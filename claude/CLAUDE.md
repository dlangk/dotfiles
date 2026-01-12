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

## Verification
After making code changes:
1. Run the linter/formatter for that language
2. Run tests if they exist
3. Check for type errors (pyright, tsc, etc.)

## Context
- Main machine: MacBook (Apple Silicon)
- Terminal: Ghostty
- Editor: Neovim, Cursor
- Dotfiles: ~/dotfiles (symlinked configs)