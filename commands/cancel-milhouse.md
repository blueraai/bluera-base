---
description: "Cancel active milhouse loop"
allowed-tools: ["Bash(test -f .claude/milhouse-loop.local.md:*)", "Bash(rm .claude/milhouse-loop.local.md)", "Read(.claude/milhouse-loop.local.md)"]
hide-from-slash-command-tool: "true"
---

# Cancel Milhouse

To cancel the milhouse loop:

1. Check if `.claude/milhouse-loop.local.md` exists using Bash: `test -f .claude/milhouse-loop.local.md && echo "EXISTS" || echo "NOT_FOUND"`

2. **If NOT_FOUND**: Say "No active milhouse loop found."

3. **If EXISTS**:
   - Read `.claude/milhouse-loop.local.md` to get the current iteration number from the `iteration:` field
   - Remove the file using Bash: `rm .claude/milhouse-loop.local.md`
   - Report: "Cancelled milhouse loop (was at iteration N)" where N is the iteration value
