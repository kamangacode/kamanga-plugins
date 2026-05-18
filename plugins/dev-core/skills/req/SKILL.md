---
name: req
argument-hint: '--issue <N>'
description: Identify or create a REQ for an issue (attach/create-stub/skip). Triggers: "/req" | "requirements step" | "attach REQ" | "find REQ for issue" | "create requirement".
version: 0.1.0
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, ToolSearch
---

# Req

## Success

I := REQ-X.mdx mutated ∨ stub created ∨ skip logged in φ
V := (attach) `grep -l "related.issues:.*\bN\b" {root}/**/*.mdx` ∋ ≥1 file ∨ (create) `test -f {root}/{kind}/{domain}/REQ-{DOM}-{NNN}.mdx` ∨ (skip) `grep "Requirements skipped" artifacts/frames/{N}-*.mdx`

Let:
  N := issue number
  R := docs/requirements/ (∨ `stack.yml.requirements.root`)
  τ := tier (S → skip)
  φ := artifacts/frames/{N}-{slug}-frame.mdx
  AQ := Present decision via protocol: read `${CLAUDE_PLUGIN_ROOT}/../shared/references/decision-presentation.md`

issue → REQ identified ∨ created ∨ skip-justified. Idempotent re-run.
Standalone-safe: callable without `/dev`. Invoked by `/dev` between `analyze` and `spec`.

## Entry

```
/req --issue N      → run on issue N
```

> **Callable outside `/dev`.** `/req --issue N` can be invoked directly when `/dev` blocks at the `requirements` step. The BLOCK message produced by `/dev` recommends this exact command.

## Pipeline

| Step | ID | Required | Verifies via | Notes |
|------|----|----------|---------------|-------|
| 1 | config | ✓ | stack.yml read | skip silent if disabled |
| 2 | issue | ✓ | gh JSON ok | — |
| 3 | scope | ✓ | dirs identified | label-based |
| 4 | frontmatters | ✓ | REQ list ∃ | invalid skipped+warn |
| 5 | existing | ✓ | grep result | re-run idempotent |
| 6 | match | — | LLM scores | V2; skip if no candidates |
| 7 | menu | ✓ | AskUserQuestion shown | — |
| 8 | action | ✓ | mutate/create/log | per choice |

## Pre-flight

Success: action persisted (REQ mutated ∨ stub written ∨ skip logged)
Evidence: V above
¬clear → STOP + ask: "Which issue # are we processing?"

## Step 1 — Read stack config

Read `.claude/stack.yml` — extract `requirements` section :

```yaml
requirements:
  enabled: true
  root: docs/requirements/
  validateCmd: pnpm requirements:validate
  matchModel: claude-haiku-4-5
```

Defaults if key missing :
- `enabled` → `false` (skip silently if section absent or `enabled` ≠ `true`)
- `root` → `docs/requirements/`
- `validateCmd` → ∅ (no validation post-mutation)
- `matchModel` → `claude-haiku-4-5`

`enabled` ≠ `true` ⇒ log `debug: req step skipped (stack.yml.requirements.enabled ≠ true)` → exit silently. ¬error.

## Step 2 — Read issue

```bash
gh issue view N --json number,title,body,labels
```

Cache : `issue.title`, `issue.body`, `issue.labels[]` (extract `area:*` matches).

## Step 3 — Scope domain dirs

Let L := `issue.labels` filtered to `area:*` prefix.

| Case | Scope |
|------|-------|
| L = ∅ | Scan global : `{R}/functional/**/*.mdx` (warn user: "No `area:*` label — scanning all functional REQs") |
| L = {`area:X`} | `{R}/functional/X/*.mdx` |
| L = {`area:X`, `area:Y`, …} | Union: `{R}/functional/X/*.mdx` ∪ `{R}/functional/Y/*.mdx` |

NFR (`{R}/non-functional/`) ¬scanné par défaut (action secondaire v2). Exception : si l'issue mentionne `PII|GDPR|RGPD|latency|perf|sécu|security` → ajouter scope NFR + flag user.

## Step 4 — Read REQ frontmatters

Glob les chemins de Step 3, parse YAML frontmatter de chaque `.mdx`. Champs requis (per `_template.mdx`) :
- `id` — `REQ-{DOMAIN}-{NNN}`
- `title`
- `domain`
- `status`
- `type` ∈ {functional, non-functional}
- `acceptance_criteria` (≥1)
- `related.issues[]`

Frontmatter invalide (champ requis manquant ∨ format ID incorrect) ⇒ skip + warn `WARN: invalid frontmatter in {path}, skipped`. ¬crash.

