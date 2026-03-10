# Helper function for smart vault login
function __vault_login
    set -l vault_url $argv[1]
    set -l env_name $argv[2]
    set -l env_suffix $argv[3]
    set -l namespace $argv[4]

    # Check for force flag in remaining args
    set -l force_login 0
    if contains -- --force $argv[5..]; or contains -- -f $argv[5..]
        set force_login 1
    end

    # Compound cache suffix includes namespace
    set -l cache_suffix "$env_suffix.$namespace"

    # Clear ALL scopes to prevent shadowing, then set universal
    set -e VAULT_ADDR 2>/dev/null
    set -eU VAULT_ADDR 2>/dev/null
    set -Ux VAULT_ADDR $vault_url
    echo "VAULT_ADDR=$VAULT_ADDR"

    set -e VAULT_NAMESPACE 2>/dev/null
    set -eU VAULT_NAMESPACE 2>/dev/null
    set -Ux VAULT_NAMESPACE $namespace
    echo "VAULT_NAMESPACE=$VAULT_NAMESPACE"

    # Restore cached tokens for this environment+namespace (both files)
    if test -f ~/.vault-token.$cache_suffix
        cp ~/.vault-token.$cache_suffix ~/.vault-token
        test -f ~/.vault-token.json.$cache_suffix; and cp ~/.vault-token.json.$cache_suffix ~/.vault-token.json
    else
        # No cached token - remove stale files so we trigger a fresh login
        rm -f ~/.vault-token ~/.vault-token.json
    end

    # Force login if requested
    if test "$force_login" -eq 1
        echo "Force login requested..."
        __vault_do_oidc_login $cache_suffix
        return $status
    end

    # Check token TTL
    set -l ttl (vault token lookup -format json 2>/dev/null | jq -r '.data.ttl' 2>/dev/null)

    if test -z "$ttl" -o "$ttl" = "null"
        echo "No valid token found, logging in..."
        __vault_do_oidc_login $cache_suffix
    else if test "$ttl" -le 1800
        echo "Token expires in <30 min ($ttl s), renewing..."
        if vault token renew >/dev/null 2>&1
            echo "Token renewed"
            __vault_cache_token $cache_suffix
        else
            echo "Renewal failed, doing OIDC login..."
            __vault_do_oidc_login $cache_suffix
        end
    else
        set -l hours (math -s0 "$ttl / 3600")
        set -l minutes (math -s0 "($ttl % 3600) / 60")
        echo "Token valid: "$hours"h "$minutes"m"
    end
end

function __vault_do_oidc_login
    set -l cache_suffix $argv[1]
    if vault login -method=oidc
        __vault_cache_token $cache_suffix
        return 0
    else
        echo "Login failed"
        return 1
    end
end

function __vault_cache_token
    set -l cache_suffix $argv[1]
    cp ~/.vault-token ~/.vault-token.$cache_suffix
    test -f ~/.vault-token.json; and cp ~/.vault-token.json ~/.vault-token.json.$cache_suffix
end
