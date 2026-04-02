#!/bin/bash
# Memory Forest v5.1 - Core Engine (Markdown Edition)
# 统一使用.md格式，零注入风险

set -euo pipefail

MF_VERSION="1.0.0"
MF_BASE_PATH="${MF_BASE_PATH:-${HOME}/memory/forest}"
MF_AGENT_ID="${MF_AGENT_ID:-default}"

# 基础树列表
MF_BASE_TREES=("identity" "rules" "corrections" "context" "workflow")

# ============================================
# 季节计算（实时）
# ============================================

mf_get_season() {
    local month=$(date '+%m')
    local season=""
    local emoji=""
    
    case "$month" in
        03|04|05) season="spring"; emoji="🌸" ;;
        06|07|08) season="summer"; emoji="☀️" ;;
        09|10|11) season="autumn"; emoji="🍂" ;;
        12|01|02) season="winter"; emoji="❄️" ;;
    esac
    
    echo "$season|$emoji"
}

mf_get_season_name() {
    mf_get_season | cut -d'|' -f1
}

mf_get_season_emoji() {
    mf_get_season | cut -d'|' -f2
}

# 季节对health的影响
mf_season_health_boost() {
    local season=$(mf_get_season_name)
    
    case "$season" in
        spring) echo "20" ;;
        summer) echo "0" ;;
        autumn) echo "0" ;;
        winter) echo "-10" ;;
    esac
}

mf_season_decay_rate() {
    local season=$(mf_get_season_name)
    
    case "$season" in
        spring) echo "1.0" ;;
        summer) echo "0.5" ;;
        autumn) echo "1.2" ;;
        winter) echo "0.8" ;;
    esac
}

# ============================================
# 路径安全检查
# ============================================

mf_validate_agent_id() {
    local agent_id="$1"
    
    # 只允许字母、数字、连字符、下划线
    if [[ ! "$agent_id" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: Invalid agent_id. Only a-z, A-Z, 0-9, -, _ allowed." >&2
        return 1
    fi
    
    # 禁止路径遍历关键字
    if [[ "$agent_id" == *".."* || "$agent_id" == *"/"* || "$agent_id" == *"\\"* ]]; then
        echo "Error: agent_id cannot contain path traversal characters." >&2
        return 1
    fi
    
    return 0
}

# ============================================
# 动态森林初始化
# ============================================

mf_init_agent_forest() {
    local agent_id="${1:-$MF_AGENT_ID}"
    local agent_path="${MF_BASE_PATH}/agents/${agent_id}"
    
    # 验证agent_id
    mf_validate_agent_id "$agent_id" || return 1
    
    # 已存在则跳过
    [[ -d "$agent_path" ]] && return 0
    
    echo "🌱 Creating forest for agent: $agent_id"
    
    # 创建目录结构
    mkdir -p "$agent_path"
    for tree in "${MF_BASE_TREES[@]}"; do
        mkdir -p "$agent_path/$tree"
    done
    
    # 生成forest.md总览
    cat > "$agent_path/forest.md" << EOF
# 🌳 Memory Forest - Agent: ${agent_id}

**Generated**: $(date '+%Y-%m-%d %H:%M:%S')  
**Version**: ${MF_VERSION}

## Agent Info
- **ID**: ${agent_id}
- **Created**: $(date '+%Y-%m-%d %H:%M:%S')
- **Season**: $(mf_get_season_name)

## Trees
$(for t in "${MF_BASE_TREES[@]}"; do echo "- ${t}"; done)

## Dynamic Trees
<!-- DYNAMIC_TREES_START -->
<!-- DYNAMIC_TREES_END -->

## Stats
- Total Memories: 0
- Health Avg: 100
- Last Watered: $(date '+%Y-%m-%d %H:%M:%S')
EOF

    # 生成基础树文件
    mf_init_tree "$agent_id" "identity"
    mf_init_tree "$agent_id" "rules"
    
    echo "✅ Forest created: $agent_path"
}

mf_init_tree() {
    local agent_id=$1
    local tree=$2
    local path="${MF_BASE_PATH}/agents/${agent_id}/${tree}"
    
    case "$tree" in
        identity)
            cat > "$path/core.md" << 'EOF'
---
id: identity
type: tree
core_level: trunk
---

# 🌲 Identity Tree

## Core Identity
- Name: 
- Role: 
- Created: 

## Leaves
<!-- 动态生成的叶记忆将列在这里 -->
EOF
            ;;
        rules)
            cat > "$path/core.md" << 'EOF'
---
id: rules
type: tree
core_level: trunk
---

# 📜 Rules Tree

## Core Rules
<!-- 核心规则 -->

## Branches
<!-- 稳定规则 -->

## Leaves
<!-- 临时规则 -->
EOF
            ;;
    esac
}

# ============================================
# 共享目录初始化
# ============================================

