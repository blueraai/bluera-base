# Statusline Modules

Complete module implementations for statusline scripts.

---

## Module: directory

Current directory name (basename only).

```bash
# --- directory ---
get_directory() {
  local dir
  dir=$(json_get "$INPUT" '.workspace.current_dir')
  if [ -n "$dir" ]; then
    echo "${ICON_DIR}$(basename "$dir")"
  fi
}
DIRECTORY=$(get_directory)
```

---

## Module: model

Claude model display name.

```bash
# --- model ---
get_model() {
  local model
  model=$(json_get "$INPUT" '.model.display_name' 'Claude')
  # Shorten common names
  case "$model" in
    "Claude Opus 4.5") echo "${ICON_MODEL}Opus4.5" ;;
    "Claude Sonnet 4") echo "${ICON_MODEL}Sonnet4" ;;
    "Claude Haiku 3.5") echo "${ICON_MODEL}Haiku3.5" ;;
    *) echo "${ICON_MODEL}${model}" ;;
  esac
}
MODEL=$(get_model)
```

---

## Module: context

Context window usage with optional progress bar.

```bash
# --- context ---
get_context() {
  local pct
  pct=$(json_get "$INPUT" '.context_window.used_percentage' '0')
  pct=$(safe_int "$pct")

  local status
  status=$(get_status "$pct" 50 75)

  if [ "$DISPLAY_MODE" = "verbose" ]; then
    local bar
    bar=$(progress_bar "$pct" 10)
    echo "${ICON_CONTEXT}${bar} ${pct}%${status}"
  else
    echo "${ICON_CONTEXT}${pct}%${status}"
  fi
}
CONTEXT=$(get_context)
```

---

## Module: git

Branch name and status indicators.

```bash
# --- git ---
get_git() {
  local dir
  dir=$(json_get "$INPUT" '.workspace.current_dir')
  [ -z "$dir" ] && return

  local branch
  branch=$(cd "$dir" 2>/dev/null && git branch --show-current 2>/dev/null) || return
  [ -z "$branch" ] && return

  local status_indicator=""
  if [ "$DISPLAY_MODE" != "compact" ]; then
    # Check for uncommitted changes
    if cd "$dir" && ! git diff --quiet 2>/dev/null; then
      status_indicator="*"
    fi
    # Check for staged changes
    if cd "$dir" && ! git diff --cached --quiet 2>/dev/null; then
      status_indicator="${status_indicator}+"
    fi
  fi

  echo "${ICON_GIT}${branch}${status_indicator}"
}
GIT=$(get_git)
```

---

## Module: cost

Session cost in USD.

```bash
# --- cost ---
get_cost() {
  local cost
  cost=$(json_get "$INPUT" '.total_cost_usd' '0')

  # Skip if zero or empty
  [ "$cost" = "0" ] || [ -z "$cost" ] && return

  # Format based on magnitude
  if (( $(echo "$cost >= 1" | bc -l 2>/dev/null || echo 0) )); then
    printf "${ICON_COST}\$%.2f" "$cost"
  else
    printf "${ICON_COST}\$%.3f" "$cost"
  fi
}
COST=$(get_cost)
```

---

## Module: rate-limits

API usage via OAuth token (5h/7d limits).

```bash
# --- rate-limits ---
get_rate_limits() {
  # Get OAuth token from Claude config
  local token_file="$HOME/.claude/.credentials"
  [ ! -f "$token_file" ] && return

  local access_token
  access_token=$(jq -r '.oauth.accessToken // empty' "$token_file" 2>/dev/null)
  [ -z "$access_token" ] && return

  # Fetch usage (with timeout)
  local usage
  usage=$(curl -s --max-time 2 \
    -H "Authorization: Bearer $access_token" \
    "https://api.claude.ai/api/usage" 2>/dev/null)
  [ -z "$usage" ] && return

  # Parse usage (example fields - adjust based on actual API)
  local hour_pct day_pct
  hour_pct=$(echo "$usage" | jq -r '.fiveHourUsagePercent // 0' 2>/dev/null)
  day_pct=$(echo "$usage" | jq -r '.sevenDayUsagePercent // 0' 2>/dev/null)

  hour_pct=$(safe_int "$hour_pct")
  day_pct=$(safe_int "$day_pct")

  local hour_status day_status
  hour_status=$(get_status_4level "$hour_pct" 25 50 75)
  day_status=$(get_status_4level "$day_pct" 25 50 75)

  echo "${ICON_RATE}5h:${hour_pct}%${hour_status} 7d:${day_pct}%${day_status}"
}
RATE_LIMITS=$(get_rate_limits)
```

