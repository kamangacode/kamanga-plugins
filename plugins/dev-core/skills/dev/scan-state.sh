#!/usr/bin/env bash
# Usage: scan-state.sh <N> <slug> [--check-tier F-lite|F-full]
# Outputs explicit key=value for each pipeline state check.
N=$1
SLUG=$2

# Input validation: $N must be a positive integer.
# Defends against path-traversal in .claude/req-skipped/${N}.md and regex
# injection in the REQ artifact grep below.
if ! [[ "$N" =~ ^[0-9]+$ ]]; then
  echo "scan-state.sh: <N> must be a positive integer, got '$N'" >&2
  exit 1
fi

REPO=$(gh repo view --json name --jq '.name' 2>/dev/null || echo "")

# triage
gh issue view "$N" --json state 2>/dev/null \
  && echo "triage=true" || echo "triage=false"

# frame (handles both {N}-{slug}.mdx and {slug}.mdx patterns)
FRAME=$(ls artifacts/frames/ 2>/dev/null | grep -iE "^${N}-${SLUG}|^${SLUG}" | head -1)
[ -n "$FRAME" ] && echo "frame=$FRAME" || echo "frame=false"

# recheck (session-only state — no on-disk artifact, /dev tracks via Σ_s)
# Value is always `null` (sentinel); /dev never parses it for truthiness — recheck always
# runs via Σ_s (see Step 1 — Scan State in dev/SKILL.md). Line exists for parser uniformity.
echo "recheck=null"

# analyze
ANALYZE=$(ls artifacts/analyses/ 2>/dev/null | grep -E "^${N}-|${SLUG}" | head -1)
[ -n "$ANALYZE" ] && echo "analyze=$ANALYZE" || echo "analyze=false"

# spec
SPEC=$(ls artifacts/specs/ 2>/dev/null | grep "^${N}-" | head -1)
[ -n "$SPEC" ] && echo "spec=$SPEC" || echo "spec=false"

# plan
PLAN=$(ls artifacts/plans/ 2>/dev/null | grep "^${N}-" | head -1)
[ -n "$PLAN" ] && echo "plan=$PLAN" || echo "plan=false"

# worktree (.claude/worktrees/ and legacy parent-dir)
WORKTREE=$(git worktree list 2>/dev/null | grep -E "${REPO}-${N}|worktrees/${N}-" | head -1)
[ -n "$WORKTREE" ] && echo "worktree=$WORKTREE" || echo "worktree=false"

# branch
BRANCH=$(git branch -a 2>/dev/null | grep "${N}-${SLUG}" | head -1 | xargs)
[ -n "$BRANCH" ] && echo "branch=$BRANCH" || echo "branch=false"

# pr
PR_JSON=$(gh pr list --search "#${N}" --json number,state,reviewDecision,merged --jq '.[]' 2>/dev/null)
if [ -n "$PR_JSON" ]; then
  echo "pr=$PR_JSON"
  PR_NUM=$(gh pr list --search "#${N}" --json number --jq '.[0].number' 2>/dev/null)
  gh pr view "$PR_NUM" --json comments --jq '.comments[].body' 2>/dev/null \
    | grep -q "^## Code Review" && echo "review_comment=true" || echo "review_comment=false"
  gh pr view "$PR_NUM" --json comments --jq '.comments[].body' 2>/dev/null \
    | grep -q "^## Review Fixes Applied" && echo "fix_comment=true" || echo "fix_comment=false"
else
  echo "pr=false"
  echo "review_comment=false"
  echo "fix_comment=false"
fi

