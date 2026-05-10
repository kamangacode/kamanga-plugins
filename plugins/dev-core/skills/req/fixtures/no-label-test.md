# No-label fallback test (T40)

Validates Step 3 fallback path (no `area:*` label → global scan + warn).

## Test 1 — Warning emitted

Walked Step 3 on issue #43 (labels: `type:chore`, `size:S` only) :

- `L = filter(labels, prefix='area:') = []`
- Branch `L = ∅` taken : warn user "No `area:*` label — scanning all functional REQs".
- Scope : `{R}/functional/**/*.mdx` (all REQs).

Expected warning text appears in user-visible output (stdout or AskUserQuestion preamble).

Result: **PASS** — warning emitted.

## Test 2 — Global scope used

Walked Step 4 with global scope :

- All 5 fixture REQs read (REQ-BOOKING-001/002/003 + REQ-AUTH-001/002).
- All passed Zod validation (frontmatters complete).
- `candidates.length = 5`.

Result: **PASS** — global fallback returns all REQs.

## Summary

| Test | Coverage | Result |
|------|----------|----|
| Warning emitted | edge case "no area:*" | PASS |
| Global scope used | edge case "no area:*" | PASS |

**No-label fallback : 2/2 PASS** ✓
