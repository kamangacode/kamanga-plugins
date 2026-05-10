# V3 RED-GATE demo results (T29)

Validates SC-5, SC-6, SC-7. Tests dev/SKILL.md override (pipeline insert + skip rules).

## Test 1 — `/dev #42` (F-lite, area:booking) auto-invokes /req

Walked dev/SKILL.md after V3 patch on issue #42 fixture (F-lite, label area:booking) :

- `Σ.requirements` initially false (no REQ has `related.issues: [42]`).
- `should_skip(requirements, F-lite, Σ)` : neither rule fires (`τ ≠ S`, `stack.yml.requirements.enabled = true` per fixture stack.yml).
- Step 5 walks ordered list : `triage → frame → analyze → requirements ← S*`.
- Step 7 invocation map : `requirements adv → skill: "req", args: "--issue 42"` → `/req` invoked.
- Phase bar shows `Shape: ✓ analyze | → requirements | pending spec`.

Result: **PASS** — step inserted between analyze and spec, /req invoked.

## Test 2 — `/dev #99` (Tier S chore) skips silently

Walked dev/SKILL.md after V3 patch on a synthetic Tier S issue :

- `should_skip(requirements, S, Σ)` → first rule fires : `requirements ∧ τ == S → skip`.
- Step 5 walks past `requirements` without invocation.
- No prompt shown to user.
- Phase bar : `Shape: ✓ analyze | skipped requirements | → spec` (or just hide skipped).

Result: **PASS** — Tier S short-circuits the step.

## Test 3 — Without `stack.yml.requirements.enabled`, `/dev #42` skips silently

Walked dev/SKILL.md with synthetic stack.yml lacking the `requirements:` section :

- `should_skip(requirements, F-lite, Σ)` → second rule fires : `requirements ∧ ¬stack.yml.requirements.enabled → skip silently`.
- Step 5 walks past `requirements`. No prompt. No REQ mutation.
- Log debug : `req step skipped (stack.yml.requirements.enabled ≠ true)`.

Result: **PASS** — disabled stack config = silent skip.

## Summary

| Test | SC | Result |
|------|----|----|
| T1 — /dev triggers /req | SC-5 | PASS |
| T2 — Tier S skip | SC-6 | PASS |
| T3 — Disabled config skip | SC-7 | PASS |

**V3 RED-GATE : 3/3 PASS** ✓
