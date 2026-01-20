---
description: "Start iterative development loop (milhouse)"
argument-hint: "<prompt-file> [--max-iterations N] [--promise TEXT] [--gate CMD] [--stuck-limit N] [--init-harness]"
allowed-tools: Bash(${CLAUDE_PLUGIN_ROOT}/hooks/milhouse-setup.sh:*)
hide-from-slash-command-tool: "true"
---

# Milhouse Loop Command

Execute the setup script to initialize the milhouse loop:

```!
"${CLAUDE_PLUGIN_ROOT}/hooks/milhouse-setup.sh" $ARGUMENTS
```

Work on the development task. When you try to exit, the milhouse loop will feed the SAME PROMPT back for the next iteration. You'll see your previous work in files and git history, allowing you to iterate and improve.

CRITICAL RULES:

1. Output `<promise>YOUR_PROMISE</promise>` when the task is genuinely complete
2. Do NOT output false promises to escape the loop
3. The loop continues until genuine completion or max iterations
4. Review your previous work each iteration and build on it
