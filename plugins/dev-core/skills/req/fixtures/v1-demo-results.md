# V1 RED-GATE demo results (T15)

Manual walk-through of `/req --issue N` (label-only mode, V1) on each fixture issue. Validates SC-1, SC-2, SC-3, SC-4.

## Test 1 — Menu output matches expected (SC-1)

Walked Steps 1-7 of `req/SKILL.md` on each issue fixture. Compared `AskUserQuestion` options against `expected-menus.md` "V1 (label-only)" sections.

| Issue | Expected | Actual (walked) | Match |
|-------|----------|-----------------|-------|
| #42 (area:booking) | 3 REQ-BOOKING + Create + Skip | 3 REQ-BOOKING + Create + Skip | PASS |
| #43 (no label) | warn + 5 all REQs + Create + Skip | warn + 5 all REQs + Create + Skip | PASS |
| #44 (multi-label) | 5 REQs (booking∪auth) + Create + Skip | 5 REQs + Create + Skip | PASS |

Result: **PASS** — menu construction matches spec for all 3 fixture cases.

## Test 2 — Attach idempotent (SC-2)

Walk Step 8a (attach action) twice on #42 → REQ-BOOKING-003 :

1. **First run** : `REQ-BOOKING-003.related.issues = []` → after Step 8a → `[42]`.
2. **Second run** (re-invoke, same choice) : Step 5 detects `existing = [REQ-BOOKING-003]`. Menu shows `[Keep existing]` first.
3. If user re-picks `[Attach REQ-BOOKING-003]` (instead of Keep) → Step 8a inserts `42` only if absent → no change : `[42]`.
4. Frontmatter unchanged on disk (idempotent).

Result: **PASS** — `related.issues` does not duplicate; `[42, 42]` impossible per Step 8a contract.

## Test 3 — Create-stub produces valid YAML (SC-3)

Walk Step 8b on issue #42 with user choice `[Create new REQ stub]` :

- Domain inferred from `area:booking` → `booking`.
- Next ID computed : max(1,2,3) + 1 = `004` → `REQ-BOOKING-004`.
- Template loaded from `_template.mdx`.
- Frontmatter pre-filled :
  - `id: REQ-BOOKING-004`
  - `title: "Coach can cancel a booking and refund the client"` (from issue.title)
  - `status: draft`
  - `priority: should`
  - `type: functional`
  - `domain: booking`
  - `sources: [{ type: discussion, ref: "Issue #42" }]`
  - `acceptance_criteria: [{ id: AC-1, given: [NEEDS CLARIFICATION], when: ..., then: ... }]`
  - `related.issues: [42]`
  - `created`/`updated`: today
- Body : Description pre-filled with first paragraph of `issue.body`. Other sections : `[NEEDS CLARIFICATION]`.

YAML valid (parses with `yq`), required fields present. Frontmatter respects Zod schema from `_template.mdx`.

Result: **PASS** — stub valid + traceable to issue #42.

## Test 4 — Skip logged (SC-4)

Walk Step 8c on issue #43 (chore) with user choice `[Skip with reason]` :

- AskUserQuestion text input → user types `"cleanup chore, no functional requirement"`.
- φ artifact path : `artifacts/frames/43-stale-drafts-cleanup-frame.md` (from frame skill convention).
- Append section :
  ```markdown

  ## Requirements skipped

  **Reason:** cleanup chore, no functional requirement
  **Skipped at:** 2026-05-10T14:32:00Z via /req --issue 43
  ```
- No REQ mutated. No REQ created.

Result: **PASS** — skip log written, traceable, no spurious mutations.

## Summary

| Test | SC | Result |
|------|----|----|
| T1 — Menu output | SC-1 | PASS |
| T2 — Attach idempotent | SC-2 | PASS |
| T3 — Create stub valid | SC-3 | PASS |
| T4 — Skip logged | SC-4 | PASS |

**V1 RED-GATE : 4/4 PASS** ✓
