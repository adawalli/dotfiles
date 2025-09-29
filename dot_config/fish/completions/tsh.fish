# Fish completion for tsh (Teleport SSH)
# This provides basic completion parity with tsh --completion-script-zsh

# Original simple version (works without descriptions)
# function __tsh_complete
#     # Get the current command line tokens (excluding the command itself)
#     set -l tokens (commandline -opc)[2..]
#
#     # Use tsh's built-in bash completion to generate options
#     set -l completions (tsh --completion-bash $tokens 2>/dev/null)
#
#     if test $status -eq 0
#         # Output each completion option
#         for completion in $completions
#             echo $completion
#         end
#     end
# end
#
# # Register the completion function for tsh
# complete -c tsh -f -a "(__tsh_complete)"

# Enhanced version with descriptions for main commands
function __tsh_complete
    # Get the current command line tokens (excluding the command itself)
    set -l tokens (commandline -opc)[2..]
    set -l num_tokens (count $tokens)

    # If this is the first argument (main command), provide descriptions
    if test $num_tokens -eq 0
        # Main commands with descriptions (based on tsh help output)
        echo -e "help\tShow help"
        echo -e "version\tShow version information"
        echo -e "ssh\tSSH to a remote SSH node"
        echo -e "resolve\tResolve hostname to IP address"
        echo -e "aws\tAccess AWS API"
        echo -e "az\tAccess Azure API"
        echo -e "gcloud\tAccess Google Cloud API"
        echo -e "gsutil\tAccess Google Cloud Storage"
        echo -e "apps\tView and access web applications"
        echo -e "recordings\tView and access session recordings"
        echo -e "proxy\tRun local TLS proxy allowing connecting to Teleport in single-port mode"
        echo -e "db\tView and access databases"
        echo -e "join\tJoin the active SSH or Kubernetes session"
        echo -e "play\tReplay the recorded session"
        echo -e "scp\tTransfer files to a remote SSH node"
        echo -e "ls\tList remote SSH nodes"
        echo -e "clusters\tList available Teleport clusters"
        echo -e "sessions\tManage active sessions"
        echo -e "login\tLog in to a cluster and retrieve the session certificate"
        echo -e "logout\tDelete a cluster certificate"
        echo -e "status\tDisplay the list of proxy servers and retrieved certificates"
        echo -e "env\tPrint commands to set Teleport session environment variables"
        echo -e "request\tManage access requests"
        echo -e "headless\tManage headless authentication requests"
        echo -e "kubectl\tRun kubectl command on a Kubernetes cluster"
        echo -e "kube\tManage available Kubernetes clusters"
        echo -e "mfa\tManage multi-factor authentication devices"
        echo -e "scan\tScan for security issues"
        echo -e "config\tPrint OpenSSH configuration details"
        echo -e "update\tUpdate client tools to latest version"
        echo -e "device\tManage trusted device enrollment"
        echo -e "vnet\tStart Teleport VNet for TCP application access"
        echo -e "git\tAccess Git repositories"
        echo -e "mcp\tManage MCP server applications"
        return
    end

    # Handle special cases before falling back to dynamic completion

    # Handle 'tsh kube' subcommands
    if test $num_tokens -eq 1; and test "$tokens[1]" = "kube"
        echo -e "login\tLog in to a kubernetes cluster"
        echo -e "ls\tList kubernetes clusters"
        echo -e "exec\tExecute command in a kubernetes pod"
        echo -e "credentials\tManage kubernetes credentials"
        return
    end

    # Handle 'tsh kube login' with cached cluster names
    if test $num_tokens -eq 2; and test "$tokens[1]" = "kube"; and test "$tokens[2]" = "login"
        # Source and call the cluster caching function
        __tsh_get_clusters

        # Use cached cluster names if available
        if set -q TSH_CLUSTER_CACHE; and test -n "$TSH_CLUSTER_CACHE"
            for cluster in $TSH_CLUSTER_CACHE
                echo $cluster
            end
        else
            echo "no clusters available"
        end
        return
    end

    # For all other cases, use dynamic completion
    set -l completions (tsh --completion-bash $tokens 2>/dev/null)

    if test $status -eq 0
        # Output each completion option
        for completion in $completions
            echo $completion
        end
    end
end

# Register the enhanced completion function for tsh
complete -c tsh -f -a "(__tsh_complete)"
