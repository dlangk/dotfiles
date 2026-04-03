# Local LLM Setup

MacBook Pro M1 Max, 64GB unified memory. ~54GB usable for model weights after macOS overhead.

## Tools

- **LM Studio** — primary inference UI, supports both GGUF and MLX backends
- **MLX backend preferred** — native Apple Silicon, faster decode on long generation tasks
- Note: Ollama uses GGUF/llama.cpp only. On M1, GGUF and MLX perform similarly (MLX wins on long output, GGUF wins on prefill). On M4+, MLX pulls ahead significantly.

## Models

### General Knowledge & Writing

**Gemma 4 26B-A4B-IT** (Google) — MoE, 26B total / ~4B active, 256K context, Apache 2.0

| Quant | HuggingFace | Size |
|-------|-------------|------|
| MLX 8-bit | [mlx-community/gemma-4-26b-a4b-it-8bit](https://huggingface.co/mlx-community/gemma-4-26b-a4b-it-8bit) | ~28 GB |
| MLX 4-bit | [mlx-community/gemma-4-26b-a4b-it-4bit](https://huggingface.co/mlx-community/gemma-4-26b-a4b-it-4bit) | ~16 GB |

Using 8-bit. MoE with only 4B active params means fast inference despite 26B total.

### Coding Agent

**Qwen 3.5 27B** (Alibaba) — Dense, 27B params, 262K context, Apache 2.0

| Quant | HuggingFace | Size |
|-------|-------------|------|
| MLX 8-bit | [mlx-community/Qwen3.5-27B-8bit](https://huggingface.co/mlx-community/Qwen3.5-27B-8bit) | ~30 GB |
| MLX 4-bit | [mlx-community/Qwen3.5-27B-4bit](https://huggingface.co/mlx-community/Qwen3.5-27B-4bit) | ~16 GB |

Using 8-bit. Top SWE-bench Verified score (72.4%) among models that fit this hardware. Built-in tool calling and `<think>` reasoning. No fine-tuning or distillation needed — base instruct model is best.

## Memory Budget

| Config | Total | Headroom |
|--------|-------|----------|
| One model at 8-bit | ~28-30 GB | ~24-26 GB for OS + KV cache |
| Both at 4-bit | ~32 GB | ~22 GB |
| Both at 8-bit | ~58 GB | Tight — run one at a time |

Run one model at a time for best performance at 8-bit.

## Models Considered & Rejected

| Model | Why not |
|-------|---------|
| Qwen3-Coder-Next 80B-A3B | 44.8 GB at 4-bit, tight fit, limited context headroom |
| GLM-4.7-Flash 31B-A3B | Lower SWE-bench (59.2%) than Qwen 3.5 27B (72.4%) |
| Qwen 2.5 Coder 32B | Older gen, 28.7% SWE-bench, weaker at agentic tasks |
| Devstral Small 2 24B | Strong (68% SWE-bench) but Qwen 3.5 27B still beats it |
| Distilled/fine-tuned variants | Style transfer only, regression on general benchmarks |

## Coding Agent: Aider

[Aider](https://aider.chat) — CLI coding assistant, best local LLM support among offline agents.

### Why Aider

- Diff edit format reduces token burden on 27B models (vs whole-file rewrites)
- Auto git commits with sensible messages
- Runs linters/tests automatically
- Pure Python, works on Apple Silicon
- Apache 2.0

### Setup

```bash
# Install
uv tool install aider-install && aider-install

# Run with LM Studio (model must be loaded)
export OPENAI_API_BASE=http://localhost:1234/v1
export OPENAI_API_KEY=dummy
aider --model openai/qwen3.5-27b --edit-format diff
```

### Shell alias

```bash
# In zshrc:
alias aid='OPENAI_API_BASE=http://localhost:1234/v1 OPENAI_API_KEY=dummy aider --model openai/qwen3.5-27b --edit-format diff --no-show-model-warnings --map-tokens 2048'
```

Key flags: `--edit-format diff` (critical for 27B), `--map-tokens 2048` (better repo context).
Auto-commits and auto-lint are on by default — keep them.

### Alternatives Evaluated

| Tool | Verdict |
|------|---------|
| Codex CLI (OpenAI) | Closest to Claude Code UX, but tuned for frontier models. Quality degrades with 27B. |
| OpenCode (SST) | Polished Go TUI, 95K stars. Good runner-up. |
| Trae Agent (ByteDance) | Strong SWE-bench, MIT. Worth revisiting. |
| Crush (Charm) | Beautiful TUI, newer. Watch this space. |
| Pi (badlogic) | Ultra-minimal. Good for scripting. |
| avante.nvim | Cursor-like sidebar in Neovim. Good complement to Aider. |
| OpenHands | Explicitly bad with small models. |
| Goose | Near-zero benchmark scores with local LLMs. |
| Amp (Sourcegraph) | Cloud-only, no local LLM support. |

## LM Studio Settings

### Gemma 4 26B-A4B (GGUF Q8_0)

| Setting | Value |
|---------|-------|
| Context Length | 32768 |
| GPU Offload | Max (all layers) |
| CPU Thread Pool Size | 8 |
| Evaluation Batch Size | 2048 |
| RoPE Frequency Base/Scale | Auto |
| Number of Experts | 8 |
| MoE layers on CPU | 0 |

All other settings: leave defaults. Context length must be a power of 2 (RoPE alignment).

### Qwen 3.5 27B (8-bit)

| Setting | Value |
|---------|-------|
| Context Length | 32768 |
| GPU Offload | Max (all layers) |
| CPU Thread Pool Size | 8 |
| Evaluation Batch Size | 2048 |

Run one model at a time at 8-bit to avoid swap pressure.

## Evaluated April 2026

Model landscape changes fast. Re-evaluate quarterly or when new model families drop.
