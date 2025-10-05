function tree --wraps eza --description 'Use eza --tree instead of tree'
    if command -q eza
        eza --tree $argv
    else
        command tree $argv
    end
end
