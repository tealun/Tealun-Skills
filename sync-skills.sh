#!/usr/bin/env bash
# sync-skills.sh - sync this repository's skills into local CLI skill folders.
#
# Usage:
#   ./sync-skills.sh                         # sync all repo folders that contain SKILL.md
#   ./sync-skills.sh tasker                  # sync one skill
#   ./sync-skills.sh planner                 # sync /planner
#   ./sync-skills.sh bugfixer                # sync /bugfixer
#   ./sync-skills.sh tasker auditor planner bugfixer
#   DRY_RUN=1 ./sync-skills.sh bugfixer      # print actions without writing
#   ./sync-skills.sh --list-targets          # show detected compatible CLI targets
#   ./sync-skills.sh --target-env wsl        # explicitly sync the WSL environment
#   ./sync-skills.sh --target-env all         # sync Windows and WSL when run in WSL
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
TARGET_ENV="auto"
ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target-env)
      [ "$#" -ge 2 ] || { echo "--target-env requires: auto, windows, wsl, or all" >&2; exit 2; }
      TARGET_ENV="$2"
      shift 2
      ;;
    --target-env=*)
      TARGET_ENV="${1#*=}"
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done
set -- "${ARGS[@]}"

case "$TARGET_ENV" in
  auto|windows|wsl|all) ;;
  *) echo "Invalid --target-env: $TARGET_ENV (expected auto, windows, wsl, or all)" >&2; exit 2 ;;
esac

IS_WSL=0
if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  IS_WSL=1
fi

run_windows_sync() {
  command -v powershell.exe >/dev/null 2>&1 || {
    echo "Cannot sync Windows: powershell.exe is unavailable from this environment." >&2
    return 1
  }
  local windows_script
  windows_script="$(wslpath -w "$REPO_DIR/sync-skills.ps1")"
  echo "WSL detected: delegating Windows sync to $windows_script"
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$windows_script" "$@"
}

# A Bash process inside WSL has a Linux HOME even when launched from Windows.
# Default to the Windows companion so an unqualified run cannot silently write
# to /root. WSL writes require an explicit --target-env wsl (or all).
if [ "$IS_WSL" = "1" ]; then
  if [ "$TARGET_ENV" = "auto" ] || [ "$TARGET_ENV" = "windows" ]; then
    run_windows_sync "$@"
    exit $?
  fi
  if [ "$TARGET_ENV" = "all" ]; then
    run_windows_sync "$@"
    echo
  fi
elif [ "$TARGET_ENV" = "windows" ] || [ "$TARGET_ENV" = "all" ]; then
  echo "--target-env $TARGET_ENV is only supported by this script when running in WSL; use sync-skills.ps1 on Windows." >&2
  exit 2
elif [ "$TARGET_ENV" = "wsl" ]; then
  echo "--target-env wsl requires WSL." >&2
  exit 2
fi

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
    legacy_names=()
    case "$skill" in
      planner) legacy_names=("planning") ;;
      auditor) legacy_names=("project-audit") ;;
    esac
    if [ "$DRY_RUN" = "1" ]; then
      for legacy_name in "${legacy_names[@]}"; do
        legacy_dst="$t/$legacy_name"
        [ -d "$legacy_dst" ] && echo "  [dry] ${TARGET_LABELS[$i]}: remove renamed skill $legacy_dst"
      done
      echo "  [dry] ${TARGET_LABELS[$i]}: overlay $src/* -> $dst"
      continue
    fi

    for legacy_name in "${legacy_names[@]}"; do
      legacy_dst="$t/$legacy_name"
      if [ -d "$legacy_dst" ]; then
        rm -rf -- "$legacy_dst"
        echo "  migrated ${TARGET_LABELS[$i]}: removed $legacy_name"
      fi
    done

    mkdir -p "$dst"
    cp -r "$src"/* "$dst"/
    echo "  ok ${TARGET_LABELS[$i]} -> $dst"
  done

  echo
done

echo "Done."
