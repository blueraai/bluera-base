#!/bin/bash
# bluera-base Auto-learn Writing Functions
# Provides functions for writing learnings to CLAUDE.md files
# Used by session-end-learn.sh when autoLearn.mode is "auto"

# ok: Pattern definition below - not actual credentials
# Note: 'token' alone is too broad (matches tokenPath, tokenizer, max_tokens)
# Note: bare patterns too broad (matches config keys) # ok: meta-comment
# Use specific patterns with context (assignments, key suffixes)
BLUERA_SECRETS_PATTERN='api[_-]?key[[:space:]]*=|_token[[:space:]]*=|^token[[:space:]]*=|password[[:space:]]*=|secret[_-]?key[[:space:]]*=|_secret[[:space:]]*=|^secret[[:space:]]*=|-----BEGIN|AWS_|GITHUB_TOKEN|ANTHROPIC_API_KEY|OPENAI_API_KEY|HF_TOKEN|private[_-]?key[[:space:]]*=|credential[[:space:]]*=' # ok: pattern def

# Marker delimiters for auto-learned section
BLUERA_LEARN_START='<!-- AUTO:bluera-base:learned -->'
BLUERA_LEARN_END='<!-- END:bluera-base:learned -->'

# Resolve target config to file path
# Usage: target_file=$(bluera_autolearn_target_file)
bluera_autolearn_target_file() {
    local target
    target=$(bluera_get_config ".autoLearn.target")
    target="${target:-local}"

    case "$target" in
        local)  echo "CLAUDE.local.md" ;;
        shared) echo "CLAUDE.md" ;;
        *)      echo "CLAUDE.local.md" ;;
    esac
}

# Normalize string for comparison (lowercase, strip punctuation, trim)
# Usage: normalized=$(bluera_autolearn_normalize "Some Learning")
bluera_autolearn_normalize() {
    local text="$1"
    # Remove leading "- ", lowercase, strip extra whitespace
    echo "$text" | sed 's/^- //' | tr '[:upper:]' '[:lower:]' | xargs
}

# Check if learning already exists in target file
# Usage: if bluera_autolearn_is_duplicate "learning" "file.md"; then ...
bluera_autolearn_is_duplicate() {
    local learning="$1"
    local target_file="$2"

    [[ ! -f "$target_file" ]] && return 1

    local normalized
    normalized=$(bluera_autolearn_normalize "$learning")

    # Extract existing learnings from marker region
    local existing_learnings
    existing_learnings=$(sed -n "/$BLUERA_LEARN_START/,/$BLUERA_LEARN_END/p" "$target_file" 2>/dev/null | grep '^-' || true)

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local existing
        existing=$(bluera_autolearn_normalize "$line")
        if [[ "$normalized" == "$existing" ]]; then
            return 0  # Duplicate found
        fi
    done <<< "$existing_learnings"

    return 1  # No duplicate
}

# Create target file with initial structure if it doesn't exist
# Usage: bluera_autolearn_ensure_file "CLAUDE.local.md"
bluera_autolearn_ensure_file() {
    local target_file="$1"
    local target
    target=$(bluera_get_config ".autoLearn.target")
    target="${target:-local}"

    if [[ ! -f "$target_file" ]]; then
        if [[ "$target" == "shared" ]]; then
            cat > "$target_file" << 'EOF'
# CLAUDE.md

---

## Auto-Learned (bluera-base)
<!-- AUTO:bluera-base:learned -->
<!-- END:bluera-base:learned -->
EOF
        else
            cat > "$target_file" << 'EOF'
# CLAUDE.local.md (private, gitignored)

---

## Auto-Learned (bluera-base)
<!-- AUTO:bluera-base:learned -->
<!-- END:bluera-base:learned -->
EOF
        fi
        return 0
    fi

    # File exists but may not have markers - add them if missing
    if ! grep -q "$BLUERA_LEARN_START" "$target_file"; then
        cat >> "$target_file" << 'EOF'

---

## Auto-Learned (bluera-base)
<!-- AUTO:bluera-base:learned -->
<!-- END:bluera-base:learned -->
EOF
    fi

    return 0
}

