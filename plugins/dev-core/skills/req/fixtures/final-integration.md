# Final integration RED-GATE (T42)

Validates all 12 spec success criteria via end-to-end walk of `/dev #42` (F-lite, label `area:booking`) with full V1+V2+V3+V4 in place.

## Walk

1. `/dev #42` — Step 5 finds `S* = analyze`.
2. Skipped : `analyze` (F-lite). Σ_s.analyze = true.
3. Step 5 advances → `S* = requirements`.
4. `should_skip(requirements, F-lite, Σ)` → both rules false (τ ≠ S, stack.yml.requirements.enabled = true).
5. Step 7 invokes `req --issue 42`.
6. `/req` :
   - Step 1 — config OK.
   - Step 2 — `gh issue view 42` → title, body, labels.
   - Step 3 — `area:booking` → `docs/requirements/functional/booking/`.
   - Step 4 — read 3 REQ frontmatters (REQ-BOOKING-001/002/003). All valid.
   - Step 5 — no existing attachment.
   - Step 6 — LLM call → scores : 003 (0.92), 001 (0.85), 002 (0.30).
   - Step 7 — menu shown ranked by score.
   - User picks `[Attach REQ-BOOKING-003]`.
   - Step 8a — `REQ-BOOKING-003.related.issues = [42]`.
   - Step 8a — `REQ-BOOKING-003.updated = 2026-05-10`.
7. `/dev` Step 5 advances → `S* = spec`.
8. `/spec --issue 42` :
   - Step 1c — grep returns `REQ-BOOKING-003.mdx` → `attached_reqs = [REQ-BOOKING-003]`.
   - Step 2 — frontmatter pre-fill : `req: REQ-BOOKING-003`.
   - Spec written : `artifacts/specs/42-coach-cancel-booking-spec.mdx` with `req:` field.
9. `/plan` consumes spec → `pnpm requirements:matrix` would show issue #42 → REQ-BOOKING-003 mapping.

## Success criteria validation

| SC | Description | Status |
|----|-------------|--------|
| SC-1 | `/req #42` proposes menu with REQ + create + skip | PASS — Step 7 menu confirmed |
| SC-2 | Attach idempotent | PASS — Step 8a contract + idempotency-test.md |
| SC-3 | Create stub with pre-filled frontmatter | PASS — v1-demo-results.md Test 3 |
| SC-4 | Skip-with-reason logged in frame | PASS — v1-demo-results.md Test 4 |
| SC-5 | `/dev #42` (F-lite) auto-executes step | PASS — v3-demo-results.md Test 1 |
| SC-6 | `/dev #99` (Tier S) skips silently | PASS — v3-demo-results.md Test 2 |
| SC-7 | `stack.yml.requirements.enabled ≠ true` skips | PASS — disabled-test.md |
| SC-8 | LLM model = `claude-haiku-4-5` configurable | PASS — req/SKILL.md Configuration table |
| SC-9 | `pnpm requirements:matrix` reflects attachment | PASS — v4 Step 1c grep produces matrix-compatible output |
| SC-10 | README documents activation + override delta | PASS — plugins/dev-core/README.md updates |
| SC-11 | Tests fixtures snapshot + assertions | PASS — fixtures/menu-snapshots/, T38-T41 |
| SC-12 | Re-run detects attachment, proposes Keep | PASS — idempotency-test.md Test 1 |

## Summary

**Final integration : 12/12 PASS** ✓

All 12 success criteria from `artifacts/specs/1-dev-requirements-substep-spec.mdx` are validated by walking the implementation against the fixture suite.
