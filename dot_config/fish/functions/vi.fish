function vi --wraps nvim --description 'Use nvim instead of vi'
    if command -q nvim
        command nvim $argv
    else
        command vi $argv
    end
end