---

## Module: project

Detect project type by manifest files.

```bash
# --- project ---
get_project() {
  local dir
  dir=$(json_get "$INPUT" '.workspace.current_dir')
  [ -z "$dir" ] && return

  # Priority order - check most specific first
  if [ -f "$dir/Cargo.toml" ]; then
    echo "${ICON_PROJECT}Rust"
  elif [ -f "$dir/go.mod" ]; then
    echo "${ICON_PROJECT}Go"
  elif [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ]; then
    echo "${ICON_PROJECT}Python"
  elif [ -f "$dir/package.json" ]; then
    # Check for specific frameworks
    if [ -f "$dir/next.config.js" ] || [ -f "$dir/next.config.mjs" ]; then
      echo "${ICON_PROJECT}Next.js"
    elif [ -f "$dir/nuxt.config.ts" ] || [ -f "$dir/nuxt.config.js" ]; then
      echo "${ICON_PROJECT}Nuxt"
    elif [ -f "$dir/vite.config.ts" ] || [ -f "$dir/vite.config.js" ]; then
      echo "${ICON_PROJECT}Vite"
    elif [ -f "$dir/tsconfig.json" ]; then
      echo "${ICON_PROJECT}TypeScript"
    else
      echo "${ICON_PROJECT}Node"
    fi
  elif [ -f "$dir/Gemfile" ]; then
    echo "${ICON_PROJECT}Ruby"
  elif [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ]; then
    echo "${ICON_PROJECT}Java"
  elif [ -f "$dir/composer.json" ]; then
    echo "${ICON_PROJECT}PHP"
  elif [ -f "$dir/mix.exs" ]; then
    echo "${ICON_PROJECT}Elixir"
  elif [ -f "$dir/pubspec.yaml" ]; then
    echo "${ICON_PROJECT}Dart"
  fi
}
PROJECT=$(get_project)
```

---

## Module: lines-changed

Lines added/removed in current session (approximation via git).

```bash
# --- lines-changed ---
get_lines_changed() {
  local dir
  dir=$(json_get "$INPUT" '.workspace.current_dir')
  [ -z "$dir" ] && return

  cd "$dir" 2>/dev/null || return

  # Get diff stats (staged + unstaged)
  local stats
  stats=$(git diff --stat HEAD 2>/dev/null | tail -1)
  [ -z "$stats" ] && return

  # Parse "X files changed, Y insertions(+), Z deletions(-)"
  local insertions deletions
  insertions=$(echo "$stats" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
  deletions=$(echo "$stats" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)

  [ "$insertions" = "0" ] && [ "$deletions" = "0" ] && return

  echo "${ICON_LINES}+${insertions}/-${deletions}"
}
LINES_CHANGED=$(get_lines_changed)
```

---

## Module: battery (macOS)

Battery percentage with charging indicator.

```bash
# --- battery ---
get_battery() {
  # macOS only
  [ "$(uname)" != "Darwin" ] && return

  local battery_info
  battery_info=$(pmset -g batt 2>/dev/null)
  [ -z "$battery_info" ] && return

  local pct charging
  pct=$(echo "$battery_info" | grep -oE '[0-9]+%' | head -1 | tr -d '%')
  [ -z "$pct" ] && return

  charging=""
  echo "$battery_info" | grep -q "charging" && charging="+"
  echo "$battery_info" | grep -q "AC Power" && charging="⚡"

  local status
  # Battery: low is critical (inverted thresholds)
  if (( pct <= 10 )); then
    status="$STATUS_CRIT"
  elif (( pct <= 25 )); then
    status="$STATUS_WARN"
  else
    status="$STATUS_OK"
  fi

  echo "${ICON_BATTERY}${pct}%${charging}${status}"
}
BATTERY=$(get_battery)
```

