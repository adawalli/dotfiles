if status is-interactive; and command -q carapace
    # clean up stale universal vars from previous config
    set -q -U CARAPACE_BRIDGES; and set -e -U CARAPACE_BRIDGES
    set -q -U CARAPACE_EXCLUDES; and set -e -U CARAPACE_EXCLUDES
    set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
    # git excluded due to broken branch completions in carapace 1.6.3
    set -gx CARAPACE_EXCLUDES kubectl,cat,ls,bun,git
    carapace _carapace | source

    # carapace registers --no-files completions for ALL commands, even excluded
    # ones, which breaks fish's default file completion. Restore file completions
    # for excluded commands by erasing carapace's registration.
    #for cmd in (string split ',' $CARAPACE_EXCLUDES)
    #    complete -e -c $cmd
    #end
end
