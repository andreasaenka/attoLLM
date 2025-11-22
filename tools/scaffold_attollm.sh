#!/usr/bin/env bash
set -euo pipefail

# Scaffold the attoLLM project with a src/ package layout.
# Usage: tools/scaffold_attollm.sh <target-dir> [--force] [--no-venv]

TARGET_DIR=""
FORCE=0
MAKE_VENV=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force) FORCE=1; shift ;;
    --no-venv) MAKE_VENV=0; shift ;;
    -h|--help) echo "Usage: $0 <target-dir> [--force] [--no-venv]"; exit 0 ;;
    *) if [[ -z "$TARGET_DIR" ]]; then TARGET_DIR="$1"; shift; else echo "Unexpected arg: $1"; exit 2; fi ;;
  esac
done

if [[ -z "$TARGET_DIR" ]]; then
  echo "Error: <target-dir> is required" >&2
  exit 2
fi

if [[ -e "$TARGET_DIR" && $FORCE -eq 0 ]]; then
  if [[ -d "$TARGET_DIR" && -z "$(ls -A "$TARGET_DIR" 2>/dev/null || true)" ]]; then :; else
    echo "Error: $TARGET_DIR exists. Use --force to overwrite." >&2
    exit 3
  fi
fi

mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

mkdir -p src/attollm scripts configs data/raw data/processed data/cache checkpoints tests

cat > README.md << 'MD'
# attoLLM

This repository implements a tiny GPT‑style language model step by step.

- Package: `src/attollm/`
- Scripts: `scripts/`
- Configs: `configs/`
- Data roots: `data/` (raw/ processed/ cache/)
- Checkpoints: `checkpoints/`

Quick start
1) Create a virtual environment and install:
   - `python3 -m venv .venv && source .venv/bin/activate`
   - `python -m pip install --upgrade pip`
   - `pip install -r requirements.txt`
   - `pip install -e .`
2) Smoke test: `python -m attollm.hello`
3) Train when code is implemented: `python scripts/train.py --config configs/default.yaml`
MD

cat > .gitignore << 'GI'
__pycache__/
*.pyc
.venv/
data/cache/
checkpoints/
runs/
*.pt
*.pth
GI

cat > requirements.txt << 'REQ'
numpy>=1.24
tqdm>=4.66
tensorboard>=2.13
REQ

cat > pyproject.toml << 'TOML'
[build-system]
requires = ["setuptools>=68", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "attollm"
version = "0.0.1"
description = "A tiny GPT-style language model for learning"
requires-python = ">=3.10"
dependencies = []

[tool.setuptools]
package-dir = {"" = "src"}

[tool.setuptools.packages.find]
where = ["src"]
TOML

cat > src/attollm/__init__.py << 'PY'
__all__ = ["hello"]
PY

cat > src/attollm/hello.py << 'PY'
def main() -> None:
    print("Hello from attoLLM!")

if __name__ == "__main__":
    main()
PY

cat > scripts/train.py << 'PY'
#!/usr/bin/env python
from __future__ import annotations
import argparse


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--config", default="configs/default.yaml")
    args = ap.parse_args()
    print(f"[train] would load config: {args.config}")
    print("[train] implement data/model/training in later chapters…")


if __name__ == "__main__":
    main()
PY
chmod +x scripts/train.py

cat > scripts/sample.py << 'PY'
#!/usr/bin/env python
from __future__ import annotations
import argparse


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--checkpoint", default="checkpoints/latest.pt")
    ap.add_argument("--prompt", default="Hello")
    args = ap.parse_args()
    print(f"[sample] would load {args.checkpoint} and continue: {args.prompt!r}")


if __name__ == "__main__":
    main()
PY
chmod +x scripts/sample.py

cat > configs/default.yaml << 'YAML'
seed: 42
device: auto   # cpu | cuda | mps | auto
optimizer: adamw
lr: 3.0e-4
batch_size: 32
block_size: 128
n_layer: 4
n_head: 4
n_embd: 256
max_steps: 2000
YAML

echo "Scaffolded attoLLM project at: $(pwd)"

# Optional convenience Makefile (Unix-like)
cat > Makefile << 'MK'
SHELL := /bin/bash

VENV ?= .venv
PY ?= $(VENV)/bin/python
PIP ?= $(VENV)/bin/pip
CONFIG ?= configs/default.yaml
CHECKPOINT ?= checkpoints/latest.pt
PROMPT ?= Hello

.PHONY: help venv install train sample clean

help:
	@echo "Targets: venv, install, train, sample, clean"

venv:
	python3 -m venv $(VENV)

install: | $(VENV)
	$(PY) -m pip install --upgrade pip
	$(PIP) install -r requirements.txt
	$(PIP) install -e .

train:
	$(PY) scripts/train.py --config $(CONFIG)

sample:
	$(PY) scripts/sample.py --checkpoint $(CHECKPOINT) --prompt "$(PROMPT)"

clean:
	rm -rf __pycache__ .pytest_cache
MK

if [[ $MAKE_VENV -eq 1 ]]; then
  if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi
  echo "Creating virtual environment (.venv)…"
  $PY -m venv .venv || { echo "venv creation failed"; exit 0; }
  # shellcheck disable=SC1091
  source .venv/bin/activate || true
  python -m pip install --upgrade pip || true
  pip install -r requirements.txt || true
  pip install -e . || true
  echo "Run: source .venv/bin/activate && python -m attollm.hello"
else
  echo "Skipped venv creation (--no-venv)."
fi
