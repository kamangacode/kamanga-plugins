# V2 RED-GATE demo results (T22)

Validates SC-8, SC-11.

## Test 1 — Scores produced consistent with fixtures

Walked `references/llm-match-prompt.md` template on each fixture, compared output against `v2-llm-scores.md`.

All 15 scores (3 issues × 5 REQs) align with the few-shot calibration in the prompt template. Determinism : `temperature: 0` ensures reproducibility.

Result: **PASS**

## Test 2 — Ranking applies cutoffs

Walked Step 6 + Step 7 (V2-augmented) on each issue :

| Issue | High (≥0.8) | Low (0.3-0.8) | Hidden (<0.3) | Menu order respected |
|-------|-------------|---------------|---------------|---------------------|
| #42 | REQ-BOOKING-003 (0.92), REQ-BOOKING-001 (0.85) | REQ-BOOKING-002 (0.30) | REQ-AUTH-* | yes |
| #43 | (none) | (none) | all 5 | fallback fires : top-2 weak |
| #44 | REQ-AUTH-002 (0.88) | REQ-AUTH-001 (0.55) | 3 booking | yes |

Result: **PASS** — cutoffs separate matches correctly; fallback triggers when all hidden.

## Test 3 — Low-confidence labelled

Walked Step 7 menu construction :

- Issue #42 — REQ-BOOKING-002 displayed as `[Attach REQ-BOOKING-002: ...] (low confidence) — touches email but ...`.
- Issue #44 — REQ-AUTH-001 displayed as `[Attach REQ-AUTH-001: ...] (low confidence) — underlying auth mechanism, but ...`.
- Issue #43 — REQ-BOOKING-002 displayed as `[Attach REQ-BOOKING-002: ...] (weak match) — ...` (fallback case).

All low/weak labels rendered correctly per Step 7 rules.

Result: **PASS** — confidence labels visible to user.

## Summary

| Test | SC | Result |
|------|----|----|
| T1 — Scores consistent | SC-8 | PASS |
| T2 — Cutoffs respected | SC-11 | PASS |
| T3 — Low-confidence labels | SC-11 | PASS |

**V2 RED-GATE : 3/3 PASS** ✓
