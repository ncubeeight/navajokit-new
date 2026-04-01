#!/usr/bin/env bash
# =============================================================================
# Portable Setup & Run Script for Navajo Transformer Trainer
# Works from any project root folder on macOS, Linux, or Git Bash (Windows)
# =============================================================================

set -e  # Exit on any error

echo "🚀 Starting portable setup for train_transformer.py..."

# ----------------------------------------------------------------------
# 1. Detect Python interpreter (prefer python3, fallback to python)
# ----------------------------------------------------------------------
if command -v python3 >/dev/null 2>&1; then
    PYTHON_CMD="python3"
elif command -v python >/dev/null 2>&1; then
    PYTHON_CMD="python"
else
    echo "❌ Error: Neither 'python3' nor 'python' found in PATH."
    echo "   Please install Python 3 and ensure it's in your PATH."
    exit 1
fi

echo "✅ Using Python: $($PYTHON_CMD --version)"

# ----------------------------------------------------------------------
# 2. Create virtual environment (use .venv for standard convention)
# ----------------------------------------------------------------------
VENV_DIR=".venv"

if [ ! -d "$VENV_DIR" ]; then
    echo "📦 Creating isolated virtual environment in $VENV_DIR/ ..."
    $PYTHON_CMD -m venv "$VENV_DIR"
    
    # Ensure pip is installed (some minimal Python installs omit it)
    echo "🔧 Ensuring pip is available..."
    "$VENV_DIR/bin/python" -m ensurepip --upgrade --default-pip || true
else
    echo "✅ Virtual environment already exists at $VENV_DIR/"
fi

# ----------------------------------------------------------------------
# 3. Activate venv using full relative path (most reliable)
# ----------------------------------------------------------------------
echo "🔌 Activating virtual environment..."
if [ -f "$VENV_DIR/bin/activate" ]; then
    # macOS / Linux / Git Bash
    source "$VENV_DIR/bin/activate"
else
    echo "❌ Error: Could not find activation script in $VENV_DIR"
    echo "   Expected: $VENV_DIR/bin/activate"
    exit 1
fi

# ----------------------------------------------------------------------
# 4. Upgrade pip and install dependencies
# ----------------------------------------------------------------------
echo "📥 Upgrading pip inside the venv..."
$PYTHON_CMD -m pip install --quiet --upgrade pip

echo "📦 Installing required packages..."
$PYTHON_CMD -m pip install --quiet torch torchvision torchaudio \
                        coremltools \
                        sentencepiece \
                        tqdm

echo "✅ Dependencies installed successfully in isolated venv."

# ----------------------------------------------------------------------
# 5. Ensure training_data folder exists
# ----------------------------------------------------------------------
if [ ! -d "training_data" ]; then
    mkdir -p training_data
    echo "📁 Created empty 'training_data' folder."
    echo "   → Add your *.json files containing {\"nv\": \"...\", \"en\": \"...\"} pairs."
    echo "   → Then run this script again."
    exit 0
fi

# ----------------------------------------------------------------------
# 6. Run the training script using the venv's python
# ----------------------------------------------------------------------
echo "🔥 Running train_transformer.py with the virtual environment..."
$PYTHON_CMD train_transformer.py

echo "🎉 Finished! Generated files should be in the project root."
echo "   Next time, just run: ./setup_and_run.sh"
