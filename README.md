# Tealun Skills

让 AI Agent 少一点"我以为我做了"，多一点"我证明我做到了"。

Tealun Skills 是一组可以同步到本机 Agent 工具的技能包。它面向已经在用 Codex、Claude Code、Cursor、Gemini、Kimi、OpenCode 或共享 `.agents/skills` 目录的用户：你不用换工具，只是给代理加上几套更稳的工作方式。

## 先解决这些问题

如果你用 AI Agent 做项目，大概率遇到过这些时刻：

- 让它改文件，它说完成了，结果没有写入、没有回读、没有验证。
- 让它做规划，它很快写了一堆文档，但需求、架构和验收标准还是散的。
- 让它审计代码，它只挑风格问题，真正的安全、数据、部署风险没有证据。
- 让它修 bug，它没复现就改，改完以后你还得自己判断是不是碰巧好了。
- 一个问题这次聊明白了，下个会话又从头犯。

这个仓库把这些场景拆成 5 个技能：先规划、再执行、会审计、能修复、最后把经验沉淀下来。技能的重点不是让 Agent 多说，而是让它少猜、少跳步，并把结果变成可检查的证据。

## 快速开始

把仓库里的技能同步到本机 Agent 工具的 `skills` 目录。建议先查看会写入哪些目标，再 dry run 预览一次，确认无误后正式同步。

### Windows

```powershell
git clone https://github.com/tealun/Tealun-Skills.git
cd Tealun-Skills
.\sync-skills.ps1 --list-targets
$env:DRY_RUN = '1'
.\sync-skills.ps1
Remove-Item Env:\DRY_RUN
.\sync-skills.ps1
```

### macOS / Linux

```bash
git clone https://github.com/tealun/Tealun-Skills.git
cd Tealun-Skills
bash ./sync-skills.sh --list-targets
DRY_RUN=1 bash ./sync-skills.sh
bash ./sync-skills.sh
```

### 只同步指定技能

如果你只想安装某几个技能，把技能名放到命令末尾：

```powershell
.\sync-skills.ps1 tasker planner
```

macOS / Linux：

```bash
bash ./sync-skills.sh tasker planner
```

安装后，重新打开你的 Agent CLI 或新建会话，让工具重新加载技能目录。

## 安装后怎么用

进入你的项目目录，重新打开 Agent CLI 或新建会话。在 Codex 这类支持 slash command 的工具里，直接输入：

```text
/tasker 检查当前项目 README 是否有断链，并给出验证结果。
/auditor 审计当前项目，优先看 README、安装脚本和文档一致性。
/bugfixer 修复这个 500 报错，先复现再改。
/planner 梳理这个项目的 M0/M1 计划，先找架构风险。
/evolver 把这次已验证的修复经验落到项目规则和演进台账。
```

不支持 slash command 的工具，把 `/tasker` 换成“用 tasker”这类自然语言即可。

如果技能已加载，Agent 会按对应技能的工作流执行。比如 `tasker` 会说明任务范围、验证方法、执行证据和最终结论，而不是只给一句"看起来没问题"。

### 自动触发

很多 Agent 会根据每个技能 `SKILL.md` 里的 `description` 自动选择技能。你不一定要手动输入 `/tasker`：

- 说“帮我把这个任务做完，并给出验证结果”时，通常会触发 `tasker`。
- 说“审计这个项目”“做一次代码 review”“检查安全和部署风险”时，通常会触发 `auditor`。
- 贴出报错、500、回归问题，或者说“还是不对”“先复现再修”时，通常会触发 `bugfixer`。
- 说“需求梳理”“技术方案”“M0/M1 计划”“项目规划”时，通常会触发 `planner`。
- 说“固化经验”“防止复发”“落到规则/台账/复盘”时，通常会触发 `evolver`。

如果 Agent 没选中，直接用 slash command 强制指定即可。

更完整的安装和排障步骤见 [QUICKSTART.md](QUICKSTART.md)。

## 该用哪个技能

| 你的场景 | 推荐技能 | 它会帮你守住什么 |
| --- | --- | --- |
| 项目刚开始，需求、架构、里程碑还不清楚 | `planner` | 把决策、假设、待验证项和阶段门槛写清楚，减少边做边猜 |
| 你要 Agent 改代码、补文档、跑检查 | `tasker` | 每个完成声明都要有产物和验证，避免"说做了但没做" |
| 合并、发布或交付前想查风险 | `auditor` | 只报告有证据的问题，并区分严重性、置信度和验证缺口 |
| 已经有报错、回归、异常表现 | `bugfixer` | 先复现和定位，再做最小修复，避免靠经验猜 bug |
| 同类问题反复出现，想把教训留住 | `evolver` | 把已验证经验变成规则、检查、台账或下一轮计划输入 |

## 安装到哪里

同步脚本会检测本机已经安装或配置过的兼容工具，把技能复制到对应的 `skills` 目录。当前覆盖：

- Claude
- Codex
- Cursor
- Gemini
- Kimi
- Kimi Desktop（Windows）
- OpenCode
- Shared agents (`~/.agents/skills`)

脚本采用覆盖式复制：仓库里的技能内容会同步到目标目录；目标目录里仅本地存在的元数据文件通常会保留。同步前先跑 `DRY_RUN=1`，可以看到将要写入的位置。

## 更新技能

拉取最新内容后重新运行同步脚本即可。

macOS / Linux：

```bash
git pull
bash ./sync-skills.sh
```

Windows：

```powershell
git pull
.\sync-skills.ps1
```

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

## 遇到问题

先看三件事：

1. 你的 Agent 工具是否支持目录型 `SKILL.md` 技能包。
2. `--list-targets` 是否能找到目标目录。
3. 同步后是否重新打开了 Agent CLI 或新建会话。

更多排查方式见 [SUPPORT.md](SUPPORT.md)。想贡献改进可以看 [CONTRIBUTING.md](CONTRIBUTING.md)。安全相关问题请按 [SECURITY.md](SECURITY.md) 处理。

## 许可证

本项目使用 MIT License，详见 [LICENSE](LICENSE)。
