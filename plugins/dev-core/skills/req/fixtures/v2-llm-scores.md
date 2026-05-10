# V2 LLM scores capture (T21)

Manual application of the prompt template (`references/llm-match-prompt.md`) against each fixture issue. Scores derived from the few-shot calibration in the prompt template (matches the rubric: 0.9-1.0 direct, 0.7-0.9 sibling, 0.4-0.7 same domain, 0.1-0.4 tangential, 0.0-0.1 unrelated).

Note: actual LLM call would produce slightly different scores per run (claude-haiku-4-5 with `temperature: 0` for stability). These are the expected values used to validate cutoff logic.

## Issue #42 — Coach cancels booking + refund

| Candidate | score: | Reason |
|-----------|--------|--------|
| REQ-BOOKING-003 | score: 0.92 | Direct match — REQ literally is "Annulation par le coach", same actor + flow as issue. |
| REQ-BOOKING-001 | score: 0.85 | Sibling — cancel-by-client, same refund + email logic, different actor. |
| REQ-BOOKING-002 | score: 0.30 | Touches email confirmation but creation-side, distinct from cancel concern. |
| REQ-AUTH-001 | score: 0.05 | Unrelated. |
| REQ-AUTH-002 | score: 0.05 | Unrelated. |

Cutoffs : 2 high (`≥0.8`), 1 low (`0.3 ≤ s < 0.8`), 2 hidden (`<0.3`).

## Issue #43 — Daily cleanup chore

| Candidate | score: | Reason |
|-----------|--------|--------|
| REQ-BOOKING-002 | score: 0.20 | Both touch email/lifecycle but unrelated scope. |
| REQ-BOOKING-001 | score: 0.10 | Cancel feature unrelated to cleanup chore. |
| REQ-BOOKING-003 | score: 0.10 | Cancel feature unrelated. |
| REQ-AUTH-001 | score: 0.10 | Auth unrelated. |
| REQ-AUTH-002 | score: 0.05 | Auth unrelated. |

Cutoffs : 0 high, 0 low, 5 hidden. Fallback fires : top-2 displayed with `weak match`.

## Issue #44 — Magic-link + booking pre-fill

| Candidate | score: | Reason |
|-----------|--------|--------|
| REQ-AUTH-002 | score: 0.88 | Direct match — invitation token + context pre-fill is the literal feature. |
| REQ-AUTH-001 | score: 0.55 | Underlying mechanism (magic-link), parent dependency. Issue extends it. |
| REQ-BOOKING-002 | score: 0.20 | Touches booking creation but trigger is different (invitation, not user form). |
| REQ-BOOKING-001 | score: 0.10 | Cancel ≠ create. |
| REQ-BOOKING-003 | score: 0.10 | Cancel ≠ create. |

Cutoffs : 1 high, 1 low, 3 hidden.

## Total scores : 15 (3 issues × 5 candidates) ✓
