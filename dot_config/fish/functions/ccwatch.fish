function ccwatch --description "Watch Claude Code token usage and costs"
    set -l interval 30
    if test (count $argv) -ge 1
        set interval $argv[1]
    end
    watch -n $interval 'bunx ccusage blocks --live --json 2>/dev/null | jq -r '\''
[.blocks[] | select(.isActive)] | if length > 0 then last else
  [.blocks[] | select(.isGap | not)] | last end |
.tokenCounts as $tc |
(.burnRate // {}) as $br |
(.projection // {}) as $pj |
(($tc.inputTokens + $tc.cacheCreationInputTokens + $tc.cacheReadInputTokens) | if . > 0 then ($tc.cacheReadInputTokens / . * 1000 | round / 10) else 0 end) as $hit |
((.projection.remainingMinutes // 0) | floor) as $rem |
"\(.startTime[:16])  [\(if .isActive then "ACTIVE" else "DONE" end)]  \(.models | join(", "))
Cost: $\(.costUSD * 100 | round / 100)  proj: $\($pj.totalCost // 0)  remaining: \($rem / 60 | floor)h\($rem % 60)m
In: \($tc.inputTokens)  Out: \($tc.outputTokens)  CacheW: \($tc.cacheCreationInputTokens)  CacheR: \($tc.cacheReadInputTokens)  Hit: \($hit)%
Burn: $\(($br.costPerHour // 0) * 100 | round / 100)/hr  \(($br.tokensPerMinute // 0) | round) tok/min  Total: \(.totalTokens) tok"'\'''
end
