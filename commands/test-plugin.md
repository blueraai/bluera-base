---
description: Run comprehensive plugin validation test suite
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Test Plugin

Comprehensive test of all Bluera Base plugin functionality (hooks + slash commands).

## Context

!`echo "Hooks: $(ls hooks/*.sh 2>/dev/null | wc -l) files"`

## Pre-Test Cleanup

Remove any leftover artifacts from previous test runs:

```bash
rm -rf .bluera/bluera-base/state/milhouse-loop.md
rm -rf /tmp/bluera-base-test
```

## Test Content Setup

Create a temporary test directory with various project types:

```bash
mkdir -p /tmp/bluera-base-test
cd /tmp/bluera-base-test
git init
echo '{"name": "test-project", "version": "1.0.0"}' > package.json
echo 'console.log("test");' > index.js
git add .
git commit -m "initial"
```

## Workflow

Execute each test in order. Mark each as PASS or FAIL.

### Part 1: Hook Registration

1. **Hook File Structure**: Verify hooks.json has expected structure

   ```bash
   PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
   cat "$PLUGIN_PATH/hooks/hooks.json" | jq -e '.hooks.PreToolUse and .hooks.PostToolUse and .hooks.Stop and .hooks.Notification'
   ```

   - Expected: Returns `true` (all hook types registered)
   - PASS if command succeeds with truthy output

2. **Hook Scripts Exist**: Verify all hook scripts are present and executable

   ```bash
   PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
   ls -la "$PLUGIN_PATH/hooks/"*.sh | wc -l
   ```

   - Expected: 10 shell scripts (block-manual-release, milhouse-setup, milhouse-stop, notify, observe-learning, post-edit-check, pre-compact, session-end-learn, session-setup, session-start-inject)
   - PASS if count is 10

### Part 2: PreToolUse Hook (block-manual-release.sh)

1. **Block npm version**: Test that manual npm version is blocked

   ```bash
   PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
   echo '{"tool_input": {"command": "npm version patch"}}' | bash "$PLUGIN_PATH/hooks/block-manual-release.sh" 2>&1
   echo "Exit code: $?"
   ```

   - Expected: Message about using /release, exit code 2
   - PASS if output contains "Use /release" and exits 2

2. **Block git tag**: Test that manual git tagging is blocked

   ```bash
   PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
   echo '{"tool_input": {"command": "git tag v1.0.0"}}' | bash "$PLUGIN_PATH/hooks/block-manual-release.sh" 2>&1
   echo "Exit code: $?"
   ```

   - Expected: Blocked with exit code 2
   - PASS if exits 2

3. **Allow skill-prefixed release**: Test that /bluera-base:release skill can run version commands

   ```bash
   PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
   echo '{"tool_input": {"command": "__SKILL__=release npm version patch"}}' | bash "$PLUGIN_PATH/hooks/block-manual-release.sh"
   echo "Exit code: $?"
   ```

   - Expected: Allowed (exit code 0)
   - PASS if exits 0

4. **Allow normal commands**: Test that non-release commands pass through

   ```bash
   PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
   echo '{"tool_input": {"command": "npm install express"}}' | bash "$PLUGIN_PATH/hooks/block-manual-release.sh"
   echo "Exit code: $?"
   ```

   - Expected: Allowed (exit code 0)
   - PASS if exits 0

### Part 3: PostToolUse Hook (post-edit-check.sh)

1. **Anti-pattern Detection**: Test detection of forbidden words

   ```bash
   cd /tmp/bluera-base-test
   echo 'const fallback = true;' >> index.js
   git add index.js
   CLAUDE_PROJECT_DIR="/tmp/bluera-base-test" PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}" bash "$PLUGIN_PATH/hooks/post-edit-check.sh" 2>&1
   EXIT=$?
   git checkout index.js 2>/dev/null
   echo "Exit code: $EXIT"
   ```

   - Expected: Detects "fallback" anti-pattern, exit code 2
   - PASS if output mentions anti-pattern and exits 2

2. **Clean Code Passes**: Test that clean code passes validation

   ```bash
   cd /tmp/bluera-base-test
   echo 'const clean = true;' >> index.js
   git add index.js
   CLAUDE_PROJECT_DIR="/tmp/bluera-base-test" PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}" bash "$PLUGIN_PATH/hooks/post-edit-check.sh" 2>&1
   EXIT=$?
   git checkout index.js 2>/dev/null
   echo "Exit code: $EXIT"
   ```

   - Expected: No output, exit code 0
   - PASS if exits 0

### Part 4: Stop Hook (milhouse-stop.sh)

1. **No State File**: Test that hook exits cleanly when no milhouse loop active

   ```bash
   cd /tmp/bluera-base-test
   rm -rf .bluera/bluera-base/state/milhouse-loop.md
   PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
   echo '{"transcript_path": "/tmp/test.jsonl"}' | bash "$PLUGIN_PATH/hooks/milhouse-stop.sh" 2>&1
   echo "Exit code: $?"
   ```

   - Expected: Silent exit 0 (no active loop)
   - PASS if exits 0 with no output

