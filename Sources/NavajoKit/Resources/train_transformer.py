import contextlib
import coremltools as ct #convert to CoreML
import glob
import json #JSON encode/decode
import math #Calculations for attention
import os #file system
import sentencepiece as spm #tokenizing
import shutil #director deletion
import torch
import torch.nn as nn
import torch.optim as optim
import warnings #suppress system warnings

from torch.utils.data import Dataset, DataLoader
from tqdm import tqdm #progress

########################################
# Silence Logs
########################################

warnings.filterwarnings("ignore")
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"
os.environ["COREMLTOOLS_VERBOSE"] = "0"

########################################
# Config
########################################

DATA_FOLDER = "training_data"

VOCAB_SIZE = 10000
MAX_LEN = 128 # paragraph-level translations

D_MODEL = 256 # long-range representations
HEADS = 8
LAYERS = 4 # handled context
DROPOUT = 0.1

BATCH_SIZE = 16
EPOCHS = 10
LR = 3e-4

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

########################################
# Special Token IDs
########################################

global PAD, BOS, EOS, UNK
PAD = 0 # We'll force <pad> to be 0
BOS = None
EOS = None
UNK = None

########################################
# Class Definitions
########################################

# Dataset loader class
class TranslationDataset(Dataset):

	def __init__(self, data, sp):
		self.data = data
		self.sp = sp

	def encode(self, text, add_special = True):
		tokens = sp.encode(text, out_type = int)

		if add_special:
			tokens = [BOS] + tokens + [EOS]

		# truncate if too long
		tokens = tokens[:MAX_LEN]

		# pad
		if len(tokens) < MAX_LEN:
			tokens += [PAD] * (MAX_LEN - len(tokens))

		return torch.tensor(tokens, dtype = torch.long)

	def __getitem__(self, idx):

		item = self.data[idx]
		src = self.encode(item["nv"])
		tgt = self.encode(item["en"])

		return src, tgt

	def __len__(self):
		return len(self.data)

class PositionalEncoding(nn.Module):

	def __init__(self, d_model, max_len = MAX_LEN):

		super().__init__()

		pe = torch.zeros(max_len, d_model)
		pos = torch.arange(
			0,
			max_len,
			dtype = torch.float
		).unsqueeze(1)

		div = torch.exp(
			torch.arange(0, d_model, 2).float() * -(math.log(10000.0) / d_model)
		)

		pe[:, 0::2] = torch.sin(pos * div)
		pe[:, 1::2] = torch.cos(pos * div)

		self.register_buffer("pe", pe.unsqueeze(0))

	def forward(self, x):
		return x + self.pe[:, :x.size(1)]

# CoreML-Friendly Mobile Transformer Block
class TransformerBlock(nn.Module):

	def __init__(self, d_model, heads, dropout = DROPOUT):
		super().__init__()

		self.attn = SimpleAttention(d_model, heads, dropout)
		self.norm1 = nn.LayerNorm(d_model)

		self.ff = nn.Sequential(
			nn.Linear(d_model, d_model * 4),
			nn.GELU(),
			nn.Dropout(dropout),
			nn.Linear(d_model * 4, d_model),
			nn.Dropout(dropout)
		)

		self.norm2 = nn.LayerNorm(d_model)

	def forward(self, x, causal = False):

		x = self.norm1(x + self.attn(x, causal = causal))
		x = self.norm2(x + self.ff(x))

		return x

# Cross Attention for Decoder
class CrossAttentionBlock(nn.Module):

	def __init__(self, d_model, heads, dropout = DROPOUT):
		super().__init__()

		self.cross = SimpleAttention(d_model, heads, dropout)
		self.norm = nn.LayerNorm(d_model)
		self.ff = nn.Sequential(
			nn.Linear(d_model, d_model * 4),
			nn.GELU(),
			nn.Dropout(dropout),
			nn.Linear(d_model * 4, d_model),
			nn.Dropout(dropout)
		)
		self.norm_ff = nn.LayerNorm(d_model)

	def forward(self, x, memory):

		x = self.norm(x + self.cross(x, context = memory))
		x = self.norm_ff(x + self.ff(x))
		return x

