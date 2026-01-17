#!/usr/bin/env bash
# bluera-base Session Signals State Management
# Provides functions for tracking command usage patterns during a session
# Signals are stored in .bluera/bluera-base/state/session-signals.json

# Get the path to the signals file
# Usage: file=$(bluera_signals_file)
bluera_signals_file() {
  local state_dir
  state_dir=$(bluera_state_dir)
  echo "${state_dir}/session-signals.json"
}

# Load signals from file (returns default if file doesn't exist)
# Usage: signals=$(bluera_load_signals)
bluera_load_signals() {
  local file
  file=$(bluera_signals_file)
  if [[ -f "$file" ]]; then
    cat "$file"
  else
    echo '{"commands":{},"session_id":"","started_at":""}'
  fi
}

# Save signals to file
# Usage: bluera_save_signals "$signals"
bluera_save_signals() {
  local signals="$1"
  local file
  file=$(bluera_signals_file)
  echo "$signals" > "$file"
}

# Initialize signals for a new session
# Usage: bluera_init_signals "session-id-123"
bluera_init_signals() {
  local session_id="$1"
  local now
  now=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local signals='{"commands":{},"session_id":"'"$session_id"'","started_at":"'"$now"'"}'
  bluera_save_signals "$signals"
}

# Increment the count for a command
# Usage: bluera_increment_signal "git:status"
bluera_increment_signal() {
  local cmd="$1"
  local signals
  signals=$(bluera_load_signals)
  signals=$(echo "$signals" | jq --arg cmd "$cmd" '.commands[$cmd] = ((.commands[$cmd] // 0) + 1)')
  bluera_save_signals "$signals"
}

# Get the count for a command (returns 0 if not found)
# Usage: count=$(bluera_get_signal_count "git:status")
bluera_get_signal_count() {
  local cmd="$1"
  local signals
  signals=$(bluera_load_signals)
  echo "$signals" | jq -r --arg cmd "$cmd" '.commands[$cmd] // 0'
}

# Get the session ID from signals
# Usage: session_id=$(bluera_signals_session_id)
bluera_signals_session_id() {
  local signals
  signals=$(bluera_load_signals)
  echo "$signals" | jq -r '.session_id // ""'
}

# Check if signals exist for a different session (needs reset)
# Usage: if bluera_signals_session_changed "new-session-id"; then ...
bluera_signals_session_changed() {
  local new_session_id="$1"
  local stored_session
  stored_session=$(bluera_signals_session_id)
  [[ -n "$stored_session" ]] && [[ "$stored_session" != "$new_session_id" ]]
}

# Remove the signals file
# Usage: bluera_clear_signals
bluera_clear_signals() {
  local file
  file=$(bluera_signals_file)
  rm -f "$file"
}
