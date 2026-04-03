# About Me

- **Name:** Daniel Langkilde
- **Email:** daniel.langkilde@gmail.com
- **GitHub:** dlangk
- **Company:** Kognic
- **Role:** CEO
- **Location:** Gothenburg, Sweden
- **Timezone:** Europe/Stockholm

# Global Preferences

## Communication
- Be direct and concise
- Skip preamble, get to the solution
- Use code blocks, not lengthy explanations

## Coding Standards
- Python: type hints, black formatting
- TypeScript: strict mode
- Go: standard go fmt
- Rust: cargo fmt
- Always run tests after changes if they exist

## Python Tooling
- Use `uv` instead of pip/pipx/venv (10-100x faster)
- `uv venv` to create virtualenvs
- `uv pip install` to install packages
- `uv tool install` for CLI tools (replaces pipx)
- Never install packages globally - always use venvs

## Verification
After making code changes:
1. Run the linter/formatter for that language
2. Run tests if they exist
3. Check for type errors (pyright, tsc, etc.)

## Context
- Main machine: MacBook M1 Max (Apple Silicon)
- Terminal: Ghostty
- Editor: Neovim, VS Code
- Dotfiles: ~/dotfiles (symlinked configs)
