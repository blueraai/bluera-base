# Objective Gates

Gates are commands that must pass AFTER the promise matches, before the loop exits.

## Usage

```bash
/bluera-base:milhouse-loop task.md --gate "npm test" --gate "npm run lint"
```

## Behavior

1. You output `<promise>TASK COMPLETE</promise>`
2. Each gate runs sequentially
3. If all pass → loop exits
4. If any fail → failure output is injected into the next iteration's prompt

This ensures code is actually correct, not just claimed to be complete.

## Multiple Gates

Gates run in order. All must pass:

```bash
/bluera-base:milhouse-loop task.md \
  --gate "npm test" \
  --gate "npm run lint" \
  --gate "npm run typecheck"
```

## Stuck Detection

If the same gate fails 3 times in a row (identical output), the loop auto-stops.

```bash
# Disable stuck detection
/bluera-base:milhouse-loop task.md --gate "npm test" --stuck-limit 0

# More lenient (5 identical failures)
/bluera-base:milhouse-loop task.md --gate "npm test" --stuck-limit 5
```

### How It Works

- A hash of each gate failure output is stored
- If 3 consecutive failures produce the same hash, loop stops
- This prevents infinite loops when truly stuck

## Gate Output

When a gate fails, the output is injected into the next iteration:

```text
--- GATE FAILED ---
Gate: npm test
Exit code: 1
Output:
FAIL src/auth.test.ts
  ✕ should validate JWT (5ms)
    Expected: 200
    Received: 401
---

Continue working on the milhouse task...
```