# Simple Attention
class SimpleAttention(nn.Module):

	def __init__(self, d_model, heads, dropout = DROPOUT):
		super().__init__()

		self.heads = heads
		self.dk = d_model // heads

		self.q = nn.Linear(d_model, d_model)
		self.k = nn.Linear(d_model, d_model)
		self.v = nn.Linear(d_model, d_model)
		self.out = nn.Linear(d_model, d_model)
		self.dropout = nn.Dropout(dropout)

	def forward(self, x, context = None, causal = False, key_padding_mask = None):

		if context is None:
			context = x

		B, T, C = x.shape
		Tc = context.shape[1]

		Q = self.q(x).view(B, T, self.heads, self.dk).transpose(1, 2)
		K = self.k(context).view(B, Tc, self.heads, self.dk).transpose(1, 2)
		V = self.v(context).view(B, Tc, self.heads, self.dk).transpose(1, 2)

		scores = torch.matmul(Q, K.transpose(-2,-1)) / math.sqrt(self.dk)

		# apply causal mask (for decoder self-attention)
		if causal:
			mask = torch.triu(
				torch.ones(T, T, device = x.device),
				diagonal = 1
			).bool()
			scores = scores.masked_fill(mask, float('-inf'))

		weights = torch.softmax(scores, dim = -1)
		weights = self.dropout(weights)

		out = torch.matmul(weights, V)
		out = out.transpose(1, 2).contiguous().view(B, T, C)

		return self.out(out)

# Encoder portion of final CoreML model
class Encoder(nn.Module):

	def __init__(self, vocab_size):
		super().__init__()

		self.embed = nn.Embedding(vocab_size, D_MODEL)
		self.pos = PositionalEncoding(D_MODEL)
		self.dropout = nn.Dropout(DROPOUT)
		self.blocks = nn.ModuleList([
			TransformerBlock(D_MODEL, HEADS, DROPOUT)
			for _ in range(LAYERS)
		])

	def forward(self, src):

		x = self.embed(src)
		x = self.pos(x)
		x = self.dropout(x)

		for block in self.blocks:
			x = block(x, causal = False)

		return x

# Decoder portion of final CoreML model
class Decoder(nn.Module):

	def __init__(self, vocab_size):
		super().__init__()

		self.embed = nn.Embedding(vocab_size, D_MODEL)
		self.pos = PositionalEncoding(D_MODEL)
		self.dropout = nn.Dropout(DROPOUT)

		self.layers = nn.ModuleList([
			nn.ModuleDict({
				"self_attn": TransformerBlock(D_MODEL, HEADS, DROPOUT),
				"cross_attn": CrossAttentionBlock(D_MODEL, HEADS, DROPOUT)
			}) for _ in range(LAYERS)
		])

		self.final_norm = nn.LayerNorm(D_MODEL)
		self.head = nn.Linear(D_MODEL, vocab_size)

	def forward(self, tgt, memory):

		x = self.embed(tgt)
		x = self.pos(x)
		x = self.dropout(x)

		for layer in self.layers:
			# masked self attention
			x = layer["self_attn"](x, causal = True)
			# cross-attention to encoder output
			x = layer["cross_attn"](x, memory)

		x = self.final_norm(x)

		return self.head(x)

########################################
# Debugging
########################################

#Navajo to English
def debug_nv_to_en(text):
	encoder.eval()
	decoder.eval()
	print("INPUT TEXT (NV):", text)

	src = dataset.encode(text).unsqueeze(0).to(DEVICE)
	memory = encoder(src)

	decoded = [BOS]
	for step in range(MAX_LEN - 1):
		tgt = torch.full(
			(1, MAX_LEN),
			PAD,
			dtype = torch.long,
			device = DEVICE
		)

		for i, t in enumerate(decoded):
			tgt[0, i] = t
		logits = decoder(tgt, memory)
		next_token = logits[0, step].argmax().item()
		decoded.append(next_token)
		if next_token == EOS:
			break

	print("OUTPUT TOKENS:", decoded)
	print("OUTPUT TEXT (EN):", sp.decode(decoded[1: -1]))
	print("")

#English to Navajo
def debug_en_to_nv(text):
	encoder_rev.eval()
	decoder_rev.eval()
	print("INPUT TEXT (EN):", text)

	src = dataset.encode(text).unsqueeze(0).to(DEVICE)
	memory = encoder_rev(src)

	decoded = [BOS]
	for step in range(MAX_LEN - 1):
		tgt = torch.full(
			(1, MAX_LEN),
			PAD,
			dtype = torch.long,
			device = DEVICE
		)

		for i, t in enumerate(decoded):
			tgt[0, i] = t
		logits = decoder_rev(tgt, memory)
		next_token = logits[0, step].argmax().item()
		decoded.append(next_token)
		if next_token == EOS:
			break

	print("OUTPUT TOKENS:", decoded)
	print("OUTPUT TEXT (NV):", sp.decode(decoded[1: -1]))
	print("")

