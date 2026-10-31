# 实战记录

这份文档记录作者 Tealun 在自己的项目里使用这套技能的情况。作者不是专业程序员，项目代码基本由 AI Agent 编写，作者负责产品决定、验收和纠偏。下面的数字来自各项目的 git 历史和项目文档，统计到 2026 年 10 月底。

## English summary

Real use of these skills across the author's own projects, all built mainly by AI agents with a non-programmer owner directing and accepting the work. Figures come from each project's git history and docs, as of late October 2026.

- **Moread** (English close-reading WeChat mini-program, live about four months, 800+ registered users): 1,278 commits since 2026-04-14. The first 16 commits were documents only, including five rounds of document audits (each fixing 5 to 18 gaps) before the first code commit. 120 audit reports in `docs/99-audits`. Every bug fix is logged as symptom, cause, fix, release and leftovers.
- **Tiko.day** (AI task and calendar assistant on Google Calendar and Google Tasks): 421 commits from 2026-10-19 to 10-28. The first 13 commits were docs only (product brief, architecture, data model, pricing, M0 fact-verification gates). Contracts were fixed before agents worked in parallel. 13 audit reports; the first found 0 P0 and 4 P1, including a settings-page crash and a browser path that bypassed server validation. 54 end-to-end test specs, a handoff doc for new sessions, and 15 owner feedback items triaged as do / do differently / don't (with reason) / clarify.
- **Kelibron** (browser-based 3D precision-measurement training lab): 1,095 commits from 2026-10-05 to 10-28. The first 4 commits were docs, including a user value and retention audit that narrowed the MVP. An evolution ledger with 70 entries, 64 test files, and a deploy gate that fails the Cloudflare build when lint or tests fail. The skills are vendored into the repo, and the public [Labsmith](https://github.com/tealun/labsmith) skill was distilled from this project.
- **A small game in development**: the first 9 commits were docs only, including three audits (readiness, deep design review, consistency) before the first prototype. The docs tree follows planner's structure exactly.
- **business-card-saas** (public repo): the first 18 commits contained no product code; 7 audit reports over 1,700 lines. A doc audit found an unauthenticated, PII-writable leads endpoint before any code existed.

## 先说明两点

- 这些项目和技能包是一起成长的。Moread 从 2026 年 4 月开始开发，早于本仓库加入 planner、bugfixer、evolver 的时间（2026 年 7 月）。所以下面的记录反映的是这些做法本身，不全是某一个技能版本的效果。
- 这里只写能在项目仓库里查到的事实，不推算效率提升之类的数字。

## Moread（沫读）

英语精读微信小程序，每天一个番茄钟，七天精读一篇 AI 生成的文章。已上线约 4 个月，注册用户 800 多人。

- 从 2026-04-14 起共 1,278 次提交。
- 前 16 次提交全是文档，其中做了五轮文档审计，每轮补上 5 到 18 个缺口，之后才有第一次代码提交。对应 planner 的「先规划、过审计门槛再写代码」。
- `docs/99-audits` 里有 120 份审计报告。对应 auditor。
- 每个 bug 修复都按「现象 / 原因 / 修复 / 上线 / 遗留」记录。对应 bugfixer 的收尾报告。

## Tiko.day

基于 Google Calendar 和 Google Tasks 的 AI 任务与日程助手。

- 2026-10-19 到 10-28 共 421 次提交。
- 前 13 次提交全是文档：产品简介、架构、数据模型、定价，以及 M0 阶段的事实核验门槛。
- 先把接口和数据契约定下来，再让多个 Agent 并行开发。
- 13 份审计报告。第一份发现 0 个 P0、4 个 P1，其中包括设置页崩溃，以及一条绕过服务端校验的浏览器路径。
- 54 个端到端测试用例。
- 有一份交接文档，新会话先读它再开工。
- 作者提出的 15 条反馈逐条分类为：照做 / 换个做法 / 不做（写明原因）/ 需要澄清。对应 tasker 的「每条需求都要有结论」。

## Kelibron

浏览器里的 3D 精密测量实训室（游标卡尺、千分尺等量具的读数和测量练习）。

- 2026-10-05 到 10-28 共 1,095 次提交。
- 前 4 次提交是文档，其中一份用户价值与留存审计把 MVP 范围收窄了。
- 演进台账有 70 条记录。例子：
  - 游标卡尺读数显示 20.04，判定却用的是 20.06。修复后加了回归测试，要求每个场景显示的读数都等于测量值。
  - 一个千分尺拖动缺陷，bugfixer 先在浏览器里复现，再动手修。
- 64 个测试文件。部署门槛：lint 或测试失败时 Cloudflare 构建直接失败，不会上线。
- 技能以固定版本复制进了项目仓库（做法见 [agent-instructions-snippet.md](agent-instructions-snippet.md)）。
- 同一项目里，技能装了一个周期却一次没被调用，后来在项目指令里写明触发条件才解决。片段也在上面那份文档里。
- 公开的 [Labsmith](https://github.com/tealun/labsmith) 技能就是从这个项目里整理出来的。

## 一个正在开发的小游戏

项目名暂不公开。

- 前 9 次提交全是文档，其中做了三次审计（开发就绪、深度设计评审、一致性检查），之后才做第一个原型。
- 文档目录完全按 planner 的结构：`00_core`、`01_specs`、`02_tasks`、`03_compliance`、`88_planning`、`99_audits`。

## business-card-saas

名片 SaaS 平台，公开仓库。

- 前 18 次提交没有产品代码。
- 7 份审计报告，合计 1,700 多行。
- 还没写代码时，一次文档审计就发现了一个无需登录、可以写入个人信息的 leads 接口设计。

## 能从这些记录里看出的做法

- 先写文档、先审计，再写代码。五个项目最开始的 4 到 18 次提交都没有产品代码。
- 审计报告作为文件留在仓库里（Moread 120 份，Tiko.day 13 份，business-card-saas 7 份）。
- 修 bug 有固定的记录格式（Moread），先复现再修，修好后补一条回归测试（Kelibron）。
- 纠正过的问题记进演进台账，并写明用什么检查防止它再出现（Kelibron）。
- 在项目指令里写明每个技能的触发条件，不指望 Agent 自己想起来（Kelibron）。
