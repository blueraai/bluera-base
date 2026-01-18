#!/bin/bash
# bluera-base Auto-learn Writing Functions
# Provides functions for writing learnings to CLAUDE.md files
# Used by session-end-learn.sh when autoLearn.mode is "auto"

# Secrets pattern - NEVER write content matching these
BLUERA_SECRETS_PATTERN='api[_-]?key|token|password|secret|-----BEGIN|AWS_|GITHUB_TOKEN|ANTHROPIC_API|OPENAI_API|private[_-]?key|credential'

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
    sed -i '' "s|$BLUERA_LEARN_END|- $learning\\
$BLUERA_LEARN_END|" "$target_file"

    return 0
}
