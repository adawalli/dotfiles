function cat --wraps bat --description 'Use bat instead of cat'
    command bat --paging=never $argv
end
