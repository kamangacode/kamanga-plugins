#!/usr/bin/env bash
# Usage: scan-state.sh <N> <slug> [--check-tier F-lite|F-full]
# Outputs explicit key=value for each pipeline state check.
N=$1
SLUG=$2

REPO=$(gh repo view --json name --jq '.name' 2>/dev/null || echo "")

# triage
gh issue view "$N" --json state 2>/dev/null \
  && echo "triage=true" || echo "triage=false"

# frame (handles both {N}-{slug}.mdx and {slug}.mdx patterns)
FRAME=$(ls artifacts/frames/ 2>/dev/null | grep -iE "^${N}-${SLUG}|^${SLUG}" | head -1)
[ -n "$FRAME" ] && echo "frame=$FRAME" || echo "frame=false"

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
compute_requirements() {
  # Check if stack.yml exists and requirements.enabled is true
  local STACK=".claude/stack.yml"
  if [ ! -f "$STACK" ]; then
    echo "requirements=true"
    return
  fi

  # Parse requirements.enabled — look for 'enabled: true' within requirements stanza
  local IN_REQ=0
  local ENABLED=false
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^requirements:"; then
      IN_REQ=1
    elif [ "$IN_REQ" -eq 1 ]; then
      if echo "$line" | grep -qE "^\s+enabled:\s+true"; then
        ENABLED=true
        break
      elif echo "$line" | grep -qE "^[a-zA-Z]"; then
        # New top-level key — left requirements stanza
        break
      fi
    fi
  done < "$STACK"

  if [ "$ENABLED" != "true" ]; then
    echo "requirements=true"
    return
  fi

  # Parse requirements.root (default: docs/requirements/)
  local REQ_ROOT="docs/requirements/"
  local IN_REQ2=0
  while IFS= read -r line; do
    if echo "$line" | grep -qE "^requirements:"; then
      IN_REQ2=1
    elif [ "$IN_REQ2" -eq 1 ]; then
      if echo "$line" | grep -qE "^\s+root:\s+\S"; then
        REQ_ROOT=$(echo "$line" | sed 's/^[[:space:]]*root:[[:space:]]*//')
        break
      elif echo "$line" | grep -qE "^[a-zA-Z]"; then
        break
      fi
    fi
  done < "$STACK"

  # Check 1: REQ artifact references this issue
  if [ -d "$REQ_ROOT" ]; then
    if grep -rlE "issues:\s*\[[^]]*\b${N}\b" "$REQ_ROOT" >/dev/null 2>&1; then
      echo "requirements=true"
      return
    fi
  fi

  # Check 2: frame body contains "## Requirements skipped"
  if [ -n "$FRAME" ] && [ "$FRAME" != "false" ]; then
    if [ -f "artifacts/frames/${FRAME}" ] && grep -q "^## Requirements skipped" "artifacts/frames/${FRAME}" 2>/dev/null; then
      echo "requirements=true"
      return
    fi
  fi

  # Check 3: spec frontmatter contains "requirements: skipped"
  if [ -n "$SPEC" ] && [ "$SPEC" != "false" ]; then
    if [ -f "artifacts/specs/${SPEC}" ] && head -20 "artifacts/specs/${SPEC}" | grep -qE "^requirements:\s*skipped"; then
      echo "requirements=true"
      return
    fi
  fi

  # Check 4: marker file exists
  if [ -f ".claude/req-skipped/${N}.md" ]; then
    echo "requirements=true"
    return
  fi

  echo "requirements=false"
}

compute_requirements

# --check-tier gate
if [ "$3" = "--check-tier" ] && { [ "$4" = "F-lite" ] || [ "$4" = "F-full" ]; }; then
  REQ_VAL=$(compute_requirements)
  if [ "$REQ_VAL" = "requirements=false" ]; then
    cat >&2 <<EOF
step \`requirements\` not satisfied for issue #${N}
  → run /req --issue ${N}  (attach existing, create new, or log skip)
  → or check existing REQs: ensure related.issues includes ${N}
EOF
    exit 2
  fi
fi
