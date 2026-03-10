function vst --description "Show current vault status"
    if not set -q VAULT_ADDR
        echo "No active vault session"
        return 1
    end

    set -l env "unknown"
    if string match -q "*stg*" "$VAULT_ADDR"
        set env "stage"
    else if string match -q "*prod*" "$VAULT_ADDR"
        set env "prod"
    end

    echo "Env:       $env"
    echo "Namespace: $VAULT_NAMESPACE"

    set -l ttl (vault token lookup -format json 2>/dev/null | jq -r '.data.ttl' 2>/dev/null)
    if test -z "$ttl" -o "$ttl" = "null"
        echo "Token:     NONE/EXPIRED"
    else
        set -l hours (math -s0 "$ttl / 3600")
        set -l minutes (math -s0 "($ttl % 3600) / 60")
        echo "Token TTL: "$hours"h "$minutes"m"
    end
end
