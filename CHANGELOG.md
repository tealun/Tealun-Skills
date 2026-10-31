# Changelog

本文件记录 Tealun Skills 项目层面的重要变化。单个技能的历史说明可能位于各自目录内。

## Unreleased

- 新增面向开源用户的项目 README。
- 新增快速开始、支持、贡献、行为准则、安全策略和许可证文件。
- 明确技能集合、安装方式、兼容工具和反馈路径。
- `bugfixer` 增加生成物新鲜度/版本失效检查，以及部署进程找不到 CLI 二进制时的环境差异排查规则。
- `tasker` 增加提交/推送收口校验：区分用户改动与任务文件、回读本地提交，并用远端分支 SHA 验证推送结果；多阶段任务在阶段边界 checkpoint，清理仅限明确生成物。
- `bugfixer` 1.6.0：原症状验证消失后，项目有测试框架时要补一条不带修复就会失败的自动化回归测试（没有测试框架时补最接近的可执行检查）；条件允许时临时撤掉修复做一次变异检查，证明这条测试真的能拦住问题。没有可用框架时写明原因并作为未防护缺口报告。
- 新增 `docs/agent-instructions-snippet.md`：可直接粘贴到项目 `CLAUDE.md` / `AGENTS.md` 的中英文技能触发片段，以及在云端会话里把技能固定版本放进项目的做法。
- 新增 `docs/case-studies.md`：作者在多个项目中使用这套技能的真实记录（中文，附英文摘要）。
- 新增 Claude Code 插件市场清单 `.claude-plugin/marketplace.json`：`/plugin marketplace add tealun/Tealun-Skills` 后 `/plugin install tealun-skills@tealun-skills` 即可安装五个技能。技能目录位置不变，同步脚本照常可用。
- README 增加插件安装方式、「让 Agent 真的调用技能」指令片段和实战记录入口；新增英文版 `README.en.md`，两份 README 顶部互相链接。

## 现有技能

- `planner` 2.0.0
- `tasker` 1.8.5
- `auditor` 4.0.0
- `bugfixer` 1.6.0
- `evolver` 当前技能文件未声明版本