mf_init_shared() {
    local shared_path="${MF_BASE_PATH}/shared"
    
    [[ -d "$shared_path" ]] && return 0
    
    mkdir -p "$shared_path"
    
    # user-profile.md
    cat > "$shared_path/user-profile.md" << 'EOF'
---
type: user-profile
updated: ""
---

# 用户画像

## 基本信息
- 称呼: 
- 时区: 

## 偏好
- 回复风格: 
- 决策方式: 

## 禁忌
- 
EOF

    # core-rules.md
    cat > "$shared_path/core-rules.md" << 'EOF'
---
type: core-rules
version: 1.0
---

# 核心铁律

## 永不违背
1. 不编造数据
2. 不重复犯错
3. 被纠正立即记录

## 行为准则
- 简洁回复
- 直接执行
- 主动闭环
EOF

    echo "✅ Shared memory created"
}

# ============================================
# 健康度实时计算
# ============================================

mf_calc_health() {
    local last_watered="$1"
    local base_health="${2:-100}"
    
    local now=$(date '+%s')
    local last=$(date -d "$last_watered" '+%s' 2>/dev/null || echo "$now")
    local hours=$(( (now - last) / 3600 ))
    
    # 确保hours不为负数
    [[ $hours -lt 0 ]] && hours=0
    
    local decay_rate=$(mf_season_decay_rate)
    local decay=$(echo "$hours * 2 * $decay_rate" | bc -l 2>/dev/null || echo "$((hours * 2))")
    
    local health=$(echo "$base_health - ${decay%.*}" | bc 2>/dev/null || echo "$((base_health - hours * 2))")
    
    # 季节加成
    local boost=$(mf_season_health_boost)
    health=$((health + boost))
    
    # 边界
    [[ $health -gt 100 ]] && health=100
    [[ $health -lt 0 ]] && health=0
    
    echo "$health"
}

