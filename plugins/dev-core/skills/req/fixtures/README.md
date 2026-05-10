# Fixtures

Test data for the `/req` skill. Used by manual demo runs (V1/V2/V3/V4 RED-GATEs) and snapshot tests.

## Structure

```
fixtures/
├── issues/                         # GitHub issue payloads (gh issue view --json)
│   ├── 42-with-label.json          # area:booking, type:feature → clear domain
│   ├── 43-no-label.json            # type:chore only → fallback global scan
│   └── 44-multi-label.json         # area:auth + area:booking → multi-domain
├── reqs/                           # Pretend repo of REQ files
│   ├── REQ-BOOKING-001.mdx         # cancel-by-client (clear match for #42)
│   ├── REQ-BOOKING-002.mdx         # email confirmation (partial match)
│   ├── REQ-BOOKING-003.mdx         # cancel-by-coach (close match for #42)
│   ├── REQ-AUTH-001.mdx            # magic-link (close match for #44)
│   └── REQ-AUTH-002.mdx            # invitation token (close match for #44)
├── expected-menus.md               # Expected AskUserQuestion output per issue
├── v1-demo-results.md              # V1 RED-GATE results (T15)
├── v2-llm-scores.md                # V2 LLM scores per issue×REQ (T21)
├── v2-demo-results.md              # V2 RED-GATE results (T22)
├── v3-demo-results.md              # V3 RED-GATE results (T29)
├── v4-demo-results.md              # V4 RED-GATE results (T33)
├── menu-snapshots/                 # T38 — expected vs actual menu diff
├── idempotency-test.md             # T39 — re-run idempotency
├── no-label-test.md                # T40 — fallback path
├── disabled-test.md                # T41 — stack.yml disabled
└── final-integration.md            # T42 — full e2e
```

## Mapping to spec success criteria

| SC | Fixture |
|----|---------|
| SC-1 menu shape | expected-menus.md |
| SC-2 attach idempotent | idempotency-test.md |
| SC-3 create stub valid | v1-demo-results.md |
| SC-4 skip logged | v1-demo-results.md |
| SC-5 /dev triggers | v3-demo-results.md, final-integration.md |
| SC-6 Tier S skip | v3-demo-results.md |
| SC-7 stack.yml disabled | disabled-test.md |
| SC-8 LLM model config | v2-demo-results.md |
| SC-9 matrix reflects | final-integration.md |
| SC-10 README | n/a (doc check) |
| SC-11 fixtures/snapshot | this dir |
| SC-12 re-run keep-existing | idempotency-test.md |
