# Preset Scripts

Ready-to-use statusline scripts. Copy to `~/.claude/statusline.sh` and make executable with `chmod +x`.

---

## Script: minimal

```bash
#!/bin/bash
input=$(cat)
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CTX=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
echo "$MODEL $CTX%"
```

---

## Script: informative

```bash
#!/bin/bash
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

Advanced statusline with rate limits, context bar, and ANSI colors.

```bash
#!/bin/bash
# Bluera preset - advanced statusline with rate limits, context bar, and ANSI colors

input=$(cat)

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

    printf "${five_color}5h:%d%%\033[0m ${seven_color}7d:%d%%\033[0m" "$five_int" "$seven_int"
}

# Extract values
MODEL=$(echo "$input" | jq -r '.model.display_name // "?"')
CURRENT_DIR=$(echo "$input" | jq -r '.workspace.current_dir')
DIR_NAME=$(basename "$CURRENT_DIR")
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
USAGE=$(echo "$input" | jq '.context_window.current_usage')

# Calculate context percentage
if [ "$USAGE" != "null" ]; then
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
    if [ -n "$(git -C "$CURRENT_DIR" --no-optional-locks status --porcelain 2>/dev/null)" ]; then
        GIT_INFO=$(printf " \033[33m%s\033[0m\033[31m*\033[0m" "$BRANCH")
    else
        GIT_INFO=$(printf " \033[36m%s\033[0m" "$BRANCH")
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

# Project type and rate limits
PROJECT_TYPE=$(get_project_type "$CURRENT_DIR")
[ -n "$PROJECT_TYPE" ] && PROJECT_TYPE=" $PROJECT_TYPE"

RATE_LIMITS=$(get_rate_limits)
[ -n "$RATE_LIMITS" ] && RATE_LIMITS=" │ $RATE_LIMITS"

# Output with colored context bar
if [ "$CONTEXT_PCT" -lt 50 ]; then
    printf "\033[35m%s\033[0m \033[1m%s\033[0m%s%s │ \033[33m%s\033[0m │ \033[32m%s\033[0m %d%% │ %s%s" \
        "$MODEL" "$DIR_NAME" "$PROJECT_TYPE" "$GIT_INFO" "$COST_FMT" "$BAR" "$CONTEXT_PCT" "$LINES_FMT" "$RATE_LIMITS"
elif [ "$CONTEXT_PCT" -lt 80 ]; then
    printf "\033[35m%s\033[0m \033[1m%s\033[0m%s%s │ \033[33m%s\033[0m │ \033[33m%s\033[0m %d%% │ %s%s" \
        "$MODEL" "$DIR_NAME" "$PROJECT_TYPE" "$GIT_INFO" "$COST_FMT" "$BAR" "$CONTEXT_PCT" "$LINES_FMT" "$RATE_LIMITS"
else
    printf "\033[35m%s\033[0m \033[1m%s\033[0m%s%s │ \033[33m%s\033[0m │ \033[31m%s\033[0m %d%% │ %s%s" \
        "$MODEL" "$DIR_NAME" "$PROJECT_TYPE" "$GIT_INFO" "$COST_FMT" "$BAR" "$CONTEXT_PCT" "$LINES_FMT" "$RATE_LIMITS"
fi
```
