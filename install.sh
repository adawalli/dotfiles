#!/usr/bin/env bash
set -euo pipefail

# Simple chezmoi bootstrapper with host profiles and flags.
# Flags:
#   --yes               Non-interactive (accepted, no-op placeholder)
#   --dry-run           Do not change system; pass to chezmoi apply
#   --no-packages       Skip package installs
#   --no-chsh           Skip changing login shell on Linux
#   --profile <name>    Host profile: default|minimal

NO_PACKAGES=""
NO_CHSH=""
DRY_RUN=""
PROFILE="default"

while [[ $# -gt 0 ]]; do
  case "${1:-}" in
    --yes)
      # kept for compatibility; script is non-interactive by design
      shift ;;
    --dry-run)
      DRY_RUN=1; shift ;;
    --no-packages)
      NO_PACKAGES=1; shift ;;
    --no-chsh)
      NO_CHSH=1; shift ;;
    --profile)
      PROFILE="${2:-default}"; shift 2 ;;
    *)
      echo "Unknown flag: $1" >&2; exit 2 ;;
  esac
done

if ! command -v chezmoi >/dev/null 2>&1; then
  echo "chezmoi not found; installing..."
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
  export PATH="$HOME/.local/bin:$PATH"
fi

# Export flags for run_once templates
export CHEZMOI_PROFILE="$PROFILE"
export CHEZMOI_NO_PACKAGES="${NO_PACKAGES:-}"
export CHEZMOI_NO_CHSH="${NO_CHSH:-}"

APPLY_ARGS=(apply)
if [[ -n "$DRY_RUN" ]]; then
  APPLY_ARGS+=(--dry-run --verbose)
fi

chezmoi "${APPLY_ARGS[@]}"

echo "Done. Profile=$PROFILE dry_run=${DRY_RUN:-0} no_packages=${NO_PACKAGES:+1} no_chsh=${NO_CHSH:+1}"
