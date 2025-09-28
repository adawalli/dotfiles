if status is-interactive
    # Commands to run in interactive sessions can go here
    fish_add_path $HOME/.local/bin
    fish_add_path /usr/local/go/bin
    starship init fish | source
    /opt/homebrew/bin/brew shellenv | source
    abbr -a icd 'cd ~/Library/Mobile\ Documents/com\~apple\~CloudDocs'
    set -Ux CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense' # optional
    carapace _carapace | source
    atuin init fish | source
end
fish_add_path $HOME/.local/bin
