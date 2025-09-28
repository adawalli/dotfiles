#!/usr/bin/env fish

if not functions -q fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    and fisher install jorgebucaran/fisher
end

# Install plugins listed in fish_plugins (unpinned per user preference)
set -l xdg (set -q XDG_CONFIG_HOME; and echo $XDG_CONFIG_HOME; or echo "$HOME/.config")
set -l plugin_file "$xdg/fish/fish_plugins"
if test -f "$plugin_file"
    for p in (cat "$plugin_file")
        fisher list | string match -q --regex -- (^|\n)$p(\n|$)
        or fisher install $p
    end
end
