if status is-interactive; and command -q starship
    set -l cache ~/.cache/fish/starship_init.fish
    if not test -f $cache; or test (command -v starship) -nt $cache
        mkdir -p ~/.cache/fish
        starship init fish --print-full-init > $cache
    end
    source $cache
end
