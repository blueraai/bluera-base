# Preset Scripts

Ready-to-use statusline scripts. Copy to `~/.claude/statusline.sh` and make executable with `chmod +x`.

---

## Script: minimal

```bash
#!/bin/bash
# bluera-base-preset: minimal@0.40.0
input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
echo "$MODEL $CTX%"
```

---

## Script: informative

```bash
#!/bin/bash
# bluera-base-preset: informative@0.40.0
input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Status indicator
if [ "$CTX" -lt 50 ]; then STATUS="🟢"
elif [ "$CTX" -lt 80 ]; then STATUS="🟡"
else STATUS="🔴"; fi

# Format cost
if (( $(echo "$COST < 1" | bc -l 2>/dev/null || echo 1) )); then
    COST_FMT=$(printf "%.0f¢" "$(echo "$COST * 100" | bc -l 2>/dev/null || echo 0)")
else
    COST_FMT=$(printf "$%.2f" "$COST")
fi

echo "🤖 $MODEL │ 📊 ${CTX}%${STATUS} │ 💰 $COST_FMT"
```

---

## Script: developer

```bash
#!/bin/bash
# bluera-base-preset: developer@0.40.0
input=$(cat)

# Extract values
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
DIR_NAME=$(basename "$CURRENT_DIR")
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

# Status indicator
if [ "$CTX" -lt 50 ]; then STATUS="🟢"
elif [ "$CTX" -lt 80 ]; then STATUS="🟡"
else STATUS="🔴"; fi

# Format cost
if (( $(echo "$COST < 1" | bc -l 2>/dev/null || echo 1) )); then
    COST_FMT=$(printf "%.0f¢" "$(echo "$COST * 100" | bc -l 2>/dev/null || echo 0)")
else
    COST_FMT=$(printf "$%.2f" "$COST")
fi

# Git branch
GIT_INFO=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$(git -C "$CURRENT_DIR" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
        GIT_INFO="🌿${BRANCH}*"
    else
        GIT_INFO="🌿${BRANCH}"
    fi
fi

# Project type
PROJECT=""
if [ -f "$CURRENT_DIR/Cargo.toml" ]; then PROJECT="🦀Rust"
elif [ -f "$CURRENT_DIR/go.mod" ]; then PROJECT="🐹Go"
elif [ -f "$CURRENT_DIR/pyproject.toml" ] || [ -f "$CURRENT_DIR/requirements.txt" ]; then PROJECT="🐍Python"
elif [ -f "$CURRENT_DIR/package.json" ]; then
    if [ -f "$CURRENT_DIR/next.config.js" ] || [ -f "$CURRENT_DIR/next.config.ts" ]; then PROJECT="▲Next.js"
    elif [ -f "$CURRENT_DIR/bun.lockb" ]; then PROJECT="🍞Bun"
    else PROJECT="📦Node"
    fi
fi

# Build output
OUTPUT="📁$DIR_NAME │ 🤖$MODEL │ 📊${CTX}%${STATUS}"
[ -n "$GIT_INFO" ] && OUTPUT="$OUTPUT │ $GIT_INFO"
[ -n "$PROJECT" ] && OUTPUT="$OUTPUT │ $PROJECT"
OUTPUT="$OUTPUT │ 💰$COST_FMT"

echo "$OUTPUT"
```

---

## Script: system

