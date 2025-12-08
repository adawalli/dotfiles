function tsh --wraps tsh --description 'Wrap tsh to preserve kube config on logout'
    if test (count $argv) -gt 0; and test "$argv[1]" = "logout"
        set -l kube_config "$HOME/.kube/config"
        set -l backup_file "$HOME/.kube/config.tsh-backup"
        set -l had_config false

        if test -f "$kube_config"
            set had_config true
            mv "$kube_config" "$backup_file"
        end

        command tsh $argv
        set -l tsh_status $status

        if $had_config; and test -f "$backup_file"
            mv "$backup_file" "$kube_config"
        end

        return $tsh_status
    else
        command tsh $argv
    end
end