########################################
# Clean up old files for fresh start
########################################

files_to_predelete = [
	"combined.txt",
	"decoder.pt",
	"decoder_rev.pt",
	"encoder.pt",
	"encoder_rev.pt",
	"tokenizer.model",
	"vocab.json"
]

for f in files_to_predelete:
	if os.path.exists(f):
		try:
			os.remove(f)
		except:
			pass

packages_to_delete = [
	"EnglishDecoder.mlpackage",
	"EnglishEncoder.mlpackage",
	"NavajoDecoder.mlpackage",
	"NavajoEncoder.mlpackage"
]

for pkg in packages_to_delete:
	if os.path.exists(pkg):
		try:
			shutil.rmtree(pkg)
		except:
			print(f"Warning: Could not delete {pkg} ({e})")

########################################
# Load Training Data Files
########################################

DATA_FOLDER = "training_data"

print(f"Loading training data from folder: {DATA_FOLDER}")

data = []

if not os.path.isdir(DATA_FOLDER):
	print(f"Error: Folder '{DATA_FOLDER}' not found. Exiting.")
	exit(1)

json_files = glob.glob(os.path.join(DATA_FOLDER, "*.json"))

if not json_files:
	print(f"No .json files found in '{DATA_FOLDER}'. Exiting.")
	exit(1)

print(f"Found {len(json_files)} JSON file(s):")
for f in json_files:
	print(f"  - {os.path.basename(f)}")

for file_path in json_files:
	try:
		with open(file_path, "r", encoding="utf-8") as f:
			file_data = json.load(f)

			if not isinstance(file_data, list):
				print(f"Warning: {os.path.basename(file_path)} does not contain a list — skipping")
				continue

			for item in file_data:
				if not isinstance(item, dict):
					continue

				nv = item.get("nv", "").strip()
				en = item.get("en", "").strip()
				if nv and en:  # skip empty/invalid pairs
					data.append({"nv": nv, "en": en})
					
		print(f"  Loaded {len(file_data):,} pairs from {os.path.basename(file_path)}")

	except json.JSONDecodeError as e:
		print(f"Error decoding {os.path.basename(file_path)}: {e}")
	except Exception as e:
		print(f"Unexpected error reading {os.path.basename(file_path)}: {e}")

print(f"\nTotal valid sentence pairs loaded: {len(data):,}")

if len(data) == 0:
	print("No valid data loaded. Check your JSON files.")
	exit(1)

########################################
# Train SentencePiece Tokenizer
########################################

print("Preparing tokenizer...")

if not os.path.exists("tokenizer.model"):
	# Combine data for training
	with open("combined.txt", "w", encoding="utf-8") as f:
		for record in data:
			f.write(record["nv"] + "\n")
			f.write(record["en"] + "\n")

	print("Training SentencePiece BPE model (this may take a minute)...")

	# Stronger suppression: set GLOG level + full redirect
	os.environ["GLOG_minloglevel"] = "2"   # 0=INFO, 1=WARNING, 2=ERROR, 3=FATAL
	os.environ["GLOG_logtostderr"] = "0"   # Optional: try to disable stderr logging

	with open(os.devnull, "w") as devnull:
		with contextlib.redirect_stdout(devnull), contextlib.redirect_stderr(devnull):
			spm.SentencePieceTrainer.train(
				input="combined.txt",
				model_prefix="tokenizer",
				vocab_size=VOCAB_SIZE,
				model_type="bpe",
				character_coverage=1.0,
				pad_id=0,
				bos_id=1,
				eos_id=2,
				unk_id=3,
				# Extra quiet options (if supported in your version)
				# minloglevel=2,   # sometimes works as a trainer arg
			)

	# Clean up
	if os.path.exists("combined.txt"):
		os.remove("combined.txt")

	# Reset environment if desired
	os.environ.pop("GLOG_minloglevel", None)
	os.environ.pop("GLOG_logtostderr", None)

sp = spm.SentencePieceProcessor(model_file="tokenizer.model")

