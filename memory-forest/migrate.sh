#!/bin/bash
# Memory Forest v5.1 Migration Script
# 从旧系统迁移记忆到新forest

set -euo pipefail

MF_OLD_BASE="/root/memory/forest-backup-20260331"
MF_NEW_BASE="/root/memory/forest"
MF_VERSION="1.0.0"

echo ""
echo "🌳 Memory Forest v${MF_VERSION} Migration"
echo "===================================="
echo ""

# 检查旧系统是否存在
if [[ ! -d "$MF_OLD_BASE" ]]; then
    echo "❌ No old forest found at $MF_OLD_BASE"
    exit 1
fi

echo "📁 Old forest: $MF_OLD_BASE"
echo "📁 New forest: $MF_NEW_BASE"
echo ""

# 确认迁移
echo "⚠️  This will migrate memories to new format"
echo "   Old data will be preserved"
echo ""
read -p "Continue? [y/N] " -n 1 -r
echo ""
[[ ! $REPLY =~ ^[Yy]$ ]] && exit 0

# 创建新forest基础结构
mkdir -p "$MF_NEW_BASE/shared"
mkdir -p "$MF_NEW_BASE/agents"

# 迁移shared记忆
echo ""
echo "🔄 Migrating shared memories..."

# 从hot-memory.md创建user-profile.md
if [[ -f "${HOME}/memory/forest/hot-memory.md" ]]; then
    cat > "$MF_NEW_BASE/shared/user-profile.md" << EOF
---
type: user-profile
migrated_from: hot-memory.md
migrated_at: $(date '+%Y-%m-%d %H:%M:%S')
---

# User Profile

## Identity
- Name: Kimi虾
- Role: AI assistant created by Moonshot AI
- Position: Cofounder, not assistant

## Core Rules
1. No pretty words - only objective facts
2. Data authenticity - never fabricate
3. Active follow-up - close the loop
4. Record immediately - write to corrections when corrected

## User Preferences (Tealun)
- Concise replies, no verbosity
- Don't ask too much, solve and report
- Objective, correct, reasoned responses
- Reject flattery and compliments

## Pre-flight Checklist
- [ ] Did I execute or just talk about executing?
- [ ] Did user receive it? Any messageId?
- [ ] Am I asking? If so, change to direct execution + report
- [ ] Is this fact or pretty words?

## Current Status
- Phase: Re-domestication
- Tasks: 2 cron jobs
- Skills: memory-forest

*Migrated from hot-memory.md*
EOF
    echo "   ✅ Migrated: hot-memory.md → user-profile.md"
fi

# 从corrections.md创建corrections
cat > "$MF_NEW_BASE/shared/core-rules.md" << 'EOF'
---
type: core-rules
version: 1.0
---

# Core Rules

## Never Violate
1. No fabricated data
2. No repeated mistakes
3. Record immediately when corrected

## Behavior
- Concise replies
- Direct execution
- Active closure
EOF

# 迁移agents
echo ""
echo "🔄 Migrating agents..."

for agent_dir in "$MF_OLD_BASE"/agents/*/; do
    [[ ! -d "$agent_dir" ]] && continue
    
    agent_name=$(basename "$agent_dir")
    echo "   Agent: $agent_name"
    
    # 创建新agent结构
    mkdir -p "$MF_NEW_BASE/agents/$agent_name"
    
    # 迁移各树
    for tree in identity rules corrections context workflow; do
        if [[ -d "$agent_dir/$tree" ]]; then
            mkdir -p "$MF_NEW_BASE/agents/$agent_name/$tree"
            
            # 复制现有.md文件
            for file in "$agent_dir/$tree"/*.md; do
                [[ ! -f "$file" ]] && continue
                cp "$file" "$MF_NEW_BASE/agents/$agent_name/$tree/"
            done
            
            # 转换.yaml文件为.md（如果有）
            for file in "$agent_dir/$tree"/*.yaml; do
                [[ ! -f "$file" ]] && continue
                
                # 简单转换：yaml内容转为markdown
                filename=$(basename "$file" .yaml)
                cat "$file" > "$MF_NEW_BASE/agents/$agent_name/$tree/${filename}.md"
            done
        fi
    done
    
    # 创建forest.md
    cat > "$MF_NEW_BASE/agents/$agent_name/forest.md" << EOF
# 🌳 Memory Forest - Agent: ${agent_name}

**Migrated**: $(date '+%Y-%m-%d %H:%M:%S')  
**Version**: ${MF_VERSION}

## Agent Info
- **ID**: ${agent_name}
- **Created**: $(date '+%Y-%m-%d %H:%M:%S')
- **Season**: spring

## Trees
- identity
- rules
- corrections
- context
- workflow

## Dynamic Trees
<!-- DYNAMIC_TREES_START -->
<!-- DYNAMIC_TREES_END -->

## Stats
- Total Memories: 0
- Health Avg: 100
- Last Watered: $(date '+%Y-%m-%d %H:%M:%S')
EOF
    
    echo "   ✅ Migrated: $agent_name"
done

# 创建完成标记
cat > "$MF_NEW_BASE/.migration_complete" << EOF
Migration completed at $(date '+%Y-%m-%d %H:%M:%S')
From: $MF_OLD_BASE
To: $MF_NEW_BASE
Version: $MF_VERSION
EOF

echo ""
echo "===================================="
echo "✅ Migration complete!"
echo ""
echo "New forest: $MF_NEW_BASE"
echo ""
echo "To switch to new forest:"
echo "  export MF_BASE_PATH=$MF_NEW_BASE"
echo ""
echo "Or update your shell profile:"
echo "  echo 'export MF_BASE_PATH=$MF_NEW_BASE' >> ~/.bashrc"
echo ""