# Write a learning to the target file
# Returns 0 on success, 1 on failure (secrets, capacity, etc.)
# Usage: bluera_autolearn_write "Run tests frequently"
bluera_autolearn_write() {
    local learning="$1"
    local target_file
    target_file=$(bluera_autolearn_target_file)

    # CRITICAL: Secrets check - never write content matching secrets pattern
    if echo "$learning" | grep -qiE "$BLUERA_SECRETS_PATTERN"; then
        echo "[bluera-base] BLOCKED: Learning contains potential secrets" >&2
        return 1
    fi

    # Ensure target file exists with markers
    bluera_autolearn_ensure_file "$target_file"

    # Check for duplicate
    if bluera_autolearn_is_duplicate "$learning" "$target_file"; then
        return 0  # Already exists, skip silently (success)
    fi

    # Hard cap check (50 learnings max)
    local count
    count=$(sed -n "/$BLUERA_LEARN_START/,/$BLUERA_LEARN_END/p" "$target_file" 2>/dev/null | grep -c '^-' || echo 0)
    if [[ $count -ge 50 ]]; then
        echo "[bluera-base] WARNING: Auto-learn section at capacity (50 learnings)" >&2
        return 1
    fi

    # Insert learning before END marker using sed
    # Note: Using | as delimiter since learning text won't contain it
    # Use temp file for portability (works on both BSD and GNU sed)
    # Escape sed replacement metacharacters (& and \) to prevent corruption
    local escaped_learning
    escaped_learning=$(printf '%s' "$learning" | sed 's/[&\]/\\&/g')
    local tmp_file
    tmp_file=$(mktemp)
    sed "s|$BLUERA_LEARN_END|- $escaped_learning\\
$BLUERA_LEARN_END|" "$target_file" > "$tmp_file" && mv "$tmp_file" "$target_file"

    return 0
}

# =============================================================================
# Global Memory Promotion (opt-in feature)
# =============================================================================

# Promote learning to global memory
# Usage: bluera_autolearn_promote_to_global "learning" "type" "confidence"
# Only promotes when: memory.enabled=true AND autoPromoteEnabled=true AND confidence >= threshold
bluera_autolearn_promote_to_global() {
    local learning="$1"
    local type="${2:-fact}"
    local confidence="${3:-0}"

    # Source memory library if not already loaded
    local script_dir="${BASH_SOURCE%/*}"
    if [[ -f "$script_dir/memory.sh" ]]; then
        # shellcheck source=./memory.sh
        source "$script_dir/memory.sh"
    fi

    # Skip if memory system not available
    type bluera_memory_create &>/dev/null || return 0

    # Check config: memory system must be enabled (default false)
    local mem_enabled
    mem_enabled=$(bluera_get_config ".memory.enabled" "false")
    [[ "$mem_enabled" != "true" ]] && return 0

    # Check config: auto-promote opt-in only (default false)
    local enabled threshold
    enabled=$(bluera_get_config ".deepLearn.autoPromoteEnabled" "false")
    threshold=$(bluera_get_config ".deepLearn.autoPromoteThreshold" "0.9")

    [[ "$enabled" != "true" ]] && return 0

    # Check confidence threshold
    if ! awk "BEGIN {exit !($confidence >= $threshold)}"; then
        return 0
    fi

    # Check for duplicate in global memory
    if bluera_memory_is_duplicate "$learning"; then
        echo "[bluera-base] Memory already exists (skipping promotion)" >&2
        return 0
    fi

    # Create with auto-generated tags
    local tags
    tags=$(bluera_memory_auto_tags "$learning" "promoted")
    tags="$tags,$type"

    local id
    id=$(bluera_memory_create "$learning" --tags "$tags")
    echo "[bluera-base] Promoted to global memory: $id" >&2
}
