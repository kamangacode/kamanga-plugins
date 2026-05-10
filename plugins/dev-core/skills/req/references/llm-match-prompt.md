# LLM matching prompt

Used by `req/SKILL.md` Step 6 (LLM match) to score REQ candidates against an issue.

Default model : `claude-haiku-4-5` (fast, cheap, sufficient for keyword + semantic matching).
Override : `stack.yml.requirements.matchModel`.

## Input format

```
ISSUE
=====
Title: {issue.title}
Body: {issue.body (truncated to first 1000 chars)}
Labels: {comma-separated labels}

CANDIDATES
==========
[
  {
    "id": "REQ-BOOKING-005",
    "title": "Annulation de réservation par le client",
    "domain": "booking",
    "ac_titles": ["Cancel before deadline", "Refund on cancel", "Notify coach"]
  },
  ...
]
```

## Output schema (strict JSON)

```json
[
  {
    "id": "REQ-BOOKING-005",
    "score": 0.92,
    "reason": "Issue mentions 'cancel booking' which matches REQ title and AC-1 directly."
  },
  {
    "id": "REQ-BOOKING-012",
    "score": 0.41,
    "reason": "Both touch booking domain but issue is about display, REQ is about confirmation flow."
  }
]
```

Score range : `0.0` (no match) to `1.0` (perfect match).

## Prompt template

```
You are matching a GitHub issue to existing functional requirements (REQs).

ISSUE
=====
Title: {issue.title}
Body: {issue.body}
Labels: {labels}

CANDIDATES
==========
{candidates_json}

TASK
====
For each candidate, output a JSON object with:
- `id`: the REQ id (verbatim)
- `score`: float in [0.0, 1.0] indicating semantic match strength
- `reason`: 1-2 sentence rationale citing specific overlap (or its absence)

Scoring guide:
- 0.9-1.0 : issue is directly about implementing this REQ
- 0.7-0.9 : issue is a sub-feature or extension of this REQ
- 0.4-0.7 : same domain but different concern
- 0.1-0.4 : tangential overlap (shared keyword, distinct scope)
- 0.0-0.1 : unrelated

Output ONLY a JSON array, no prose, no markdown fence.
```

## Few-shot examples

### Example 1 — Clear match

**Issue** :
- Title: "Coach can cancel a booking and refund the client"
- Body: "When a coach cancels a confirmed session, the system must refund the client and notify them by email."
- Labels: `area:booking`, `type:feature`

**Candidates** :
```json
[
  {
    "id": "REQ-BOOKING-005",
    "title": "Annulation de réservation par le client",
    "domain": "booking",
    "ac_titles": ["Cancel before 24h", "Refund flow", "Email notification"]
  },
  {
    "id": "REQ-BOOKING-012",
    "title": "Email de confirmation de réservation",
    "domain": "booking",
    "ac_titles": ["Send on creation", "Include calendar link"]
  }
]
```

**Expected output** :
```json
[
  { "id": "REQ-BOOKING-005", "score": 0.85, "reason": "Issue is about cancel-by-coach; REQ-005 covers cancel-by-client. Same flow (refund + notify) but different actor — likely sibling/extension." },
  { "id": "REQ-BOOKING-012", "score": 0.25, "reason": "Both touch email, but REQ-012 is creation-side, issue is cancellation-side." }
]
```

### Example 2 — Partial / borderline

**Issue** :
- Title: "Add tracking pixel to landing page"
- Body: "Marketing wants to track conversions from the landing page CTA."
- Labels: `area:leads`

**Candidates** :
```json
[
  { "id": "REQ-LEADS-003", "title": "Capture lead from form", "domain": "leads", "ac_titles": ["Form submission", "Email validation"] },
  { "id": "REQ-LEADS-008", "title": "Track lead source", "domain": "leads", "ac_titles": ["UTM capture", "Referrer logging"] }
]
```

**Expected output** :
```json
[
  { "id": "REQ-LEADS-003", "score": 0.15, "reason": "Form capture is unrelated to tracking pixel — different mechanism, different goal." },
  { "id": "REQ-LEADS-008", "score": 0.55, "reason": "Both about lead-source tracking; tracking pixel partially overlaps with UTM/referrer capture but is a distinct ad-tracking mechanism." }
]
```

### Example 3 — No match

**Issue** :
- Title: "Migrate from PostgreSQL 14 to 16"
- Body: "Bump major version, run migrations, validate query plans."
- Labels: `area:infra`, `type:chore`

**Candidates** :
```json
[
  { "id": "REQ-AUTH-001", "title": "Magic link login", "domain": "auth", "ac_titles": ["Send link", "Verify HMAC"] },
  { "id": "REQ-BOOKING-005", "title": "Annulation de réservation", "domain": "booking", "ac_titles": ["Cancel flow"] }
]
```

**Expected output** :
```json
[
  { "id": "REQ-AUTH-001", "score": 0.05, "reason": "Auth feature unrelated to DB version migration." },
  { "id": "REQ-BOOKING-005", "score": 0.05, "reason": "Booking feature unrelated to DB infra work." }
]
```

This issue is a chore — `req` step should propose `[Skip with reason: 'PostgreSQL infra migration, no functional REQ']`.

## Notes

- **Truncation** : issue body capped to 1000 chars to keep prompt cheap. Most REQs are matchable from title alone.
- **AC titles only** : full AC descriptions add noise without proportional gain at scoring level.
- **Determinism** : `temperature: 0` for reproducibility. Cache prompt+input → score map per session if repeated.
- **Cost** : ~500-1500 input tokens per call, ~200-400 output. Haiku 4.5 ≈ $0.001-0.003 per /req invocation.
