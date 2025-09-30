function vim --wraps nvim --description 'Use nvim instead of vim'
    if command -q nvim
        command nvim $argv
    else
        command vim $argv
    end
end
