# Tealun Skills

一组面向 AI Agent 的实用技能包，帮助代理在规划、执行、审计、修复和复盘时更稳、更可验证。

这个项目适合已经在使用 Codex、Claude Code、Cursor、Gemini、Kimi、OpenCode 或兼容 Agent Skills 目录规范工具的用户。你可以把这里的技能同步到本机，让代理在合适的场景自动采用更严格的工作流。

## 你能得到什么

| 技能 | 适合什么时候用 | 它帮你避免什么 |
| --- | --- | --- |
| `planner` | 项目前期规划、需求梳理、里程碑拆分 | 边写边猜、文档失控、架构决策缺证据 |
| `tasker` | 执行具体任务、补文档、改代码、做检查 | 代理嘴上说完成、实际没验证 |
| `auditor` | 项目审计、风险检查、代码评审 | 只看表面问题、缺少可复现证据 |
| `bugfixer` | 修复明确的报错、异常、回归问题 | 靠猜修 bug、没复现就改代码 |
| `evolver` | 把已验证经验沉淀成长期规则 | 同类问题反复出现、教训只停留在聊天里 |

## 快速开始

### Windows

```powershell
.\sync-skills.ps1 --list-targets
$env:DRY_RUN = '1'; .\sync-skills.ps1
Remove-Item Env:\DRY_RUN
.\sync-skills.ps1
```

### macOS / Linux

```bash
./sync-skills.sh --list-targets
DRY_RUN=1 ./sync-skills.sh
./sync-skills.sh
```

### 只安装某几个技能

```bash
./sync-skills.sh tasker planner
```

Windows 用户可使用：

```powershell
.\sync-skills.ps1 tasker planner
```

安装完成后，重新打开你的 Agent CLI 或新建会话，让工具重新加载技能目录。

更详细的步骤见 [QUICKSTART.md](QUICKSTART.md)。

## 如何使用

安装后，你可以直接在对话里提到技能名，也可以自然描述任务：

```text
用 tasker 帮我把这个任务做完，并给出验证结果。
```

```text
用 auditor 审计一下当前项目，优先看安全和部署风险。
```

```text
用 bugfixer 修复这个 500 报错，先复现再改。
```

大多数情况下，你不需要记住复杂命令。技能的价值在于让 Agent 在该谨慎的时候谨慎，在该验证的时候验证。

## 项目结构

```text
.
├── auditor/          # 证据驱动的项目审计技能
├── bugfixer/         # 面向具体症状的修复技能
├── evolver/          # 把经验固化为长期防线的复盘技能
├── planner/          # 项目前期规划技能
├── tasker/           # 通用任务执行纪律技能
├── sync-skills.ps1   # Windows 同步脚本
└── sync-skills.sh    # macOS / Linux / WSL 同步脚本
```

## 兼容范围

同步脚本会自动检测本机已安装或已配置的兼容工具，并把技能复制到对应的 `skills` 目录。当前脚本覆盖：

- Claude
- Codex
- Cursor
- Gemini
- Kimi
- OpenCode
- Shared agents (`~/.agents/skills`)

不同工具对 Agent Skills 的支持程度可能不同。如果某个工具没有加载成功，先确认它是否支持目录型 `SKILL.md` 技能包。

## 更新技能

拉取项目最新内容后重新运行同步脚本即可：

```bash
git pull
./sync-skills.sh
```

Windows：

```powershell
git pull
.\sync-skills.ps1
```

同步脚本是覆盖式复制：仓库里的技能内容会同步到目标技能目录；目标目录里仅本地存在的元数据文件通常会被保留。

## 反馈与参与

- 遇到使用问题：查看 [SUPPORT.md](SUPPORT.md)
- 想报告问题：提交 issue，并附上你的工具、系统和触发方式
- 想改进技能：阅读 [CONTRIBUTING.md](CONTRIBUTING.md)
- 安全相关问题：阅读 [SECURITY.md](SECURITY.md)

## 许可证

本项目使用 MIT License，详见 [LICENSE](LICENSE)。