```bash
#!/bin/bash
# bluera-base-preset: system@0.40.0
input=$(cat)

# Extract values
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir // "."')
DIR_NAME=$(basename "$CURRENT_DIR")
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

# Status indicator
if [ "$CTX" -lt 50 ]; then CTX_STATUS="🟢"
elif [ "$CTX" -lt 80 ]; then CTX_STATUS="🟡"
else CTX_STATUS="🔴"; fi

# Git branch
GIT_INFO=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" --no-optional-locks branch --show-current 2>/dev/null)
    GIT_INFO="🌿$BRANCH"
fi

# CPU usage (cross-platform)
CPU_PCT=0
if [[ "$OSTYPE" == "darwin"* ]]; then
    CPU_PCT=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | awk '{print int($3)}')
else
    CPU_PCT=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print int($2)}')
fi
if [ "$CPU_PCT" -lt 50 ]; then CPU_STATUS="🟢"
elif [ "$CPU_PCT" -lt 80 ]; then CPU_STATUS="🟡"
else CPU_STATUS="🔴"; fi

# Memory usage (cross-platform)
MEM_PCT=0
if [[ "$OSTYPE" == "darwin"* ]]; then
    MEM_PCT=$(vm_stat 2>/dev/null | awk '/Pages active/ {active=$3} /Pages inactive/ {inactive=$3} /Pages speculative/ {spec=$3} /Pages wired/ {wired=$4} /Pages free/ {free=$3} END {used=active+inactive+spec+wired; total=used+free; if(total>0) printf "%d", (used/total)*100}')
else
    MEM_PCT=$(free 2>/dev/null | awk '/Mem:/ {printf "%d", $3/$2*100}')
fi
if [ "$MEM_PCT" -lt 50 ]; then MEM_STATUS="🟢"
elif [ "$MEM_PCT" -lt 80 ]; then MEM_STATUS="🟡"
else MEM_STATUS="🔴"; fi

# Docker containers
DOCKER_COUNT=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')

# Build output
OUTPUT="📁$DIR_NAME │ 🤖$MODEL │ 📊${CTX}%${CTX_STATUS}"
[ -n "$GIT_INFO" ] && OUTPUT="$OUTPUT │ $GIT_INFO"
OUTPUT="$OUTPUT │ 💻${CPU_PCT}%${CPU_STATUS} │ 🧠${MEM_PCT}%${MEM_STATUS}"
[ "$DOCKER_COUNT" -gt 0 ] && OUTPUT="$OUTPUT │ 🐳$DOCKER_COUNT"

echo "$OUTPUT"
```

---

## Script: bluera

Advanced 2-line statusline with cache efficiency, reset timer, token usage, rate limits, context bar, and ANSI colors.