# set global token IDs
PAD = sp.pad_id()  # 0
BOS = sp.bos_id()  # 1
EOS = sp.eos_id()  # 2
UNK = sp.unk_id()  # 3

print(f"Tokenizer ready, vocab size: {sp.get_piece_size()}")

########################################
# Generate token look-up tables for CoreML
########################################

vocab = {}
#scores = {}

for i in range(sp.get_piece_size()):
	piece = sp.id_to_piece(i)
	vocab[piece] = i
#	scores[piece] = sp.get_score(i)

with open("vocab.json", "w") as f:
	json.dump(vocab, f, ensure_ascii = False)

#with open("scores.json", "w") as f:
#	json.dump(scores, f, ensure_ascii = False)

########################################
# Build models
########################################

dataset = TranslationDataset(data, sp)
loader = DataLoader(dataset, batch_size = BATCH_SIZE, shuffle = True)

# calculate total training tokens
total_tokens = 0
for src, tgt in dataset:
	total_tokens += (src != PAD).sum().item()
	total_tokens += (tgt != PAD).sum().item()
print(f"Total training tokens: {total_tokens:,}")

criterion = nn.CrossEntropyLoss(ignore_index = PAD)

########################################
# Training Navajo-to-English
########################################

print("Training Navajo-to-English models...")

encoder = Encoder(sp.get_piece_size()).to(DEVICE)
decoder = Decoder(sp.get_piece_size()).to(DEVICE)

optimizer = optim.Adam(
	list(encoder.parameters()) + list(decoder.parameters()),
	lr = LR
)

for epoch in range(EPOCHS):
	encoder.train()
	decoder.train()
	total_loss = 0
	num_batches = 0

	pbar = tqdm(loader, desc = f"NV-EN Epoch {epoch+1}/{EPOCHS}")

	for src, tgt in pbar:

		src = src.to(DEVICE)
		tgt = tgt.to(DEVICE)

		tgt_input = tgt[:, :-1] # exclude last token
		tgt_output = tgt[:, 1:] # shift right

		memory = encoder(src)
		logits = decoder(tgt_input, memory)

		loss = criterion(
			logits.reshape(-1, logits.size(-1)),
			tgt_output.reshape(-1)
		)

		optimizer.zero_grad()
		loss.backward()
		optimizer.step()

		total_loss += loss.item()
		num_batches += 1
		pbar.set_postfix(loss = f"{loss.item():.4f}")

	avg_loss = total_loss / num_batches
	print(f"NV-EN Epoch {epoch+1}/{EPOCHS} completed - avg loss: {avg_loss:.4f}")

########################################
# TorchScript Export
########################################

print("Exporting TorchScript...")

encoder.eval()
decoder.eval()

dummy_src = torch.full(
	(1, MAX_LEN),
	PAD,
	dtype = torch.long,
	device = DEVICE
)
dummy_tgt = torch.full(
	(1, MAX_LEN),
	PAD,
	dtype = torch.long,
	device = DEVICE
)

with torch.no_grad():

	traced_encoder = torch.jit.trace(encoder, dummy_src)
	memory = traced_encoder(dummy_src)
	traced_decoder = torch.jit.trace(
		decoder,
		(dummy_tgt, memory)
	)

traced_encoder.save("encoder.pt")
traced_decoder.save("decoder.pt")

########################################
# Convert to CoreML
########################################

print("Converting to CoreML...")

ml_encoder = ct.convert(
	traced_encoder,
	inputs = [
		ct.TensorType(name = "source", shape = dummy_src.shape)
	],
	outputs = [
		ct.TensorType(name = "memory")
	],
	convert_to = "mlprogram",
	compute_precision = ct.precision.FLOAT16,
	minimum_deployment_target = ct.target.iOS15
)
ml_encoder.save("NavajoEncoder.mlpackage")
print("Exported CoreML NavajoEncoder model")

ml_decoder = ct.convert(
	traced_decoder,
	inputs = [
		ct.TensorType(name = "target", shape = dummy_tgt.shape),
		ct.TensorType(name = "memory", shape = memory.shape)
	],
	outputs = [
		ct.TensorType(name = "logits")
	],
	convert_to = "mlprogram",
	compute_precision = ct.precision.FLOAT16,
	minimum_deployment_target = ct.target.iOS15
)
ml_decoder.save("EnglishDecoder.mlpackage")
print("Exported CoreML EnglishDecoder model")

########################################
# Training English-to-Navajo
########################################

