#!/bin/bash
# bluera-base Configuration Library
# Provides functions for loading, saving, and managing plugin configuration
# Uses .bluera/bluera-base/ directory structure with deep merge support

# Default configuration (embedded as JSON)
BLUERA_BASE_DEFAULT_CONFIG='{
  "version": 1,
  "autoLearn": {
    "enabled": false,
    "mode": "suggest",
    "threshold": 3,
    "target": "local"
  },
  "milhouse": {
    "defaultMaxIterations": 0,
    "defaultStuckLimit": 3,
    "defaultGates": []
  },
  "notifications": {
    "enabled": true
  },
  "autoCommit": {
    "enabled": false,
    "onStop": true,
    "push": false,
    "remote": "origin"
  },
  "dryCheck": {
    "enabled": false,
    "onStop": false,
    "minTokens": 70,
    "minLines": 5
  },
  "strictTyping": {
    "enabled": false
  },
  "standardsReview": {
    "enabled": false,
    "mode": "warn"
  },
  "deepLearn": {
    "enabled": false,
    "model": "haiku",
    "maxBudget": 0.02
  }
}'

# Get the config directory path
# Prefers BLUERA_CONFIG env var (published by SessionStart hook via CLAUDE_ENV_FILE)
# Falls back to CLAUDE_PROJECT_DIR or current directory
# Usage: config_dir=$(bluera_config_dir)
bluera_config_dir() {
  if [[ -n "${BLUERA_CONFIG:-}" ]]; then
    # BLUERA_CONFIG points to config.json, return parent directory
    dirname "$BLUERA_CONFIG"
  else
    echo "${BLUERA_PROJECT_DIR:-${CLAUDE_PROJECT_DIR:-.}}/.bluera/bluera-base"
  fi
}

# Get the state directory path
# Prefers BLUERA_STATE_DIR env var (published by SessionStart hook via CLAUDE_ENV_FILE)
# Falls back to config_dir/state
# Usage: state_dir=$(bluera_state_dir)
bluera_state_dir() {
  if [[ -n "${BLUERA_STATE_DIR:-}" ]]; then
    echo "$BLUERA_STATE_DIR"
  else
    echo "$(bluera_config_dir)/state"
  fi
}

# Ensure config directory exists
# Usage: bluera_ensure_config_dir
bluera_ensure_config_dir() {
  local config_dir
  config_dir=$(bluera_config_dir)
  mkdir -p "$config_dir"
  mkdir -p "$(bluera_state_dir)"
}

# Load effective configuration (merged: defaults <- shared <- local)
# Usage: config=$(bluera_load_config)
bluera_load_config() {
  local config_dir shared_config local_config result
  config_dir=$(bluera_config_dir)
  shared_config="$config_dir/config.json"
  local_config="$config_dir/config.local.json"

  # Start with defaults
  result="$BLUERA_BASE_DEFAULT_CONFIG"

  # Merge shared config if exists
  if [[ -f "$shared_config" ]]; then
    result=$(echo "$result" | jq -s '.[0] * .[1]' - "$shared_config" 2>/dev/null || echo "$result")
  fi

  # Merge local config if exists
  if [[ -f "$local_config" ]]; then
    result=$(echo "$result" | jq -s '.[0] * .[1]' - "$local_config" 2>/dev/null || echo "$result")
  fi

  echo "$result"
}

# Get a config value by JSON path
# Usage: value=$(bluera_get_config ".autoLearn.enabled" "default_value")
bluera_get_config() {
  local path="$1"
  local default="${2:-}"
  local config
  config=$(bluera_load_config)
  local value
  value=$(echo "$config" | jq -r "$path // empty")
  if [[ -z "$value" ]] && [[ -n "$default" ]]; then
    echo "$default"
  else
    echo "$value"
  fi
}

# Check if a config value is true
# Usage: if bluera_config_enabled ".autoLearn.enabled"; then ...
bluera_config_enabled() {
  local path="$1"
  local value
  value=$(bluera_get_config "$path")
  [[ "$value" == "true" ]]
}

# Set a config value (writes to local config by default)
# Usage: bluera_set_config ".autoLearn.enabled" "true" [--shared]
bluera_set_config() {
  local path="$1"
  local value="$2"
  local target="${3:---local}"
  local config_dir config_file current

  config_dir=$(bluera_config_dir)
  bluera_ensure_config_dir

  if [[ "$target" == "--shared" ]]; then
    config_file="$config_dir/config.json"
  else
    config_file="$config_dir/config.local.json"
  fi

  # Load existing or start with empty object
  if [[ -f "$config_file" ]]; then
    current=$(cat "$config_file")
  else
    current="{}"
  fi

  # Set the value using jq
  # Handle different value types
  if [[ "$value" == "true" ]] || [[ "$value" == "false" ]]; then
    # Boolean
    current=$(echo "$current" | jq "$path = $value")
  elif [[ "$value" =~ ^[0-9]+$ ]]; then
    # Integer
    current=$(echo "$current" | jq "$path = $value")
  elif [[ "$value" =~ ^\[.*\]$ ]] || [[ "$value" =~ ^\{.*\}$ ]]; then
    # JSON array or object
    current=$(echo "$current" | jq --argjson val "$value" "$path = \$val")
  else
    # String
    current=$(echo "$current" | jq --arg val "$value" "$path = \$val")
  fi

  echo "$current" > "$config_file"
}

# Initialize config with defaults (creates config.json if not exists)
# Usage: bluera_init_config [--force]
bluera_init_config() {
  local force="${1:-}"
  local config_dir config_file

  config_dir=$(bluera_config_dir)
  config_file="$config_dir/config.json"

  bluera_ensure_config_dir

  if [[ -f "$config_file" ]] && [[ "$force" != "--force" ]]; then
    echo "Config already exists at $config_file" >&2
    return 1
  fi

  echo "$BLUERA_BASE_DEFAULT_CONFIG" | jq '.' > "$config_file"
  echo "Created $config_file"
}

# Check if config is initialized
# Usage: if bluera_config_exists; then ...
bluera_config_exists() {
  local config_dir
  config_dir=$(bluera_config_dir)
  [[ -f "$config_dir/config.json" ]] || [[ -f "$config_dir/config.local.json" ]]
}

# Display current effective config
# Usage: bluera_show_config
bluera_show_config() {
  local config
  config=$(bluera_load_config)
  echo "$config" | jq '.'
}

# Reset config to defaults (removes local overrides)
# Usage: bluera_reset_config [--all]
bluera_reset_config() {
  local all="${1:-}"
  local config_dir

  config_dir=$(bluera_config_dir)

  if [[ "$all" == "--all" ]]; then
    rm -f "$config_dir/config.json"
    rm -f "$config_dir/config.local.json"
    echo "Removed all config files"
  else
    rm -f "$config_dir/config.local.json"
    echo "Removed local config overrides"
  fi
}