```bash
#!/bin/bash
# bluera-base-preset: bluera@0.41.0
# Bluera preset - advanced 2-line statusline with ANSI colors

input=$(cat)

# --- Bluera Config Status ---
get_bluera_status() {
    local project_dir="$1"
    local config_file="$project_dir/.bluera/bluera-base/config.json"
    local local_config="$project_dir/.bluera/bluera-base/config.local.json"

    # Not initialized — no badge
    if [ ! -f "$config_file" ] && [ ! -f "$local_config" ]; then
        echo ""
        return
    fi

    # Merge configs (shared ← local override) matching config.sh behavior
    local config=""
    if [ -f "$config_file" ] && [ -f "$local_config" ]; then
        config=$(jq -s '.[0] * .[1]' "$config_file" "$local_config" 2>/dev/null)
    elif [ -f "$local_config" ]; then
        config=$(cat "$local_config" 2>/dev/null)
    else
        config=$(cat "$config_file" 2>/dev/null)
    fi

    [ -z "$config" ] && echo "" && return

    local total enabled
    total=$(echo "$config" | jq '[to_entries[] | select(.value | type == "object" and has("enabled"))] | length' 2>/dev/null || echo 0)
    enabled=$(echo "$config" | jq '[to_entries[] | select(.value | type == "object" and .enabled == true)] | length' 2>/dev/null || echo 0)

    [ "$total" -eq 0 ] && echo "" && return

    printf " \033[38;5;33m⚡\033[36m%d/%d\033[0m" "$enabled" "$total"
}

# --- Project Type Detection ---
get_project_type() {
    local dir="$1"
    if [ -f "$dir/Cargo.toml" ]; then echo "🦀"
    elif [ -f "$dir/go.mod" ]; then echo "🐹"
    elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/requirements.txt" ]; then echo "🐍"
    elif [ -f "$dir/mix.exs" ]; then echo "💧"
    elif [ -f "$dir/Gemfile" ]; then echo "💎"
    elif [ -f "$dir/package.json" ]; then
        if [ -f "$dir/next.config.js" ] || [ -f "$dir/next.config.ts" ] || [ -f "$dir/next.config.mjs" ]; then echo "▲"
        elif [ -f "$dir/nuxt.config.ts" ] || [ -f "$dir/nuxt.config.js" ]; then echo "⚡"
        elif [ -f "$dir/vite.config.ts" ] || [ -f "$dir/vite.config.js" ]; then echo "⚡"
        elif [ -f "$dir/bun.lockb" ]; then echo "🍞"
        else echo "📦"
        fi
    elif [ -f "$dir/deno.json" ]; then echo "🦕"
    else echo ""
    fi
}

# --- Rate Limits (UNDOCUMENTED API - may break in future) ---
# WARNING: This uses an undocumented Anthropic endpoint and macOS keychain
# - Endpoint: https://api.anthropic.com/api/oauth/usage (not in official docs)
# - Auth: OAuth token from macOS keychain 'Claude Code-credentials'
# - Header: anthropic-beta: oauth-2025-04-20 (experimental)
# - Platform: macOS only (uses 'security' command)
# This may break if Anthropic changes credential storage or the API
get_rate_limits() {
    local cache_file="/tmp/.claude_usage_cache"
    local cache_max_age=60
    local usage_data=""

    # Check cache
    if [ -f "$cache_file" ]; then
        local cache_age=$(($(date +%s) - $(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [ "$cache_age" -lt "$cache_max_age" ]; then
            usage_data=$(cat "$cache_file")
        fi
    fi

    # Fetch if no cache (macOS keychain)
    if [ -z "$usage_data" ]; then
        local token
        token=$(security find-generic-password -s 'Claude Code-credentials' -w 2>/dev/null | jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
        if [ -n "$token" ]; then
            usage_data=$(curl -s --max-time 2 "https://api.anthropic.com/api/oauth/usage" \
                -H "Authorization: Bearer $token" \
                -H "anthropic-beta: oauth-2025-04-20" \
                -H "Accept: application/json" 2>/dev/null)
            [ -n "$usage_data" ] && echo "$usage_data" > "$cache_file" 2>/dev/null
        fi
    fi

    if [ -z "$usage_data" ]; then echo ""; return; fi

    local five_hour=$(echo "$usage_data" | jq -r '(.five_hour // .five_hour_opus // .five_hour_sonnet // {}).utilization // 0' 2>/dev/null)
    local seven_day=$(echo "$usage_data" | jq -r '(.seven_day // .seven_day_opus // .seven_day_sonnet // {}).utilization // 0' 2>/dev/null)

    local five_int=$(printf "%.0f" "$five_hour" 2>/dev/null || echo "0")
    local seven_int=$(printf "%.0f" "$seven_day" 2>/dev/null || echo "0")

    # Color based on usage
    local five_color="\033[32m"; [ "$five_int" -ge 50 ] && five_color="\033[33m"; [ "$five_int" -ge 75 ] && five_color="\033[38;5;208m"; [ "$five_int" -ge 95 ] && five_color="\033[31m"
    local seven_color="\033[32m"; [ "$seven_int" -ge 50 ] && seven_color="\033[33m"; [ "$seven_int" -ge 75 ] && seven_color="\033[38;5;208m"; [ "$seven_int" -ge 95 ] && seven_color="\033[31m"

    printf "${seven_color}7d:%d%%\033[0m ${five_color}5h:%d%%\033[0m" "$seven_int" "$five_int"
}

# --- Reset Timer (time until 5h rate limit resets) ---
get_reset_timer() {
    local cache_file="/tmp/.claude_usage_cache"
    [ ! -f "$cache_file" ] && echo "" && return

    local resets_at
    resets_at=$(jq -r '(.five_hour // .five_hour_opus // .five_hour_sonnet // {}).resets_at // empty' "$cache_file" 2>/dev/null)
    [ -z "$resets_at" ] && echo "" && return

    # Parse ISO timestamp to epoch — strip fractional secs and offset for macOS date
    local clean_ts="${resets_at%%.*}"  # strip .989255+00:00 or similar
    clean_ts="${clean_ts%%+*}"         # strip +00:00 if no fractional
    local reset_epoch
    reset_epoch=$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%S" "$clean_ts" +%s 2>/dev/null || date -d "$resets_at" +%s 2>/dev/null)
    [ -z "$reset_epoch" ] && echo "" && return

    local now=$(date +%s)
    local delta=$((reset_epoch - now))
    [ "$delta" -le 0 ] && echo "" && return

    local hours=$((delta / 3600))
    local mins=$(( (delta % 3600) / 60 ))

    if [ "$hours" -gt 0 ]; then
        printf "\033[38;5;245m↻%dh%dm\033[0m" "$hours" "$mins"
    else
        printf "\033[38;5;245m↻%dm\033[0m" "$mins"
    fi
}

# --- Cache Efficiency (cache read hit rate) ---
get_cache_efficiency() {
    local cache_read="$1" cache_create="$2"
    local total=$((cache_read + cache_create))
    [ "$total" -eq 0 ] && echo "" && return

    local pct=$((cache_read * 100 / total))

    # Green ≥50% (good cache reuse), yellow 25-49%, red <25%
    local color="\033[31m"
    [ "$pct" -ge 25 ] && color="\033[33m"
    [ "$pct" -ge 50 ] && color="\033[32m"

    printf "${color}C:%d%%\033[0m" "$pct"
}

# --- Session Duration ---
get_session_duration() {
    local duration_ms="$1"
    [ "$duration_ms" = "0" ] || [ -z "$duration_ms" ] && echo "" && return

    local secs=$((duration_ms / 1000))
    if [ "$secs" -lt 60 ]; then
        printf "\033[38;5;245m%ds\033[0m" "$secs"
    elif [ "$secs" -lt 3600 ]; then
        printf "\033[38;5;245m%dm\033[0m" $((secs / 60))
    else
        local h=$((secs / 3600)) m=$(( (secs % 3600) / 60 ))
        if [ "$m" -eq 0 ]; then
            printf "\033[38;5;245m%dh\033[0m" "$h"
        else
            printf "\033[38;5;245m%dh%dm\033[0m" "$h" "$m"
        fi
    fi
}

# --- Token Usage (compact) ---
get_token_usage() {
    local tokens="$1"
    [ "$tokens" -eq 0 ] 2>/dev/null && echo "" && return

    if [ "$tokens" -ge 1000000 ]; then
        local m=$((tokens / 1000000))
        local remainder=$(( (tokens % 1000000) / 100000 ))
        printf "\033[38;5;245m%d.%dM\033[0m" "$m" "$remainder"
    elif [ "$tokens" -ge 1000 ]; then
        printf "\033[38;5;245m%dK\033[0m" $((tokens / 1000))
    else
        printf "\033[38;5;245m%d\033[0m" "$tokens"
    fi
}

# Extract values
SESSION_ID=$(echo "$input" | jq -r '.session_id // ""' | cut -c1-6)
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
DIR_NAME=$(basename "$CURRENT_DIR")
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
DURATION_MS=$(echo "$input" | jq -r '.cost.total_duration_ms // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

# Calculate context percentage and token counts
INPUT_TOKENS=0; CACHE_CREATE=0; CACHE_READ=0; CURRENT_TOKENS=0
if [ "$USAGE" != "null" ] && [ -n "$USAGE" ]; then
    INPUT_TOKENS=$(echo "$USAGE" | jq '.input_tokens // 0')
    CACHE_CREATE=$(echo "$USAGE" | jq '.cache_creation_input_tokens // 0')
    CACHE_READ=$(echo "$USAGE" | jq '.cache_read_input_tokens // 0')
    CURRENT_TOKENS=$((INPUT_TOKENS + CACHE_CREATE + CACHE_READ))
    CONTEXT_PCT=$((CURRENT_TOKENS * 100 / CONTEXT_SIZE))
else
    CONTEXT_PCT=0
fi

# Git info with colors
GIT_INFO=""
if git -C "$CURRENT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
    BRANCH=$(git -C "$CURRENT_DIR" --no-optional-locks branch --show-current 2>/dev/null)
    SHORT_SHA=$(git -C "$CURRENT_DIR" --no-optional-locks rev-parse --short=6 HEAD 2>/dev/null)
    BRANCH_ICON=$(printf '\xee\x82\xa0')
    if [ -n "$(git -C "$CURRENT_DIR" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
        GIT_INFO=$(printf "\033[34m%s\033[0m \033[33m%s %s\033[31m*\033[0m" "$SHORT_SHA" "$BRANCH_ICON" "$BRANCH")
    else
        GIT_INFO=$(printf "\033[34m%s\033[0m \033[32m%s\033[0m \033[36m%s\033[0m" "$SHORT_SHA" "$BRANCH_ICON" "$BRANCH")
    fi
fi

# Format cost
if (( $(echo "$COST < 1" | bc -l) )); then
    COST_FMT=$(printf "%.0f¢" "$(echo "$COST * 100" | bc -l)")
else
    COST_FMT=$(printf "$%.2f" "$COST")
fi

# Format lines changed
if [ "$LINES_ADDED" -gt 0 ] || [ "$LINES_REMOVED" -gt 0 ]; then
    LINES_FMT=$(printf "\033[32m+%d\033[0m/\033[31m-%d\033[0m" "$LINES_ADDED" "$LINES_REMOVED")
else
    LINES_FMT="-"
fi

# Build context bar (10 chars wide)
BAR_WIDTH=10
FILLED=$((CONTEXT_PCT * BAR_WIDTH / 100))
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""; for ((i=0; i<FILLED; i++)); do BAR+="█"; done; for ((i=0; i<EMPTY; i++)); do BAR+="░"; done

# Project type, bluera status, and rate limits
PROJECT_TYPE=$(get_project_type "$CURRENT_DIR")
[ -n "$PROJECT_TYPE" ] && PROJECT_TYPE="$PROJECT_TYPE "

PROJECT_DIR=$(echo "$input" | jq -r '.workspace.project_dir // empty')
[ -z "$PROJECT_DIR" ] && PROJECT_DIR="$CURRENT_DIR"
BLUERA_STATUS=$(get_bluera_status "$PROJECT_DIR")

RATE_LIMITS=$(get_rate_limits)
RESET_TIMER=$(get_reset_timer)
[ -n "$RESET_TIMER" ] && RESET_TIMER=" $RESET_TIMER"

# New metrics
CACHE_EFF=$(get_cache_efficiency "$CACHE_READ" "$CACHE_CREATE")
[ -n "$CACHE_EFF" ] && CACHE_EFF=" $CACHE_EFF"

TOKEN_FMT=$(get_token_usage "$CURRENT_TOKENS")
[ -n "$TOKEN_FMT" ] && TOKEN_FMT=" $TOKEN_FMT"

DURATION_FMT=$(get_session_duration "$DURATION_MS")
[ -n "$DURATION_FMT" ] && DURATION_FMT="$DURATION_FMT"

# Separator: dark gray middle dot
SEP=$(printf " \033[38;5;240m·\033[0m ")

# Format session ID prefix (blood orange)
SID_FMT=""
[ -n "$SESSION_ID" ] && SID_FMT=$(printf "\033[38;5;166m%s\033[0m " "$SESSION_ID")

# Context bar color
if [ "$CONTEXT_PCT" -lt 50 ]; then
    BAR_COLOR="\033[32m"
elif [ "$CONTEXT_PCT" -lt 80 ]; then
    BAR_COLOR="\033[33m"
else
    BAR_COLOR="\033[31m"
fi

# Build rate limit segment (7d + 5h + reset)
RATE_SEG=""
if [ -n "$RATE_LIMITS" ]; then
    RATE_SEG="${SEP}$RATE_LIMITS$RESET_TIMER"
fi

# Build cost segment
COST_SEG=$(printf "%s\033[33m%s\033[0m" "$SEP" "$COST_FMT")

# Build plugin status segment for line 2
PLUGIN_SEG=""
[ -n "$BLUERA_STATUS" ] && PLUGIN_SEG="${SEP}$BLUERA_STATUS"

# Line 1: session_id stack project · model ctx_bar ctx% tokens cache · 7d 5h reset · cost
printf "%s%s\033[1m%s\033[0m%s\033[35m%s\033[0m %b%s\033[0m %d%%%s%s%s%s\n" \
    "$SID_FMT" "$PROJECT_TYPE" "$DIR_NAME" "$SEP" \
    "$MODEL" "$BAR_COLOR" "$BAR" "$CONTEXT_PCT" "$TOKEN_FMT" "$CACHE_EFF" "$RATE_SEG" "$COST_SEG"

# Line 2: sha branch lines · duration · bluera
printf "%s %s%s%s%s" "$GIT_INFO" "$LINES_FMT" "$SEP" "$DURATION_FMT" "$PLUGIN_SEG"
```