print("Training English-to-Navajo models...")

encoder_rev = Encoder(sp.get_piece_size()).to(DEVICE)
decoder_rev = Decoder(sp.get_piece_size()).to(DEVICE)

optimizer_rev = optim.Adam(
	list(encoder_rev.parameters()) + list(decoder_rev.parameters()),
	lr = LR
)

for epoch in range(EPOCHS):
	encoder_rev.train()
	decoder_rev.train()
	total_loss = 0
	num_batches = 0

	pbar = tqdm(loader, desc = f"EN-NV Epoch {epoch+1}/{EPOCHS}")

	for src, tgt in pbar:

		src_rev = tgt.to(DEVICE)
		tgt_rev = src.to(DEVICE)

		tgt_input = tgt_rev[:, :-1] # exclude last token
		tgt_output = tgt_rev[:, 1:] # shift right

		memory = encoder_rev(src_rev)
		logits = decoder_rev(tgt_input, memory)

		loss = criterion(
			logits.reshape(-1, logits.size(-1)),
			tgt_output.reshape(-1)
		)

		optimizer_rev.zero_grad()
		loss.backward()
		optimizer_rev.step()

		total_loss += loss.item()
		num_batches += 1
		pbar.set_postfix(loss = f"{loss.item():.4f}")

	avg_loss = total_loss / num_batches
	print(f"EN-NV Epoch {epoch+1}/{EPOCHS} completed - avg loss: {avg_loss:.4f}")

########################################
# TorchScript Export
########################################

print("Exporting TorchScript...")

encoder_rev.eval()
decoder_rev.eval()

dummy_src = torch.full(
	(1, MAX_LEN),
	PAD,
	dtype = torch.long,
	device = DEVICE
)
dummy_tgt = torch.full(
	(1, MAX_LEN),
	PAD,
	dtype = torch.long,
	device = DEVICE
)

with torch.no_grad():

	traced_encoder_rev = torch.jit.trace(encoder_rev, dummy_src)
	memory = traced_encoder_rev(dummy_src)
	traced_decoder_rev = torch.jit.trace(
		decoder_rev,
		(dummy_tgt, memory)
	)

traced_encoder_rev.save("encoder_rev.pt")
traced_decoder_rev.save("decoder_rev.pt")

########################################
# Convert to CoreML
########################################

print("Converting to CoreML...")

ml_encoder_rev = ct.convert(
	traced_encoder_rev,
	inputs = [
		ct.TensorType(name = "source", shape = dummy_src.shape)
	],
	outputs = [
		ct.TensorType(name = "memory")
	],
	convert_to = "mlprogram",
	compute_precision = ct.precision.FLOAT16,
	minimum_deployment_target = ct.target.iOS15
)
ml_encoder_rev.save("EnglishEncoder.mlpackage")
print("Exported CoreML EnglishEncoder model")

ml_decoder_rev = ct.convert(
	traced_decoder_rev,
	inputs = [
		ct.TensorType(name = "target", shape = dummy_tgt.shape),
		ct.TensorType(name = "memory", shape = memory.shape)
	],
	outputs = [
		ct.TensorType(name = "logits")
	],
	convert_to = "mlprogram",
	compute_precision = ct.precision.FLOAT16,
	minimum_deployment_target = ct.target.iOS15
)
ml_decoder_rev.save("NavajoDecoder.mlpackage")
print("Exported CoreML NavajoDecoder model")

########################################
# Final clean up files
########################################

files_to_postdelete = [
	"combined.txt",
	"decoder.pt",
	"decoder_rev.pt",
	"encoder.pt",
	"encoder_rev.pt",
	"tokenizer.model"
]

for f in files_to_postdelete:
	if os.path.exists(f):
		try:
			os.remove(f)
		except:
			pass

debug_nv_to_en("yáʼátʼééh shikʼéí dóó nihí dóó nihikéyah bił hólǫ́.")
debug_nv_to_en("Yá'át'ééh abíní shik'éí.") #Good morning, my friend

debug_en_to_nv("Hello my relatives and friends.")
debug_en_to_nv("How are you today on this beautiful land?")

print("CoreML packages ready for iOS integration:")
print("  - NavajoEncoder.mlpackage + EnglishDecoder.mlpackage   (Navajo → English)")
print("  - EnglishEncoder.mlpackage + NavajoDecoder.mlpackage   (English → Navajo)")
