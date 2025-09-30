# Custom function to set namespace for current kubectl context
# This evaluates the current context dynamically, not at shell startup

function kcn -d "Set namespace for current kubectl context"
    if test (count $argv) -eq 0
        echo "Usage: kcn <namespace>"
        return 1
    end

    set -l current_context (kubectl config current-context 2>/dev/null)

    if test -z "$current_context"
        echo "Error: No current kubectl context found"
        return 1
    end

    kubectl config set-context $current_context --namespace $argv[1]
end