2. **Invalid Iteration**: Test handling of corrupted state file

    ```bash
    cd /tmp/bluera-base-test
    mkdir -p .bluera/bluera-base/state
    printf '%s\n' '---' 'iteration: invalid' 'max_iterations: 5' 'completion_promise: "done"' '---' '' 'test prompt' > .bluera/bluera-base/state/milhouse-loop.md
    PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
    echo '{"transcript_path": "/tmp/test.jsonl"}' | bash "$PLUGIN_PATH/hooks/milhouse-stop.sh" 2>&1
    EXIT=$?
    echo "Exit code: $EXIT"
    ```

    - Expected: Warning about invalid iteration, removes file, exits 0
    - PASS if mentions "invalid" and exits 0

### Part 5: Milhouse Setup Hook

1. **Setup Creates State File**: Test milhouse-setup.sh creates proper state

    ```bash
    cd /tmp/bluera-base-test
    rm -rf .bluera/bluera-base/state/milhouse-loop.md
    PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
    CLAUDE_PROJECT_DIR="/tmp/bluera-base-test" bash "$PLUGIN_PATH/hooks/milhouse-setup.sh" --inline "Build the feature" --max-iterations 10 2>&1
    cat .bluera/bluera-base/state/milhouse-loop.md 2>/dev/null | head -10
    ```

    - Expected: State file created with iteration: 1, max_iterations: 10
    - PASS if file exists with correct fields

### Part 6: Slash Commands (Invocation Test)

1. **Commit Command Available**: Run `/bluera-base:commit` (will show clean status)
    - Expected: Shows git status and workflow instructions
    - PASS if command executes without error

2. **Cancel Milhouse Available**: Verify cancel command works when no loop active

    ```bash
    rm -rf /tmp/bluera-base-test/.bluera/bluera-base/state/milhouse-loop.md
    ```

    Then run `/bluera-base:cancel-milhouse`
    - Expected: Message about no active loop
    - PASS if command executes

### Part 7: Skills Verification

1. **Skills Directory Structure**: Verify all skills exist

    ```bash
    PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
    ls -d "$PLUGIN_PATH/skills/"*/
    ```

    - Expected: Lists 7 skill directories (architectural-constraints, atomic-commits, claude-md-maintainer, code-review-repo, milhouse, readme-maintainer, release)
    - PASS if all 7 skill directories exist

2. **Atomic Commits Skill**: Verify skill file is readable

    ```bash
    PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
    head -5 "$PLUGIN_PATH/skills/atomic-commits/SKILL.md"
    ```

    - Expected: Shows skill header/title
    - PASS if file is readable

3. **Milhouse Skill**: Verify skill file is readable

    ```bash
    PLUGIN_PATH="${CLAUDE_PLUGIN_ROOT:-$(pwd)}"
    head -5 "$PLUGIN_PATH/skills/milhouse/SKILL.md"
    ```

    - Expected: Shows skill header/title
    - PASS if file is readable

### Part 8: Cleanup

1. **Remove Test Directory**: Clean up test artifacts

    ```bash
    rm -rf /tmp/bluera-base-test
    rm -rf .bluera/bluera-base/state/milhouse-loop.md
    ```

    - Expected: Directory removed
    - PASS if command succeeds

2. **Verify Cleanup**: Confirm test directory is gone

    ```bash
    ls /tmp/bluera-base-test 2>&1 || echo "Cleanup successful"
    ```

    - Expected: Directory not found
    - PASS if directory doesn't exist

## Output Format

After running all tests, report results in this format:

### Plugin Test Results

| # | Test | Status |
|---|------|--------|
| 1 | Hook File Structure | ? |
| 2 | Hook Scripts Exist | ? |
| 3 | Block npm version | ? |
| 4 | Block git tag | ? |
| 5 | Allow skill-prefixed release | ? |
| 6 | Allow normal commands | ? |
| 7 | Anti-pattern Detection | ? |
| 8 | Clean Code Passes | ? |
| 9 | No State File (milhouse-stop) | ? |
| 10 | Invalid Iteration Handling | ? |
| 11 | Setup Creates State File | ? |
| 12 | /bluera-base:commit Command | ? |
| 13 | /bluera-base:cancel-milhouse Command | ? |
| 14 | Skills Directory Structure | ? |
| 15 | Atomic Commits Skill | ? |
| 16 | Milhouse Skill | ? |
| 17 | Remove Test Directory | ? |
| 18 | Verify Cleanup | ? |

**Result: X/18 tests passed**

## Error Recovery

If tests fail partway through, clean up manually:

```bash
rm -rf /tmp/bluera-base-test
rm -rf .bluera/bluera-base/state/milhouse-loop.md
```