Cache : `candidates := [{ path, id, title, domain, status, ac_count, related_issues }]`.

## Step 5 — Detect existing attachment

```bash
grep -l "related.issues:.*\b${N}\b" ${R}/**/*.mdx 2>/dev/null
```

`existing := paths matching`. Cache `existing_ids := [id from frontmatter of those paths]`.

`existing ≠ ∅` ⇒ ajouter en première option du menu (Step 7) : `[Keep existing attachment(s): REQ-X, REQ-Y]`.

## Step 6 — LLM match

> Lit le prompt depuis `${CLAUDE_SKILL_DIR}/references/llm-match-prompt.md`.

Invoke model `stack.yml.requirements.matchModel` (default `claude-haiku-4-5`) avec :
- Input : issue.title + issue.body + compact frontmatters (id + title + AC titles only)
- Output schema : JSON `[{id, score: 0..1, reason}]`

### Scoring cutoffs

| Score | Label | Action |
|-------|-------|--------|
| ≥ 0.8 | `match` (high confidence) | présenté en premier dans menu |
| 0.3 ≤ s &lt; 0.8 | `low confidence` | présenté avec étiquette explicite |
| &lt; 0.3 | (hidden) | non présenté |

**Fallback** : si tous scores &lt; 0.3 ⇒ présenter quand même top-2 avec étiquette `weak match` + option `[Create new REQ stub]` proéminente.

`candidates.length == 0` ⇒ skip Step 6, aller direct Step 7 sans matches LLM.

## Step 7 — Build menu

Construit options `AskUserQuestion` :

1. (si `existing ≠ ∅`) `[Keep existing attachment(s): REQ-X, REQ-Y]` — recommandé
2. ∀ candidate avec `score ≥ 0.8` : `[Attach REQ-X: {title}]` (description: `(match) — {reason}`)
3. ∀ candidate avec `0.3 ≤ score < 0.8` : `[Attach REQ-X: {title}]` (description: `(low confidence) — {reason}`)
4. `[Create new REQ stub]` (description: `New REQ in {domain} from issue title+frame`)
5. `[Skip with reason]` (description: `Logged in frame artifact, non-blocking`)

