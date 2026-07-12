#!/usr/bin/env bash
# sync-skills.sh - sync this repository's skills into local CLI skill folders.
#
# Usage:
#   ./sync-skills.sh                         # sync all repo folders that contain SKILL.md
#   ./sync-skills.sh tasker                  # sync one skill
#   ./sync-skills.sh planning                # sync /planning
#   ./sync-skills.sh bugfixer                # sync /bugfixer
#   ./sync-skills.sh tasker project-audit planning bugfixer
#   DRY_RUN=1 ./sync-skills.sh bugfixer      # print actions without writing
#
# Notes:
#   - Auto-detects existing local skills directories and skips missing ones.
#   - Targets use the "skills folder + lazy-loaded SKILL.md" convention.
#   - .agents/skills is the cross-agent shared directory read by Codex and others.
#   - Overlay copy preserves files that exist only in the target directory, such as _meta.json.
#   - Gemini single-file GEMINI.md and Cursor .mdc rules are intentionally out of scope.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-0}"

CANDIDATE_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.kimi/skills"
  "$HOME/.agents/skills"
)

TARGETS=()
for d in "${CANDIDATE_DIRS[@]}"; do
  [ -d "$d" ] && TARGETS+=("$d")
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No local CLI skills directories found; exiting."
  exit 1
fi

if [ "$#" -gt 0 ]; then
  SKILLS=("$@")
else
  SKILLS=()
  for s in "$REPO_DIR"/*/; do
    [ -f "${s}SKILL.md" ] && SKILLS+=("$(basename "$s")")
  done
fi

echo "Source: $REPO_DIR"
echo "Targets: ${TARGETS[*]}"
[ "$DRY_RUN" = "1" ] && echo "[DRY-RUN: no writes]"
echo

for skill in "${SKILLS[@]}"; do
  src="$REPO_DIR/$skill"
  if [ ! -f "$src/SKILL.md" ]; then
    echo "Skip $skill: missing $skill/SKILL.md"
    continue
  fi

  ver="$(grep -m1 '^version:' "$src/SKILL.md" | awk '{print $2}' || echo '?')"
  echo "== $skill @ ${ver} =="

  for t in "${TARGETS[@]}"; do
    dst="$t/$skill"
    if [ "$DRY_RUN" = "1" ]; then
      echo "  [dry] overlay $src/* -> $dst"
      continue
    fi

    mkdir -p "$dst"
    cp -r "$src"/* "$dst"/
    echo "  ok -> $dst"
  done

  echo
done

echo "Done."
