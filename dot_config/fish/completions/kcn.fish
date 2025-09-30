# Completions for kcn (kubectl config set-context namespace)

# Complete with available namespaces from current context
complete -c kcn -f -a '(kubectl get namespaces -o jsonpath="{.items[*].metadata.name}" 2>/dev/null | string split " ")'
