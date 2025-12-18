# Helper function for smart vault login
function __vault_login
    set -l vault_url $argv[1]
    set -l env_name $argv[2]
    set -l env_suffix $argv[3]

    # Check for force flag
    set -l force_login 0
    if contains -- --force $argv; or contains -- -f $argv
        set force_login 1
    end

    # Save current tokens before switching (vault uses both .vault-token and .vault-token.json)
    if test -f ~/.vault-token
        if string match -q "*stg*" "$VAULT_ADDR"
            cp ~/.vault-token ~/.vault-token.stg
            test -f ~/.vault-token.json; and cp ~/.vault-token.json ~/.vault-token.json.stg
        else if string match -q "*prod*" "$VAULT_ADDR"
            cp ~/.vault-token ~/.vault-token.prd
            test -f ~/.vault-token.json; and cp ~/.vault-token.json ~/.vault-token.json.prd
        end
    end

    # Clear ALL scopes to prevent shadowing, then set universal
    set -e VAULT_ADDR 2>/dev/null
    set -eU VAULT_ADDR 2>/dev/null
    set -Ux VAULT_ADDR $vault_url
    echo "VAULT_ADDR=$VAULT_ADDR"

    # Restore cached tokens for this environment (both files)
    if test -f ~/.vault-token.$env_suffix
        cp ~/.vault-token.$env_suffix ~/.vault-token
        test -f ~/.vault-token.json.$env_suffix; and cp ~/.vault-token.json.$env_suffix ~/.vault-token.json
    else
        # No cached token - remove .json so vault doesn't use stale one
        rm -f ~/.vault-token.json
    end

    # Force login if requested
    if test "$force_login" -eq 1
        echo "Force login requested..."
        __vault_do_oidc_login $env_suffix
        return $status
    end

    # Check token TTL
    set -l ttl (vault token lookup -format json 2>/dev/null | jq -r '.data.ttl' 2>/dev/null)

    if test -z "$ttl" -o "$ttl" = "null"
        echo "No valid token found, logging in..."
        __vault_do_oidc_login $env_suffix
    else if test "$ttl" -le 1800
        echo "Token expires in <30 min ($ttl s), renewing..."
        if vault token renew >/dev/null 2>&1
            echo "Token renewed"
            __vault_cache_token $env_suffix
        else
            echo "Renewal failed, doing OIDC login..."
            __vault_do_oidc_login $env_suffix
        end
    else
        set -l hours (math -s0 "$ttl / 3600")
        set -l minutes (math -s0 "($ttl % 3600) / 60")
        echo "Token valid: "$hours"h "$minutes"m"
    end
end

function __vault_do_oidc_login
    set -l env_suffix $argv[1]
    if vault login -method=oidc
        __vault_cache_token $env_suffix
        return 0
    else
        echo "Login failed"
        return 1
    end
end

function __vault_cache_token
    set -l env_suffix $argv[1]
    cp ~/.vault-token ~/.vault-token.$env_suffix
    test -f ~/.vault-token.json; and cp ~/.vault-token.json ~/.vault-token.json.$env_suffix
end
