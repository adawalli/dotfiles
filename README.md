## dotfiles (chezmoi + XDG-first)

Overview

- Uses chezmoi for idempotent dotfile management
- XDG-first (`~/.config/...`) for portability
- macOS keeps system shell as zsh; Debian will chsh to fish
- Catppuccin Mocha everywhere; JetBrains Mono Nerd Font on all systems

Quick start

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply adawalli
```

What this installs

- chezmoi and applies this repo as source state
- fish + fisher plugins (from `fish_plugins`)
- zellij with Catppuccin Mocha
- Ghostty config via XDG path
- starship with Catppuccin Mocha palette
- JetBrains Mono Nerd Font (macOS via Homebrew cask; Debian via user fonts dir)

Future

- Git/SSH and secrets intentionally omitted for initial cut
- Profiles allow lightweight installs on small hosts (eg. Raspberry Pi)

Pre-commit hooks (secrets scanning)

- Uses `pre-commit` with `gitleaks` to prevent committing secrets and to enforce basic hygiene
- Hooks run automatically on `git commit`; you can also run them manually over the whole repo

Install prerequisites

```bash
# macOS (Homebrew)
brew install uv

# Linux
curl -Ls https://astral.sh/uv/install.sh | sh
```

Install and enable hooks

```bash
# Install pre-commit via uv (recommended)
uv tool install pre-commit --with pre-commit-uv --force-reinstall

# Enable hooks for this repo
pre-commit install

# Run across all files (first run may modify whitespace/EOLs)
pre-commit run --all-files
```

Maintain

```bash
# Update hook versions to latest compatible releases
pre-commit autoupdate
```

Notes

- `gitleaks` is provided by the hook environment; no separate install required
- If a hook modifies files, re-stage changes and re-run `pre-commit` until clean
