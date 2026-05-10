# Stack.yml-disabled test (T41)

Validates SC-7 (silent skip when `requirements.enabled ≠ true`).

## Test — Step 1 short-circuits

Walked Step 1 of req/SKILL.md against synthetic stack.yml :

### Case A — section absent

```yaml
schema_version: "1.0"
runtime: bun
# no requirements: section
```

Step 1 :
- `enabled` default = `false` (per Configuration table).
- `enabled ≠ true` → log debug, exit silently. No prompt. No REQ mutation. No frame mutation.

### Case B — `enabled: false` explicit

```yaml
requirements:
  enabled: false
  root: docs/requirements/
```

Step 1 :
- `enabled = false` → exit silently as in Case A.

### Case C — section present, `enabled` missing

```yaml
requirements:
  root: docs/requirements/
```

Step 1 :
- `enabled` default = `false` → exit silently as in Case A.

All three cases : silent no-op, no side effect.

Result: **PASS** — disabled config = silent skip in all 3 sub-cases.

## Summary

| Test | SC | Result |
|------|----|----|
| Disabled config silent | SC-7 | PASS |

**Disabled : 1/1 PASS** ✓
