if status is-interactive; and command -q carapace
    # clean up stale universal vars from previous config
    set -q -U CARAPACE_BRIDGES; and set -e -U CARAPACE_BRIDGES
    set -q -U CARAPACE_EXCLUDES; and set -e -U CARAPACE_EXCLUDES
    set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
    set -gx CARAPACE_EXCLUDES kubectl,cat,ls,bun
    carapace _carapace | source
end