---

## Module: cpu

CPU usage percentage.

```bash
# --- cpu ---
get_cpu() {
  local cpu_pct

  if [ "$(uname)" = "Darwin" ]; then
    # macOS
    cpu_pct=$(top -l 1 -n 0 2>/dev/null | grep "CPU usage" | awk '{print int($3)}')
  else
    # Linux
    cpu_pct=$(top -bn1 2>/dev/null | grep "Cpu(s)" | awk '{print int($2)}')
  fi

  [ -z "$cpu_pct" ] && return

  local status
  status=$(get_status "$cpu_pct" 50 80)

  echo "${ICON_CPU}${cpu_pct}%${status}"
}
CPU=$(get_cpu)
```

---

## Module: memory

RAM usage percentage.

```bash
# --- memory ---
get_memory() {
  local mem_pct

  if [ "$(uname)" = "Darwin" ]; then
    # macOS - approximate from vm_stat
    local page_size pages_free pages_active pages_speculative pages_wired
    page_size=$(pagesize 2>/dev/null || echo 4096)

    local vm_stats
    vm_stats=$(vm_stat 2>/dev/null)
    pages_free=$(echo "$vm_stats" | awk '/Pages free/ {gsub(/\./,""); print $3}')
    pages_active=$(echo "$vm_stats" | awk '/Pages active/ {gsub(/\./,""); print $3}')
    pages_speculative=$(echo "$vm_stats" | awk '/Pages speculative/ {gsub(/\./,""); print $3}')
    pages_wired=$(echo "$vm_stats" | awk '/Pages wired/ {gsub(/\./,""); print $4}')

    local total_mem used_mem
    total_mem=$(sysctl -n hw.memsize 2>/dev/null)
    used_mem=$(( (pages_active + pages_wired) * page_size ))

    [ -z "$total_mem" ] || [ "$total_mem" = "0" ] && return
    mem_pct=$(( used_mem * 100 / total_mem ))
  else
    # Linux
    mem_pct=$(free 2>/dev/null | awk '/Mem:/ {printf "%.0f", $3/$2 * 100}')
  fi

  [ -z "$mem_pct" ] && return

  local status
  status=$(get_status "$mem_pct" 60 85)

  echo "${ICON_MEM}${mem_pct}%${status}"
}
MEMORY=$(get_memory)
```

---

## Module: docker

Running container count.

```bash
# --- docker ---
get_docker() {
  command -v docker &>/dev/null || return

  local count
  count=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ')

  [ "$count" = "0" ] && return

  echo "${ICON_DOCKER}${count}"
}
DOCKER=$(get_docker)
```

---

## Module: time

Current time display.

```bash
# --- time ---
get_time() {
  if [ "$DISPLAY_MODE" = "verbose" ]; then
    echo "${ICON_TIME}$(date '+%Y-%m-%d %H:%M')"
  else
    echo "${ICON_TIME}$(date '+%H:%M')"
  fi
}
TIME=$(get_time)
```

---

## Module: cca-status

Claude Code Anywhere status.

```bash
# --- claude-code-anywhere status ---
get_cca_status() {
  local port_file="$HOME/.config/claude-code-anywhere/port"
  [ ! -f "$port_file" ] && return

  local port
  port=$(cat "$port_file" 2>/dev/null)
  [ -z "$port" ] && return

  # Check if service is responding
  local status
  if curl -s --max-time 1 "http://127.0.0.1:${port}/health" &>/dev/null; then
    status="${STATUS_OK}"
  else
    status="${STATUS_WARN}"
  fi

  echo "${ICON_CCA}CCA${status}"
}
CCA_STATUS=$(get_cca_status)
```