# 计算树的健康度
mf_calc_tree_health() {
    local agent_id=$1
    local tree=$2
    local tree_path="${MF_BASE_PATH}/agents/${agent_id}/${tree}"
    
    [[ ! -d "$tree_path" ]] && echo "0" && return
    
    local total_health=0
    local count=0
    
    for file in "$tree_path"/*.md; do
        [[ ! -f "$file" ]] && continue
        [[ "$file" == *"/core.md" ]] && continue  # 跳过core.md
        
        local grown=$(grep "^grown:" "$file" 2>/dev/null | sed 's/grown:[[:space:]]*"//; s/"$//' | head -1)
        local base=$(grep "^health:" "$file" 2>/dev/null | awk '{print $2}' | head -1 || echo "100")
        
        [[ -z "$grown" ]] && continue
        
        local current=$(mf_calc_health "$grown" "$base")
        total_health=$((total_health + current))
        count=$((count + 1))
    done
    
    [[ $count -eq 0 ]] && echo "100" && return
    
    echo $((total_health / count))
}

# ============================================
# 记忆操作
# ============================================

mf_remember() {
    local agent_id="${1:-$MF_AGENT_ID}"
    local tree="${2:-}"
    local content="${3:-}"
    local context="${4:-}"
    
    [[ -z "$tree" || -z "$content" ]] && {
        echo "Usage: remember <tree> <content> [context]"
        return 1
    }
    
    # 验证agent_id
    mf_validate_agent_id "$agent_id" || return 1
    
    # 确保森林存在
    mf_init_agent_forest "$agent_id"
    
    # 动态树处理
    if [[ ! -d "${MF_BASE_PATH}/agents/${agent_id}/${tree}" ]]; then
        mkdir -p "${MF_BASE_PATH}/agents/${agent_id}/${tree}"
        mf_add_dynamic_tree "$agent_id" "$tree"
    fi
    
    local id=$(date +%s%N | sha256sum | head -c 8)
    local season=$(mf_get_season_name)
    local health_boost=$(mf_season_health_boost)
    local timestamp=$(date '+%Y-%m-%d')
    local datetime=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 使用.md格式，内容放在正文，零注入风险
    cat > "${MF_BASE_PATH}/agents/${agent_id}/${tree}/${timestamp}-${id}.md" << EOF
---
id: "${id}"
tree: "${tree}"
level: leaf
health: $((100 + health_boost))
grown: "${datetime}"
season: "${season}"
---

# Memory Entry

**Context**: ${context}

${content}
EOF

    echo "🌱 Grown: ${timestamp}-${id} in $tree tree (season: $season, +${health_boost} health)"
}

# 安全添加动态树
mf_add_dynamic_tree() {
    local agent_id=$1
    local tree=$2
    local forest_file="${MF_BASE_PATH}/agents/${agent_id}/forest.md"
    
    local tmp_file=$(mktemp)
    
    awk -v tree="$tree" '
        /<!-- DYNAMIC_TREES_END -->/ {
            print "- " tree
        }
        {print}
    ' "$forest_file" > "$tmp_file"
    
    mv "$tmp_file" "$forest_file"
}

# ============================================
# 场景匹配加载
# ============================================

mf_recall() {
    local agent_id="${1:-$MF_AGENT_ID}"
    local scene="${2:-}"
    
    [[ -z "$scene" ]] && {
        echo "Usage: recall <scene>"
        return 1
    }
    
    mf_validate_agent_id "$agent_id" || return 1
    mf_init_agent_forest "$agent_id"
    
    echo "🌳 Recalling for scene: $scene"
    echo ""
    
    # 加载共享记忆
    echo "## Shared Memories"
    mf_load_shared
    
    echo ""
    echo "## Agent Memories ($agent_id)"
    
    # 场景匹配（使用关联数组去重）
    declare -A loaded_trees
    
    case "$scene" in
        morning*|report*)
            [[ -z "${loaded_trees[rules]:-}" ]] && { mf_load_tree "$agent_id" "rules"; loaded_trees[rules]=1; }
            [[ -z "${loaded_trees[workflow]:-}" ]] && { mf_load_tree "$agent_id" "workflow"; loaded_trees[workflow]=1; }
            ;;
        error*|wrong*|correction*)
            [[ -z "${loaded_trees[corrections]:-}" ]] && { mf_load_tree "$agent_id" "corrections"; loaded_trees[corrections]=1; }
            [[ -z "${loaded_trees[rules]:-}" ]] && { mf_load_tree "$agent_id" "rules"; loaded_trees[rules]=1; }
            ;;
        task*|work*)
            [[ -z "${loaded_trees[workflow]:-}" ]] && { mf_load_tree "$agent_id" "workflow"; loaded_trees[workflow]=1; }
            [[ -z "${loaded_trees[context]:-}" ]] && { mf_load_tree "$agent_id" "context"; loaded_trees[context]=1; }
            ;;
        *)
            [[ -z "${loaded_trees[identity]:-}" ]] && { mf_load_tree "$agent_id" "identity"; loaded_trees[identity]=1; }
            [[ -z "${loaded_trees[context]:-}" ]] && { mf_load_tree "$agent_id" "context"; loaded_trees[context]=1; }
            ;;
    esac
}

mf_load_shared() {
    local shared_path="${MF_BASE_PATH}/shared"
    
    for file in "$shared_path"/*.md; do
        [[ ! -f "$file" ]] && continue
        echo ""
        echo "### $(basename "$file" .md)"
        awk '/^---$/{if(++count<=2)next} count>=2{print}' "$file" | head -30
    done
}

mf_load_tree() {
    local agent_id=$1
    local tree=$2
    local tree_path="${MF_BASE_PATH}/agents/${agent_id}/${tree}"
    
    [[ ! -d "$tree_path" ]] && return
    
    echo ""
    echo "### $tree tree"
    
    for file in "$tree_path"/*.md; do
        [[ ! -f "$file" ]] && continue
        [[ "$file" == *"/core.md" ]] && continue
        
        local grown=$(grep "^grown:" "$file" 2>/dev/null | sed 's/grown:[[:space:]]*"//; s/"$//' | head -1)
        [[ -z "$grown" ]] && continue
        
        local health=$(mf_calc_health "$grown")
        
        # 冬季只加载健康度>50的
        [[ "$(mf_get_season_name)" == "winter" && $health -lt 50 ]] && continue
        
        local title=$(grep "^# " "$file" 2>/dev/null | head -1 | sed 's/^# //' || echo "Untitled")
        [[ -z "$title" ]] && title="Untitled"
        
        printf "  [%3d%%] %s\n" "$health" "$title"
    done
}

# ============================================
# 视觉化状态
# ============================================

mf_status() {
    local agent_id="${1:-$MF_AGENT_ID}"
    
    mf_validate_agent_id "$agent_id" || return 1
    
    local agent_path="${MF_BASE_PATH}/agents/${agent_id}"
    mf_init_agent_forest "$agent_id"
    
    local season=$(mf_get_season_name)
    local emoji=$(mf_get_season_emoji)
    
    # 计算整体健康度
    local total_health=0
    local tree_count=0
    
    for tree in "${MF_BASE_TREES[@]}"; do
        local h=$(mf_calc_tree_health "$agent_id" "$tree")
        total_health=$((total_health + h))
        tree_count=$((tree_count + 1))
    done
    
    local avg_health=$((total_health / tree_count))
    
    echo ""
    echo "🌳 $agent_id Forest | $emoji $season | Health: ${avg_health}%"
    echo ""
    
    echo "Trees:"
    for tree in "${MF_BASE_TREES[@]}"; do
        local h=$(mf_calc_tree_health "$agent_id" "$tree")
        local count=$(find "${agent_path}/${tree}" -name "*.md" ! -name "core.md" 2>/dev/null | wc -l)
        
        local bar=""
        local filled=$((h / 10))
        for ((i=0; i<10; i++)); do
            if [[ $i -lt $filled ]]; then
                bar+="█"
            else
                bar+="░"
            fi
        done
        
        printf "  🌲 %-12s %s %3d%%  %d items\n" "$tree" "$bar" "$h" "$count"
    done
    
    # 动态树
    local forest_file="${agent_path}/forest.md"
    if [[ -f "$forest_file" ]]; then
        local dynamic_count=$(awk '/<!-- DYNAMIC_TREES_START -->/,/<!-- DYNAMIC_TREES_END -->/' "$forest_file" | grep "^- " | wc -l)
        if [[ $dynamic_count -gt 0 ]]; then
            echo ""
            echo "Dynamic:"
            awk '/<!-- DYNAMIC_TREES_START -->/,/<!-- DYNAMIC_TREES_END -->/' "$forest_file" | grep "^- " | while read -r line; do
                local t=$(echo "$line" | sed 's/^- //')
                local h=$(mf_calc_tree_health "$agent_id" "$t")
                printf "  🌱 %-12s %d%%\n" "$t" "$h"
            done
        fi
    fi
    
    echo ""
    echo "Shared: user-profile, core-rules"
    
    # 即将枯萎的
    local wither_count=0
    for tree in "${MF_BASE_TREES[@]}"; do
        for file in "${agent_path}/${tree}"/*.md; do
            [[ ! -f "$file" ]] && continue
            [[ "$file" == *"/core.md" ]] && continue
            
            local grown=$(grep "^grown:" "$file" 2>/dev/null | sed 's/grown:[[:space:]]*"//; s/"$//' | head -1)
            [[ -z "$grown" ]] && continue
            
            local h=$(mf_calc_health "$grown")
            [[ $h -lt 30 ]] && wither_count=$((wither_count + 1))
        done
    done
    
    [[ $wither_count -gt 0 ]] && echo "🍂 Will wither: $wither_count leaves"
    
    echo ""
}

# ============================================
# 季节性维护
# ============================================

mf_maintain() {
    local agent_id="${1:-$MF_AGENT_ID}"
    
    mf_validate_agent_id "$agent_id" || return 1
    
    local agent_path="${MF_BASE_PATH}/agents/${agent_id}"
    local season=$(mf_get_season_name)
    
    echo "🍂 Seasonal maintenance for $season..."
    
    local archived=0
    
    for tree in "${MF_BASE_TREES[@]}"; do
        local tree_path="${agent_path}/${tree}"
        [[ ! -d "$tree_path" ]] && continue
        
        for file in "$tree_path"/*.md; do
            [[ ! -f "$file" ]] && continue
            [[ "$file" == *"/core.md" ]] && continue
            
            local grown=$(grep "^grown:" "$file" 2>/dev/null | sed 's/grown:[[:space:]]*"//; s/"$//' | head -1)
            [[ -z "$grown" ]] && continue
            
            local health=$(mf_calc_health "$grown")
            
            # 秋季归档低健康度
            if [[ "$season" == "autumn" && $health -lt 30 ]]; then
                mkdir -p "${agent_path}/${tree}/archive"
                mv "$file" "${agent_path}/${tree}/archive/"
                archived=$((archived + 1))
            fi
        done
    done
    
    [[ $archived -gt 0 ]] && echo "Archived $archived withered leaves"
    
    # 更新浇水时间
    local forest_file="${agent_path}/forest.md"
    if [[ -f "$forest_file" ]]; then
        local tmp_file=$(mktemp)
        sed "s/Last Watered:.*/Last Watered: $(date '+%Y-%m-%d %H:%M:%S')/" "$forest_file" > "$tmp_file"
        mv "$tmp_file" "$forest_file"
    fi
    
    echo "✅ Maintenance complete"
}

# ============================================
# 主入口
# ============================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        init)
            mf_init_shared
            mf_init_agent_forest "${2:-$MF_AGENT_ID}"
            ;;
        remember)
            shift
            mf_remember "$@"
            ;;
        recall)
            shift
            mf_recall "$@"
            ;;
        status)
            mf_status "${2:-$MF_AGENT_ID}"
            ;;
        maintain)
            mf_maintain "${2:-$MF_AGENT_ID}"
            ;;
        *)
            echo "Memory Forest v${MF_VERSION}"
            echo ""
            echo "Commands:"
            echo "  init [agent-id]              Initialize forest"
            echo "  remember <tree> <content>    Grow new memory"
            echo "  recall <scene>               Recall for scene"
            echo "  status [agent-id]            Show forest status"
            echo "  maintain [agent-id]          Seasonal maintenance"
            ;;
    esac
fi
