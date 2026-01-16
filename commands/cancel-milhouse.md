---
description: "Cancel active milhouse loop"
allowed-tools: ["Bash(test -f .bluera/bluera-base/state/milhouse-loop.md:*)", "Bash(rm .bluera/bluera-base/state/milhouse-loop.md)", "Read(.bluera/bluera-base/state/milhouse-loop.md)"]
hide-from-slash-command-tool: "true"
---

# Cancel Milhouse

To cancel the milhouse loop:

1. Check if `.bluera/bluera-base/state/milhouse-loop.md` exists using Bash: `test -f .bluera/bluera-base/state/milhouse-loop.md && echo "EXISTS" || echo "NOT_FOUND"`

2. **If NOT_FOUND**: Say "No active milhouse loop found."

3. **If EXISTS**:
   - Read `.bluera/bluera-base/state/milhouse-loop.md` to get the current iteration number from the `iteration:` field
   - Remove the file using Bash: `rm .bluera/bluera-base/state/milhouse-loop.md`
   - Report: "Cancelled milhouse loop (was at iteration N)" where N is the iteration value
