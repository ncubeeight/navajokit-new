import contextlib
import coremltools as ct #convert to CoreML
import json #JSON encode/decode
import math #Calculations for attention
import os #file system
import sentencepiece as spm #tokenizing
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

DATA_FILE = "training_data.json"

VOCAB_SIZE = 8000 #Will like need to increase later
MAX_LEN = 40 #includes BOS + EOS + padding

D_MODEL = 160
HEADS = 4
LAYERS = 3
DROPOUT = 0.1

BATCH_SIZE = 32
EPOCHS = 10
LR = 3e-4

DEVICE = "cuda" if torch.cuda.is_available() else "cpu"

########################################
# Special Token IDs (will be set after tokenizer training)
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
		dest = self.encode(item["en"])

		return src, dest

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

		self.embed = nn.Embedding(vocab_size, D_MODEL, padding_idx = PAD)
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

		self.embed = nn.Embedding(vocab_size, D_MODEL, padding_idx = PAD)
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

	def forward(self, dest, memory):

		x = self.embed(dest)
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
# Clean up old for fresh start
########################################

if os.path.exists("tokenizer.model"):
	os.remove("tokenizer.model")

if os.path.exists("scores.json"):
	os.remove("scores.json")

if os.path.exists("vocab.json"):
	os.remove("vocab.json")

if os.path.exists("decoder.pt"):
	os.remove("decoder.pt")

if os.path.exists("encoder.pt"):
	os.remove("encoder.pt")

if os.path.exists("NavajoEncoder.mlpackage"):
	os.remove("NavajoEncoder.mlpackage")

if os.path.exists("NavajoDecoder.mlpackage"):
	os.remove("NavajoDecoder.mlpackage")

########################################
# Load Data
########################################

print("Loading the training data...")

with open(DATA_FILE, "r", encoding = "utf-8") as f:
	data = json.load(f)

nv = [x["nv"] for x in data]
en = [x["en"] for x in data]

########################################
# Train SentencePiece Tokenizer
########################################

print("Preparing tokenizer...")

vocab = {}
scores = {}

if not os.path.exists("tokenizer.model"):

	with open("combined.txt", "w", encoding = "utf-8") as f:
		for nv, en in zip(nv, en):
			f.write(nv + "\n")
			f.write(en + "\n")

	with open(os.devnull, "w") as f, contextlib.redirect_stdout(f):
		spm.SentencePieceTrainer.train(
			input = "combined.txt",
			model_prefix = "tokenizer",
			vocab_size = VOCAB_SIZE,
			model_type = "bpe",
			character_coverage = 1.0,
			pad_id = PAD,
			bos_id = 1,
			eos_id = 2,
			unk_id = 3,
		)

	os.remove("combined.txt")

sp = spm.SentencePieceProcessor(model_file = "tokenizer.model")

# set global token IDs
PAD = sp.pad_id() # 0
BOS = sp.bos_id() # 1
EOS = sp.eos_id() # 2
UNK = sp.unk_id() # 3

for i in range(sp.get_piece_size()):
	piece = sp.id_to_piece(i)
	vocab[piece] = i
	scores[piece] = sp.get_score(i)

with open("vocab.json", "w") as f:
	json.dump(vocab, f, ensure_ascii = False)

with open("scores.json", "w") as f:
	json.dump(scores, f, ensure_ascii = False)

print(f"Generated vocabulary size: {sp.get_piece_size()}")

########################################
# Build models
########################################

dataset = TranslationDataset(data, sp)
loader = DataLoader(dataset, batch_size = BATCH_SIZE, shuffle = True)

# calculate total training tokens
total_tokens = 0
for src, dest in dataset:
	total_tokens += (src != PAD).sum().item()
	total_tokens += (dest != PAD).sum().item()
print(f"Total training tokens: {total_tokens:,}")

encoder = Encoder(sp.get_piece_size()).to(DEVICE)
decoder = Decoder(sp.get_piece_size()).to(DEVICE)

########################################
# Training
########################################

print("Training models...")

criterion = nn.CrossEntropyLoss(ignore_index = PAD)
optimizer = optim.Adam(
	list(encoder.parameters()) + list(decoder.parameters()),
	lr = LR
)

for epoch in range(EPOCHS):
	encoder.train()
	decoder.train()
	total_loss = 0
	num_batches = 0

	pbar = tqdm(loader, desc = f"Epoch {epoch+1}/{EPOCHS}")

	for src, dest in pbar:

		src = src.to(DEVICE)
		dest = dest.to(DEVICE)

		dest_input = dest[:, :-1] # excluse last token
		dest_output = dest[:, 1:] # shift right

		memory = encoder(src)
		logits = decoder(dest_input, memory)

		loss = criterion(
			logits.reshape(-1, logits.size(-1)),
			dest_output.reshape(-1)
		)

		optimizer.zero_grad()
		loss.backward()
		optimizer.step()

		total_loss += loss.item()
		num_batches += 1
		pbar.set_postfix(loss = f"{loss.item():.4f}")

	avg_loss = total_loss / num_batches
	print(f"Epoch {epoch+1}/{EPOCHS} completed - avg loss: {avg_loss:.4f}")

########################################
# TorchScript Export to CoreML
########################################

print("Exporting Models...")

encoder.eval()
decoder.eval()

dummy_src = torch.full(
	(1, MAX_LEN),
	PAD,
	dtype = torch.long,
	device = DEVICE
)
dummy_dest = torch.full(
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
		(dummy_dest, memory)
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
	convert_to = "mlprogram",
	#compute_precision = ct.precision.FLOAT16,
	minimum_deployment_target = ct.target.iOS15
)
ml_encoder.save("NavajoEncoder.mlpackage")
print("Exported CoreML Encoder model")

ml_decoder = ct.convert(
	traced_decoder,
	inputs = [
		ct.TensorType(name = "target", shape = dummy_dest.shape),
		ct.TensorType(name = "memory", shape = memory.shape)
	],
	convert_to = "mlprogram",
	#compute_precision = ct.precision.FLOAT16,
	minimum_deployment_target = ct.target.iOS15
)
ml_decoder.save("NavajoDecoder.mlpackage")
print("Exported CoreML Decoder model")

########################################
# Debugging
########################################

def debug_translation(text):

	encoder.eval()
	decoder.eval()

	print("INPUT:", text)

	# Tokenize
	tokens = sp.encode(text, out_type=int)

	print("TOKENS:", tokens)

	src = torch.zeros(1, MAX_LEN, dtype = torch.long)

	for i,t in enumerate(tokens[:MAX_LEN]):
		src[0,i] = t

	# Encoder
	memory = encoder(src)

	print("\nENCODER MEMORY SAMPLE:")
	print(memory[0,0,:10])

	decoded = [BOS]

	for step in range(10):

		tgt = torch.zeros(1, MAX_LEN, dtype = torch.long)

		for i,t in enumerate(decoded):
			tgt[0,i] = t

		logits = decoder(tgt, memory)

		step_logits = logits[0, step]

		next_token = step_logits.argmax().item()

		decoded.append(next_token)

		if next_token == EOS:
			break

	print("\nOUTPUT TOKENS:", decoded)

debug_translation("yáʼátʼééh shikʼéí")
