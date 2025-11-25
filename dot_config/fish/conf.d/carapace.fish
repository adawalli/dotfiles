if status is-interactive; and command -q carapace
    set -q CARAPACE_BRIDGES; or set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
    set -q CARAPACE_EXCLUDES; or set -Ux CARAPACE_EXCLUDES kubectl
    carapace _carapace | source
end
