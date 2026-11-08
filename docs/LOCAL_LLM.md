# Local LLM Setup

MacBook Pro M5 Max, 128 GB unified memory, 614 GB/s. ~110 GB usable for weights plus KV cache.
`iogpu.wired_limit_mb` is at its default (≈96 GB GPU-wired); raise it with
`sudo sysctl iogpu.wired_limit_mb=115000` before loading anything over ~90 GB.

## Tools

| Tool | Role | Install |
|------|------|---------|
| LM Studio | Day-to-day inference UI + OpenAI-compatible server on :1234. MLX engine preferred (faster than GGUF on M5). | `/Applications`, CLI at `~/.lmstudio/bin/lms` |
| mlx-lm | Scripted inference and research on raw weights | pulled in per-script by `uv run` (inline deps) |
| `hf` CLI | Download original checkpoints from Hugging Face | `uv tool install huggingface_hub` |
| MTPLX | Optional Apache-2.0 server that uses Qwen's multi-token-prediction head; 2–3× decode speed on dense Qwen 3.8 | https://github.com/youssofal/MTPLX |

Token for gated/rate-limited downloads: `~/.huggingface_token` (use `HF_TOKEN=$(cat ~/.huggingface_token)`).

## Models (lineup as of November 2026)

| Model | Where | Size | Role |
|-------|-------|------|------|
| **Qwen3.8-27B** 8-bit MLX | LM Studio (`qwen3.8-27b-mlx`) | 29.5 GB | Default for coding and general use. Best dense model ≤30B by independent eval (Krafton: SWE-bench Verified 74.6, GPQA 89.7). Dense, so ~20 tok/s in LM Studio, 50–65 with MTPLX. |
| **Qwen3.8-27B** BF16 | `~/dev/learning/transformers/models/` | 55.6 GB | Research copy, unquantized. See "Research weights" below. |
| Qwen3.8-Flash-Next 125B-A6B | not installed | 112 GB MLX 4-bit / 102 GB GGUF IQ4_NL | Strongest open model that fits. LM Studio's llama.cpp runtime ≥2.31 loads the GGUF; its MLX engine cannot (Nov 2026). Fast path is MTPLX. License is Qwen Community 1.0: fine for local/internal use, commercial assistant products need a licence from Alibaba. |

Superseded, delete when convenient: gpt-oss-120b (Aug 2025, 63 GB), Qwen3-Coder-Next 80B-A3B (Feb 2026, 85 GB, no thinking mode, SWE-bench Pro 44.3), Qwen3.6-35B-A3B (Apr 2026, 38 GB). All three lose to Qwen3.8-27B on every coding and reasoning benchmark; their only edge was MoE decode speed inside LM Studio.

Why Qwen3.8-27B is tagged `qwen3_5` everywhere: Qwen 3.8 reuses the 3.5 hybrid architecture (3 Gated DeltaNet linear-attention layers then 1 full-attention layer, ×16; 64 layers, hidden 5120, 24 Q / 4 KV heads at dim 256, 248K vocab, 262K context). That is also why mlx-lm and LM Studio load it today while Flash-Next (new `qwen4_exp` arch) is not supported yet.

## Research weights: Qwen3.8-27B BF16

Lives in `~/dev/learning/transformers/` (own project, own CLAUDE.md), not here.
That CLAUDE.md is the guide: which repo to pull (`Qwen/Qwen3.8-27B`, the only unquantized copy),
the `hf download` command, `uv run scripts/verify_model.py` to check hashes against the Hub and run a
smoke inference, and how to load tensors with mlx-lm or safetensors. 55.6 GB BF16, ~54 GB resident.

## Memory budget

| Config | Resident | Headroom of ~110 GB |
|--------|----------|---------------------|
| Qwen3.8-27B 8-bit in LM Studio | ~32 GB | ~78 GB |
| Qwen3.8-27B BF16 in mlx-lm (research) | ~54 GB | ~56 GB |
| Both at once | ~86 GB | ~24 GB — fine for short-context research, unload one for long agent sessions |
| Flash-Next 4-bit MLX | ~50–65 GB resident (45 GB n-gram table is mmapped) | raise the wired limit first |

## Coding Agent: Aider

[Aider](https://aider.chat) — CLI coding assistant, best local-LLM support among offline agents.

- Diff edit format keeps the token burden low for a 27B model
- Auto git commits, auto lint/test, pure Python, Apache 2.0

```bash
uv tool install aider-install && aider-install

# Run against LM Studio (model must be loaded there)
export OPENAI_API_BASE=http://localhost:1234/v1
export OPENAI_API_KEY=dummy
aider --model openai/qwen3.8-27b-mlx --edit-format diff
```

Shell alias (zshrc):
```bash
alias aid='OPENAI_API_BASE=http://localhost:1234/v1 OPENAI_API_KEY=dummy aider --model openai/qwen3.8-27b-mlx --edit-format diff --no-show-model-warnings --map-tokens 2048'
```

Point `OPENAI_API_BASE` at MTPLX instead of LM Studio for 2–3× faster generation with the same model.

### Alternatives evaluated

| Tool | Verdict |
|------|---------|
| OpenCode (SST) | Polished Go TUI. Good runner-up; MTPLX publishes OpenCode benchmarks with Flash-Next. |
| Codex CLI (OpenAI) | Closest to Claude Code UX, but tuned for frontier models. |
| Trae Agent (ByteDance) | Strong SWE-bench, MIT. Worth revisiting. |
| Crush (Charm) | Beautiful TUI, newer. |
| Pi (badlogic) | Ultra-minimal. Good for scripting. |
| avante.nvim | Cursor-like sidebar in Neovim. Complement to Aider. |
| OpenHands, Goose | Poor with local models. |
| Amp (Sourcegraph) | Cloud-only. |

## LM Studio settings: Qwen3.8-27B 8-bit

| Setting | Value |
|---------|-------|
| Context length | 32768 (raise to 65536 for agent runs; native max 262144) |
| GPU offload | Max |
| Thinking | On by default at `reasoning_effort: xhigh`; the template also accepts `medium` / `low`, and `enable_thinking: false` |
| Sampling, thinking mode | temp 1.0, top-p 0.95, top-k 20 (shipped defaults) |
| Sampling, non-thinking | temp 0.7, top-p 0.8, top-k 20, presence penalty 1.5 (Qwen's recommendation; LM Studio does not switch automatically) |
| `preserve_thinking` | Defaults to true — earlier reasoning stays in context. Disable for long agent sessions. |

Tool calls use Qwen's XML-style `<tool_call><function=…>` format, not JSON. LM Studio's server translates it; only matters if you hit the model directly.

Note the LM Studio build still carries the pre-2026-11-07 chat template. The BF16 repo has the newer one ("response template and generation tags"). Re-download the LM Studio model if the template difference ever matters.

## Evaluated November 2026

Previous evaluation April 2026 (Gemma 4 26B-A4B + Qwen 3.5 27B). Model landscape changes fast; re-evaluate quarterly.
Candidates not chosen this round: Ornith-1.5-122B (Qwen3.5-122B fine-tune, MIT, 70 GB MLX 4-bit, vendor-only
benchmarks that claim to beat Flash-Next — worth an A/B), Nemotron 3.5 Super-VL 120B-A12B (fits, scores below
the 27B), Muse-Glimmer-30B (dense Meta model, slightly below Qwen3.8-27B).
