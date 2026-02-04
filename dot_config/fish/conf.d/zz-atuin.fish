# Named zz-* to load last in conf.d - atuin's Ctrl+R binding must run after
# fish_vi_key_bindings (set in config.fish) or it gets overwritten with "redo"

if status is-interactive; and command -q atuin
    atuin init fish | source
end
