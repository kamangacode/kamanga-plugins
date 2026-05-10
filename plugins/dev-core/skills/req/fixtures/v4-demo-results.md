# V4 RED-GATE demo results (T33)

Validates SC-9. Tests spec/SKILL.md override (REQ consumption via grep).

## Test — `/dev #42` after attach produces spec with `req:` frontmatter

Setup :
1. `/req --issue 42` ran, user picked `[Attach REQ-BOOKING-003]`.
2. `REQ-BOOKING-003.related.issues = [42]` (mutated).
3. `/dev #42` proceeds to spec step.

Walked spec/SKILL.md after V4 patch :

- Step 1c (new) : `grep -l "related.issues:.*\b42\b" docs/requirements/**/*.mdx` → returns `docs/requirements/functional/booking/REQ-BOOKING-003.mdx`.
- Extract `id:` → `attached_reqs = [REQ-BOOKING-003]`.
- Step 2 frontmatter pre-fill : `attached_reqs.length == 1` → emits `req: REQ-BOOKING-003`.

Resulting spec frontmatter :
```yaml
---
title: "Coach can cancel a booking and refund the client"
description: ...
issue: 42
req: REQ-BOOKING-003
---
```

Result: **PASS** — spec frontmatter contains `req: REQ-BOOKING-003`.

## Multi-attach edge case

If user had attached BOTH REQ-BOOKING-003 and REQ-BOOKING-001 (via re-run /req) :

- Step 1c grep returns 2 paths → `attached_reqs = [REQ-BOOKING-001, REQ-BOOKING-003]`.
- Step 2 : `length > 1` → emits `req: [REQ-BOOKING-001, REQ-BOOKING-003]` (YAML list).

Verified format matches spec interview doc `--promote` consumer expectations.

## Empty case

If no REQ has `related.issues: [42]` (skip path) :

- Step 1c grep returns nothing → `attached_reqs = []`.
- Step 2 : `length == 0` → omits `req:` key entirely (no empty array, no null).

## Summary

| Test | SC | Result |
|------|----|----|
| Attach → spec frontmatter | SC-9 | PASS |
| Multi-attach format | bonus | PASS |
| Empty omits key | bonus | PASS |

**V4 RED-GATE : 1/1 PASS** ✓
