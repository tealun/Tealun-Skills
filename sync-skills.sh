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
#   ./sync-skills.sh --list-targets          # show detected compatible CLI targets
#
# Notes:
#   - Detects installed compatible CLIs from PATH or their local config directory.
#   - Creates a CLI's skills directory when the CLI is installed but the directory is absent.
#   - Targets use the "skills folder + lazy-loaded SKILL.md" convention.
#   - .agents/skills is the cross-agent shared directory read by Codex and others.
#   - Overlay copy preserves files that exist only in the target directory, such as _meta.json.
#   - Legacy single-file instructions (GEMINI.md, .mdc rules, etc.) are intentionally out of scope.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-0}"

TARGETS=()
TARGET_LABELS=()

has_command() {
  local command_name
  for command_name in "$@"; do
    command -v "$command_name" >/dev/null 2>&1 && return 0
  done
  return 1
}

add_target() {
  local label="$1" path="$2" existing
  for existing in "${TARGETS[@]:-}"; do
    [ "$existing" = "$path" ] && return
  done
  TARGET_LABELS+=("$label")
  TARGETS+=("$path")
}

# Only CLIs known to consume directory-based SKILL.md packages belong here.
# A PATH hit is preferred; an existing config directory also counts because GUI/IDE
# installs do not always expose their bundled CLI on PATH.
if has_command claude || [ -d "$HOME/.claude" ]; then
  add_target "Claude" "$HOME/.claude/skills"
fi
# Codex reads the shared Agent Skills directory. Prefer that location when it
# exists so the same skill is not installed twice. Fall back to Codex's own
# directory on machines that do not have the shared directory configured.
if (has_command codex || [ -d "$HOME/.codex" ]) && [ ! -d "$HOME/.agents" ]; then
  add_target "Codex" "$HOME/.codex/skills"
fi
if has_command cursor || [ -d "$HOME/.cursor" ]; then
  add_target "Cursor" "$HOME/.cursor/skills"
fi
if has_command gemini || [ -d "$HOME/.gemini" ]; then
  add_target "Gemini" "$HOME/.gemini/skills"
fi
if has_command kimi kimi-cli kimi-code || [ -d "$HOME/.kimi" ] || [ -d "$HOME/.kimi-code" ]; then
  add_target "Kimi" "$HOME/.kimi/skills"
fi
if has_command opencode || [ -d "$HOME/.config/opencode" ]; then
  add_target "OpenCode" "$HOME/.config/opencode/skills"
fi

# Shared Agent Skills is useful to multiple compatible agents. Do not create it
# on an unrelated machine, but retain it when already installed/configured.
if [ -d "$HOME/.agents" ]; then
  add_target "Shared agents" "$HOME/.agents/skills"
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "No installed CLI with a known SKILL.md directory was found; exiting."
  exit 1
fi

if [ "${1:-}" = "--list-targets" ]; then
  for i in "${!TARGETS[@]}"; do
    printf '%-14s %s\n' "${TARGET_LABELS[$i]}" "${TARGETS[$i]}"
  done
  exit 0
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
echo "Targets:"
for i in "${!TARGETS[@]}"; do
  echo "  ${TARGET_LABELS[$i]} -> ${TARGETS[$i]}"
done
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

  for i in "${!TARGETS[@]}"; do
    t="${TARGETS[$i]}"
    dst="$t/$skill"
    if [ "$DRY_RUN" = "1" ]; then
      echo "  [dry] ${TARGET_LABELS[$i]}: overlay $src/* -> $dst"
      continue
    fi

    mkdir -p "$dst"
    cp -r "$src"/* "$dst"/
    echo "  ok ${TARGET_LABELS[$i]} -> $dst"
  done

  echo
done

echo "Done."
