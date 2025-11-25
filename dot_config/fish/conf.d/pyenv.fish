if status is-interactive; and command -q pyenv
    set -gx PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/shims
    function pyenv --wraps pyenv
        functions --erase pyenv
        source (pyenv init - | psub)
        pyenv $argv
    end
end
