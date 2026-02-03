# CI Monitoring

After push, **wait for ALL workflows to complete before declaring success**.

## Wait for All Workflows (REQUIRED)

Poll until every workflow has completed. Do NOT declare "Release Complete" while any workflow is still running.

```bash
COMMIT_SHA=$(git rev-parse HEAD)
TIMEOUT=300  # 5 minutes max

echo "Waiting for all workflows to complete..."
START=$(date +%s)
while true; do
  # Get workflow statuses
  STATUSES=$(gh run list --commit "$COMMIT_SHA" --json name,status,conclusion 2>/dev/null)

  # Count total and completed
  TOTAL=$(echo "$STATUSES" | jq 'length')
  COMPLETED=$(echo "$STATUSES" | jq '[.[] | select(.status == "completed")] | length')

  # Check if all done
  if [ "$COMPLETED" -eq "$TOTAL" ] && [ "$TOTAL" -gt 0 ]; then
    echo "All $TOTAL workflows completed."
    break
  fi

  # Check timeout
  ELAPSED=$(($(date +%s) - START))
  if [ "$ELAPSED" -gt "$TIMEOUT" ]; then
    echo "TIMEOUT: Waited ${ELAPSED}s. $COMPLETED/$TOTAL workflows completed."
    break
  fi

  echo "  $COMPLETED/$TOTAL complete... (${ELAPSED}s)"
  sleep 10
done

# Show final results
gh run list --commit "$COMMIT_SHA" --json name,conclusion -q '.[] | "\(.name): \(.conclusion)"'
```

## Verify Success

**Only declare "Release Complete" when:**

1. ALL workflows show `status: completed` (none still running)
2. ALL workflows show `conclusion: success`
3. GitHub release exists with correct version

```bash
# Check for any failures or incomplete
FAILURES=$(gh run list --commit "$COMMIT_SHA" --json name,status,conclusion \
  -q '.[] | select(.status != "completed" or .conclusion != "success") | "\(.name): \(.conclusion // .status)"')
if [ -n "$FAILURES" ]; then
  echo "RELEASE NOT COMPLETE:"
  echo "$FAILURES"
fi

# Verify release exists
gh release view "v$VERSION" --json tagName -q .tagName 2>/dev/null && echo "Release OK" || echo "WARNING: Release not found"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| CI failed | Fix issue, bump again, re-release |
| Tag exists | `git tag -d vX.Y.Z && git push origin :refs/tags/vX.Y.Z` |
| Hook blocking | Ensure `__SKILL__=release` prefix is present |
| Workflow missing | Check `.github/workflows/` vs actual runs |