`multiSelect: false` (v1 : un seul choix). Multi-attach via re-run `/req --issue N` (le second run propose d'ajouter un REQ supplémentaire).

→ → DP(A) → user response → branche Step 8.

## Step 8 — Execute action

### Step 8a — Attach to existing REQ

User a choisi `[Attach REQ-X]` ∨ `[Keep existing]`.

```
target := docs/requirements/{kind}/{domain}/REQ-X.mdx
```

Read `target`, parse frontmatter. Mute `related.issues` :

```yaml
related:
  issues: [N, ...]   # ajout idempotent : N inséré seulement si absent
```

Préserver l'ordre des autres clés frontmatter. Préserver le body markdown intact. Re-écrire le fichier.

`updated` field frontmatter ⇒ set à date du jour (`YYYY-MM-DD`).

✓ → log `INFO: attached issue ${N} → ${id}`.

### Step 8b — Create new REQ stub

User a choisi `[Create new REQ stub]`.

1. Determine domain :
   - `area:X` label présent ⇒ domain := X
   - sinon → → DP(A) lister les domaines existants (lecture des dossiers `{R}/functional/`) → user pick. Default: créer `{R}/functional/uncategorized/`.
2. Determine `next` numéro : `max(NNN ∈ {R}/functional/{domain}/REQ-{DOMAIN}-NNN.mdx) + 1`. Format 3 chiffres.
3. Lire `{R}/_template.mdx` (∨ équivalent local).
4. Pré-remplir frontmatter :
   ```yaml
   id: REQ-{DOMAIN_UPPER}-{NNN}
   title: "{issue.title}"
   status: draft
   priority: should
   type: functional
   domain: {domain}
   sources:
     - type: discussion
       ref: "Issue #{N}"
   acceptance_criteria:
     - id: AC-1
       given: "[NEEDS CLARIFICATION]"
       when: "[NEEDS CLARIFICATION]"
       then: "[NEEDS CLARIFICATION]"
   related:
     issues: [{N}]
     specs: []
     adrs: []
     prs: []
     blocks: []
     blocked_by: []
   owner: {git config user.name}
   created: {today YYYY-MM-DD}
   updated: {today YYYY-MM-DD}
   ```
5. Body : reprend les sections du template. **Description** est pré-remplie avec `issue.body` (premier paragraphe). Autres sections : `[NEEDS CLARIFICATION]`.
6. Write `{R}/functional/{domain}/REQ-{DOMAIN_UPPER}-{NNN}.mdx`.

✓ → log `INFO: created stub REQ-{DOMAIN_UPPER}-{NNN}` + AskUserQuestion : "Edit ACs maintenant ?" → [Open in editor] | [Plus tard].

### Step 8c — Skip with reason

User a choisi `[Skip with reason]`.

→ → DP(A) text input "Reason for skip (e.g. 'pure refactor', 'docs only', 'experiment')" → capture `reason`.

Write `.claude/req-skipped/{N}.md` with body:

```
issue: {N}
reason: {free-text reason supplied by user}
by: /req standalone
at: {ISO 8601 timestamp}
```

This marker is recognized by `/dev` Σ.requirements and unblocks the gate without a REQ. Use it when the issue genuinely has no requirements coverage need (infra cleanup, doc-only changes, etc.).

**Body schema is advisory only.** The gate (`scan-state.sh`) checks file existence — the fields above (`issue`, `reason`, `by`, `at`) are a human-readable audit trail, not a stable parse contract. Future tooling that wants to consume the body should define its own schema rather than depending on this format.

Append à `φ` (frame artifact) :

```markdown

## Requirements skipped

**Reason:** {reason}
**Skipped at:** {ISO timestamp} via /req --issue {N}
```

¬REQ muté. ¬REQ créé. Loggé pour traceability — visible dans `pnpm requirements:matrix` côté projet hôte.

✓ → log `INFO: req skipped for issue ${N}: ${reason}`.

## Configuration

Toutes les clés sous `.claude/stack.yml` → `requirements:`.

| Key | Default | Purpose |
|-----|---------|---------|
| `enabled` | `false` | Active le step. Skip silencieux si `false` ∨ absent. |
| `root` | `docs/requirements/` | Racine du référentiel REQ. |
| `validateCmd` | ∅ | Commande de validation post-mutation (ex. `pnpm requirements:validate`). |
| `matchModel` | `claude-haiku-4-5` | Modèle LLM pour matching Step 6. |

Exemple minimal (`.claude/stack.yml`) :

```yaml
requirements:
  enabled: true
  root: docs/requirements/
  validateCmd: pnpm requirements:validate
  matchModel: claude-haiku-4-5
```

## Edge cases

| Cas | Comportement |
|-----|--------------|
| `stack.yml` absent ∨ section `requirements` absente | Skip silencieux (log debug). |
| Tier S (chore) — invocation par `/dev` | `/dev` skip rule s'applique avant invocation. Standalone : exécute quand même. |
| Aucun `area:*` label | Fallback global scan + warn. |
| Aucun match (tous scores &lt; 0.3) | Top-2 affiché avec `weak match` + `[Create]` proéminent. |
| Plusieurs matches haute confiance | Présentés ranked par score. User pick un. Multi-attach via re-run. |
| REQ frontmatter Zod invalide | Skip ce REQ + warn, ¬crash. |
| User cancel via Esc | Pas de mutation. Pipeline `/dev` s'arrête (caller décide). |
| Re-run `/req --issue N` après attach | Step 5 détecte `related.issues: [N]` → menu propose `[Keep existing]` en premier. Si user re-pick `[Attach REQ-X]` (autre REQ) → ajout multi-REQ. |
| Création stub : ID conflict | Step 8b.2 calcule `next` à chaque run (atomique sur file system). |
| Skip avec reason vide | Re-prompt jusqu'à reason non-vide ∨ user cancel. |

## Safety

1. ¬mute REQ frontmatter en dehors de `related.issues` (status, ACs, etc. = humain only en v1).
2. ¬supprimer un REQ. Detach reporté en v2.
3. ¬commit automatique. Le caller (`/dev` ∨ user) gère le commit du REQ muté avec le reste.
4. Lecture frontmatter : tolérante aux ordres de clés. Écriture : préserve l'ordre original.

## Chain Position

- **Phase:** Shape
- **Predecessor:** `/analyze` (artifact: `artifacts/analyses/{N}-*.mdx`) ∨ `/frame` (Tier F-lite)
- **Successor:** `/spec` (consomme `req:` frontmatter via grep `related.issues`)
- **Class:** gate (action persistée) — toujours interactif via `AskUserQuestion`

## Task Integration

- Standalone : ¬gère de TaskList. Single-shot.
- Invoqué par `/dev` : la step task `requirements` est gérée par `/dev` (ouvert par 2b.2, fermé en retour).
