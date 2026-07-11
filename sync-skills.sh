#!/usr/bin/env bash
# sync-skills.sh — 把本仓库的技能同步到本机各 CLI 的 skills 目录
#
# 用法:
#   ./sync-skills.sh                # 同步仓库里所有含 SKILL.md 的技能
#   ./sync-skills.sh tasker         # 只同步指定技能
#   ./sync-skills.sh planning       # 同步 /planning 前期规划技能
#   ./sync-skills.sh tasker project-audit planning
#   DRY_RUN=1 ./sync-skills.sh ...  # 只打印将要做的动作，不实际拷贝
#
# 特性:
#   - 自动探测已存在的 CLI skills 目录，不存在则跳过
#   - 目标均为「skills 文件夹 + 按需加载」模式 (Claude/Codex/Kimi 及 .agents 通用约定)：
#     系统先看 skill 清单(名称/简介/路径)，点名或匹配时才读 SKILL.md，故直接 overlay 拷贝即可
#   - .agents/skills 是跨 agent 的通用共享目录 (Codex 等会读取)
#   - 支持本仓库里的快捷技能: /tasker, /planning 等
#   - overlay 拷贝: 覆盖同名文件，保留目标目录里仓库没有的文件 (如 codex 的 _meta.json)
#   - 不含 Gemini(单文件 GEMINI.md)与 Cursor(项目级 .mdc rules)——加载机制不同，非本脚本目标
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN="${DRY_RUN:-0}"

# 候选 CLI skills 目录 (存在才纳入；均为 skills 文件夹 + 按需加载模式)
CANDIDATE_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.codex/skills"
  "$HOME/.kimi/skills"
  "$HOME/.agents/skills"   # 跨 agent 通用共享目录 (Codex 等读取)
)
TARGETS=()
for d in "${CANDIDATE_DIRS[@]}"; do
  [ -d "$d" ] && TARGETS+=("$d")
done
if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "未探测到任何 CLI skills 目录，退出。"; exit 1
fi

# 要同步的技能: 命令行参数优先，否则取仓库所有含 SKILL.md 的目录
if [ "$#" -gt 0 ]; then
  SKILLS=("$@")
else
  SKILLS=()
  for s in "$REPO_DIR"/*/; do
    [ -f "${s}SKILL.md" ] && SKILLS+=("$(basename "$s")")
  done
fi

echo "源: $REPO_DIR"
echo "目标 CLI: ${TARGETS[*]}"
[ "$DRY_RUN" = "1" ] && echo "[DRY-RUN 模式，不实际写入]"
echo

for skill in "${SKILLS[@]}"; do
  src="$REPO_DIR/$skill"
  if [ ! -f "$src/SKILL.md" ]; then
    echo "跳过 $skill: 仓库无 $skill/SKILL.md"; continue
  fi
  ver="$(grep -m1 '^version:' "$src/SKILL.md" | awk '{print $2}' || echo '?')"
  echo "== $skill @ ${ver} =="
  for t in "${TARGETS[@]}"; do
    dst="$t/$skill"
    if [ "$DRY_RUN" = "1" ]; then
      echo "  [dry] overlay $src/* → $dst"
      continue
    fi
    mkdir -p "$dst"
    cp -r "$src"/* "$dst"/   # overlay: 只覆盖同名，保留目标独有文件 (_meta.json 等)
    echo "  ✓ → $dst"
  done
  echo
done

echo "完成。"
