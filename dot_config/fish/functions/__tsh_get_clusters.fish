# Function to fetch and cache tsh kube cluster names
# Ported from Oh My Zsh tsh plugin

function __tsh_get_clusters
    # Cache variables using Fish's universal variables
    set -l cache_ttl 14400  # 4 hours in seconds
    set -l current_time (date +%s)

    # Check if we have cached data and if it's still valid
    if set -q TSH_CLUSTER_CACHE; and set -q TSH_CLUSTER_CACHE_TIME
        set -l cache_age (math $current_time - $TSH_CLUSTER_CACHE_TIME)
        if test $cache_age -lt $cache_ttl
            # Cache is still valid, return existing data
            return 0
        end
    end

    # Fetch fresh cluster list
    set -l clusters (tsh kube ls 2>/dev/null | awk '
        NR > 2 {  # Skip header lines
            if ($1 != "" && $1 !~ /^-+$/) {  # Skip empty lines and separator lines
                print $1
            }
        }
    ')

    # Update the cache if we got results
    if test -n "$clusters"
        set -g TSH_CLUSTER_CACHE $clusters
        set -g TSH_CLUSTER_CACHE_TIME $current_time
    end

    return 0
end
