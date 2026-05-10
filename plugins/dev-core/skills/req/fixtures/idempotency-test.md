# Idempotency test (T39)

Validates SC-2 + SC-12. Re-run `/req --issue 42` twice, verify no duplicate, verify Keep-existing offered.

## Run 1 — initial attach

State before :
- `REQ-BOOKING-003.related.issues = []`

Walk Steps 1-8 of req/SKILL.md, user picks `[Attach REQ-BOOKING-003]`.

State after :
- `REQ-BOOKING-003.related.issues = [42]`

## Run 2 — re-invocation

State before : same as Run 1 result.

Walk Steps 1-8 again :

- **Step 5** detects `existing = [REQ-BOOKING-003]`. Cached.
- **Step 7** menu : first option = `[Keep existing attachment(s): REQ-BOOKING-003]` (recommended).

Test 1 : User picks `[Keep existing]` → Step 8 short-circuits to no-op. State unchanged.

Result: **PASS** — Keep-existing offered, no-op when chosen.

Test 2 : User picks `[Attach REQ-BOOKING-003]` again (against recommendation) → Step 8a runs but idempotent insertion skips duplicate. State unchanged: `[42]` (not `[42, 42]`).

Result: **PASS** — `related.issues` does not duplicate.

## Summary

| Test | SC | Result |
|------|----|----|
| Keep-existing offered | SC-12 | PASS |
| Attach idempotent | SC-2 | PASS |

**Idempotency : 2/2 PASS** ✓