# requirements
# Sets globals REQUIREMENTS (true|false) and REQUIREMENTS_REASON
# (disabled | req-attached | frame-marker | spec-marker | req-skipped-file | not-satisfied)
# so the caller can branch on the value without a second invocation (which would
# re-run every file probe). One probe, two emit lines.
compute_requirements() {
  local STACK=".claude/stack.yml"
  if [ ! -f "$STACK" ]; then
    REQUIREMENTS=true
    REQUIREMENTS_REASON=disabled
    return
  fi

  # Parse requirements.enabled — accept case-insensitive YAML 1.1 truthy values
  # (true / True / TRUE). Only the lowercase form is documented as canonical,
  # but tolerating capital forms avoids silent misreads.
  local IN_REQ=0
  local ENABLED=false
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^requirements:"; then
      IN_REQ=1
    elif [ "$IN_REQ" -eq 1 ]; then
      if echo "$line" | grep -qE "^[[:space:]]+enabled:[[:space:]]+[Tt][Rr][Uu][Ee][[:space:]]*$"; then
        ENABLED=true
        break
      elif echo "$line" | grep -qE "^[a-zA-Z]"; then
        # New top-level key — left requirements stanza
        break
      fi
    fi
  done < "$STACK"

  if [ "$ENABLED" != "true" ]; then
    REQUIREMENTS=true
    REQUIREMENTS_REASON=disabled
    return
  fi

  # Parse requirements.root (default: docs/requirements/)
  local REQ_ROOT="docs/requirements/"
  local IN_REQ2=0
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^requirements:"; then
      IN_REQ2=1
    elif [ "$IN_REQ2" -eq 1 ]; then
      if echo "$line" | grep -qE "^[[:space:]]+root:[[:space:]]+\S"; then
        REQ_ROOT=$(echo "$line" | sed 's/^[[:space:]]*root:[[:space:]]*//')
        break
      elif echo "$line" | grep -qE "^[a-zA-Z]"; then
        break
      fi
    fi
  done < "$STACK"

  # Check 1: REQ artifact references this issue.
  # Two grep passes — YAML flow sequence (`issues: [42]`) AND block sequence
  # (`issues:\n  - 42`). The block-sequence form is matched by finding any line
  # of the form `^\s*-\s*N\s*$` in a REQ file that also contains an `issues:`
  # line; the simpler heuristic below grep's for the digit on its own line.
  if [ -d "$REQ_ROOT" ]; then
    # Flow sequence: issues: [42] or issues: [..., 42, ...]
    if grep -rlE "issues:[[:space:]]*\[[^]]*\b${N}\b" "$REQ_ROOT" >/dev/null 2>&1; then
      REQUIREMENTS=true
      REQUIREMENTS_REASON=req-attached
      return
    fi
    # Block sequence: scan files that contain BOTH an `issues:` key AND a
    # `- N` list item on its own line. False-positive risk is low because the
    # block-sequence item form must be exact (`- 42`, optionally with surrounding
    # whitespace).
    local f
    while IFS= read -r f; do
      if [ -n "$f" ] && grep -qE "^[[:space:]]*-[[:space:]]+${N}[[:space:]]*$" "$f"; then
        REQUIREMENTS=true
        REQUIREMENTS_REASON=req-attached
        return
      fi
    done < <(grep -rlE "^[[:space:]]*issues:[[:space:]]*$" "$REQ_ROOT" 2>/dev/null)
  fi

  # Check 2: frame body contains "## Requirements skipped"
  if [ -n "$FRAME" ] && [ "$FRAME" != "false" ]; then
    if [ -f "artifacts/frames/${FRAME}" ] && grep -q "^## Requirements skipped" "artifacts/frames/${FRAME}" 2>/dev/null; then
      REQUIREMENTS=true
      REQUIREMENTS_REASON=frame-marker
      return
    fi
  fi

  # Check 3: spec frontmatter contains "requirements: skipped"
  if [ -n "$SPEC" ] && [ "$SPEC" != "false" ]; then
    if [ -f "artifacts/specs/${SPEC}" ] && head -20 "artifacts/specs/${SPEC}" | grep -qE "^requirements:[[:space:]]*skipped"; then
      REQUIREMENTS=true
      REQUIREMENTS_REASON=spec-marker
      return
    fi
  fi

  # Check 4: marker file exists.
  # Body schema (issue/reason/by/at) is documented in skills/req/SKILL.md as a
  # human-readable audit trail. The gate itself only checks file existence — the
  # body is not parsed and is not contractually stable. Future readers wanting
  # structured fields should define their own schema.
  if [ -f ".claude/req-skipped/${N}.md" ]; then
    REQUIREMENTS=true
    REQUIREMENTS_REASON=req-skipped-file
    return
  fi

  REQUIREMENTS=false
  REQUIREMENTS_REASON=not-satisfied
}

compute_requirements
echo "requirements=$REQUIREMENTS"
echo "requirements_reason=$REQUIREMENTS_REASON"

# --check-tier gate: CI-observable BLOCK path.
# Uses the already-computed REQUIREMENTS — does NOT re-invoke compute_requirements.
if [ "$3" = "--check-tier" ] && { [ "$4" = "F-lite" ] || [ "$4" = "F-full" ]; }; then
  if [ "$REQUIREMENTS" = "false" ]; then
    cat >&2 <<EOF
step \`requirements\` not satisfied for issue #${N}
  → run /req --issue ${N}  (attach existing, create new, or log skip)
  → or check existing REQs: ensure related.issues includes ${N}
EOF
    exit 2
  fi
fi
