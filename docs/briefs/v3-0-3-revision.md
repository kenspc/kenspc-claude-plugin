# Requirement Brief: v3.0.3 修补输入 —— task-implement Phase 转换 anchor 与 emergent 行为正式化

## Outcome

把 v3.0.2 在 DungeonDescent `pixel-font-pass` 端到端 dogfooding 中暴露的两类 prompt 工程缺陷修补，使本 plugin 在 **Phase 转换可靠性**、**emergent 好行为锁定**、**长期可维护性** 三方面进入下一稳定层。本次属于 **patch release**——不引入新 SKILL、新 agent、新 plugin 组件，只编辑现有 prompt 文件（SKILL.md / agent.md / hooks.json / scripts / CLAUDE.md）+ 版本号 bump。

修补范围共 9 项，按 ROI 分四档：P0（堵实证故障源头）2 项、P1（高复发性问题 + emergent 行为锁定）2 项、P2（emergent 锁定 + 反向通路自动化）2 项、P3（遥测 / 静态守护增厚 / 元教训沉淀）3 项。

## Scope

**In scope**——9 项修补对应的 prompt 文本编辑：

**P0**（必做，堵实证故障）：
1. `skills/task-implement/SKILL.md` Phase 1 Step 3 "Confirm with user" 升级为硬 gate（仅允许 batch 清单确认，禁止主动谈具体 task）
2. `skills/task-implement/SKILL.md` Phase 1 Step 5 后、Phase 2 完成前禁用跨 Phase 收口措辞（"整段落地"/"session 结束"/"workflow 收口" 等）

**P1**（应做，高复发 + emergent 锁定）：
3. `skills/generate-brief/SKILL.md` Phase 1 头加 system-reminder 冲突检测段（检测 "work without stopping" 类 reminder 时降级到 rapid-inferred mode + 强制 `Discovery Mode:` 字段标记）
4. `skills/task-implement/SKILL.md` + `skills/task-review/SKILL.md` 把 `CUSTOM_INSTRUCTIONS` 动态构造正式化（4 类 session 上下文：项目结构事实、风格倾向、session 内授权、跨文档语义约束）

**P2**（值得做，emergent 锁定 + 反向通路）：
5. `agents/regression-verifier.md` PROCESSING APPROACH 加"无测试工程项目 fallback 行为 spot-check"段
6. `skills/generate-task/SKILL.md` Phase 3 Step 3 加 Plan-Level Concerns 非空时主动建议 `/kenspc-plan {original-path}` 复跑

**P3**（长期价值）：
7. `hooks/hooks.json` + 新 SessionEnd 脚本（纯遥测，写 `~/.claude/kenspc/missed-reviews.log`，零干扰用户）
8. `scripts/check-canonical-dispatch.sh` 升级为 byte-identity + 关键 anchor 词组频次断言双重检测
9. 顶层 `CLAUDE.md` 加 "Phase 转换靠 artifact 不靠措辞" + "Hook 适合环境约束 / 事后遥测、不适合工作流状态机守护" 两条元教训段

**附属维护**：
- `plugins/kenspc/.claude-plugin/plugin.json` `version`: 3.0.2 → 3.0.3
- `.claude-plugin/marketplace.json` 同步 bump
- `plugins/kenspc/CHANGELOG.md` 加 v3.0.3 段（列 9 项修补 + Stop hook 误判作为元教训）
- `docs/release-checklist.md` 跑一遍（视情况增补：端到端 trace 验证一项）

**Out of scope**：
- 任何 SKILL 重构——不动 Phase 数量、不改 Schema 名称（A/B/C/D/E/F/G 保持）、不重排 SKILL 顺序
- 任何 agent 重构——不动 CONTEXT 契约键名、不改 `effort:` 配置、不重写 PREREQUISITES/FILE COVERAGE/CUSTOM INSTRUCTIONS 三段共享文本
- 新增任何 SKILL、agent、command 或 shared 文件
- `shared/discovery-framework.md` 内容改动
- plugin 目录结构调整（agents/ skills/ commands/ hooks/ shared/ references/ 位置不变）
- v3.0.3 行为的自动化端到端测试 harness（trace 自动 replay 等）

**Deferred**（建议 v3.0.4 或更晚，不是承诺）：
- SKILL 行为的真实 trace 自动 replay 测试框架
- `task-implementer` subagent 是否应支持"manual Phase 1 mode"的官方契约——本次只用 P0.1 Step 3 硬 gate 防止 manual 模式发生在 batch 入口下，**不正式支持双模式**
- 跨 plugin 复用的 "Phase 转换 anchor 模式" 做成 `shared/phase-transition-anchor.md` 文件
- 第三方 plugin 作者向导（如何在自己的 plugin 里复用 v3 设计哲学）

## Failure Modes

按风险高到低：

**F1 · 把 prompt 改动当代码改动做**。本次修补全部是 prompt 文本编辑——失败模式不是"代码逻辑 bug"，而是 **anchor 强度不够**、**措辞间冲突**、**artifact 强制契约未落实**。用代码 review 的 mindset（看 diff、跑 build、跑测试）做不出对的判断；要用 prompt 工程的 mindset：**模型读这段 prompt 时，在何种上下文压力下还会按指令做？anchor 词组出现的位置和频次是否够强？措辞与本 SKILL 其他段是否互斥？**。F1 在本 brief 起草过程中被用户两次显式提醒（"这是 plugins、skills 和 agents，不是程式代码"），elevated 到顶部。

**F2 · P0 改完没人真的跑一次端到端验证**。v3.0.2 失败的根因正是 **static guard 通过 ≠ runtime 守得住**。如果 v3.0.3 改完只跑 `check-review-agent-drift.sh` + `check-canonical-dispatch.sh` + 三个 JSON `python -m json.tool`，等于复刻同一种盲区。必须在真实项目跑一次完整 `/kenspc-brief` → `/kenspc-plan` → `/kenspc-task` → `/kenspc-task-implement` 链路，并人工验证 trace 显示三件事：
- Phase 2 在 Phase 1 主会话交互式完成后**自动触发**（无需用户问"跑完了吗？"）
- 收口措辞在 Phase 2 dispatch 之前**真被守住**（"整段落地"等词不出现）
- generate-brief 在带 "work without stopping" reminder 的 session 下**真输出降级声明**

**F3 · 把 emergent 好行为锁过死**。`CUSTOM_INSTRUCTIONS` 动态构造在 DungeonDescent trace 跑得好的关键，是主会话有自由度去识别 session 上下文里**哪些**该折进 prompt。如果 v3.0.3 把它写成"必须按 4 类信息填表"的机械模板，反而让模型在没有这些信息的项目里**强行编内容**或**留空表头**。正式化措辞要走 "consider folding ... when applicable"，不走 "must fold ..."；并显式列出"若 4 类都不适用则回落到 'N/A'"。

**F4 · 改 SKILL 时引入新的 anchor 冲突**。P0.2 "禁用收口措辞" 与 SKILL 现有 Phase 1 Step 5 模板里的 "Implementation phase complete." 直接冲突——SKILL 自己叫模型说 "complete"。修这一处时必须**同时改 Step 5 措辞**（如改为 "Implementation phase summary"），否则模型在两个互斥指令间会随机倾向其一。每条 P0/P1 编辑必须自检：**新措辞是否与现有 SKILL/agent 文本任意段产生新冲突**。F4 是本次 9 项里最容易被忽略的工程层风险——所有改动都要做这步自检。

**F5 · 误改 byte-identity 守护下的共享段**。5 reviewer agent 的 PREREQUISITES / FILE COVERAGE / CUSTOM INSTRUCTIONS 三段被 `check-review-agent-drift.sh` 锁定 byte-identity；`task-implement/SKILL.md` 与 `task-review/SKILL.md` 的 `<!-- canonical:dispatch:start -->` ~ `<!-- canonical:dispatch:end -->` 块被 `check-canonical-dispatch.sh` 锁定。P0/P1 的 SKILL 编辑应**全部位于 canonical 块之外**（Phase 1 Step 3/5、Phase 2 Step 1）；若手滑把改动写进 canonical 块，两个 SKILL 必须同步改、且 P3.2 的 anchor 词组检测也要同步更新。

**F6 · 版本号 / CHANGELOG 漏 bump 或不同步**。`plugin.json`、`marketplace.json`、`CHANGELOG.md` 三处版本必须同步；`docs/release-checklist.md` 已存在——必须按它跑一遍 smoke test 才能发版。任何一处不同步会导致用户安装时 plugin 自报版本与 marketplace 显示版本不一致，定位极难。

**F7 · P3 项被一并拖入 P0/P1 节奏**。P3 是长期价值项，可以在 v3.0.3 不做、留 v3.0.4。但 prompt 工程产品的常见陷阱是"既然都在改 SKILL 了，顺手把 CLAUDE.md 也改了吧"——这会让单版改动面扩大、引入 F4 风险。P3 应**显式作为可选**，由实施者根据时间预算决定是否纳入本版。

**显式接受的失败（不算 failure）**：
- v3.0.3 仍没有 SKILL 行为的自动化端到端测试——deferred 项，接受继续靠人工 dogfooding
- 部分 P3 项（SessionEnd 遥测 hook、CLAUDE.md 元教训）对当次 session 用户毫无可感收益——价值在下一次 plugin 迭代或新 plugin 作者复用时
- v3.0.3 不会让 v3.0.2 已生成的 brief/plan/task 文档作废——所有改动只影响**新调用 SKILL** 的行为，旧文档原样可用

## The Hard Part

最难的不是写 prompt，是**判断该锁什么、不该锁什么**。本版有四个具体的判断难点：

### 判断 1 · P0.2 "禁用收口措辞" 与 Step 5 模板冲突的调和

SKILL 自己的 Phase 1 Step 5 模板里写着 "Implementation phase complete."——这是合法的 Phase 内宣告。P0.2 要禁的是 **跨 Phase 总结性** 措辞（如"Step 2 of 3 整段落地"、"workflow 收口"、"session 结束"），不是 Phase 内的 progress update。

**倾向方案**：把 P0.2 的禁用清单**窄化定义**为"任何暗示整条 `/kenspc-task-implement` 已完成的措辞"——保留 Phase 1 内的 "Implementation phase complete." 不禁，但禁止任何把 Phase 1 包装成"整体完成"的延伸表述。措辞示例（plan 阶段细化）：
- 禁：跨 Phase 总结、`Step N of M` 类里程碑措辞、`✓ ... 落地` 类成就型措辞、`session 结束`、`workflow 收口`
- 允许：Phase 内进度（"Implementation phase complete. Proceeding to code review."）、Phase 转换指示（"Proceeding to Phase 2."）

边界要清晰，否则模型踩雷。Plan 阶段必须把禁用清单**逐词列**到 SKILL Phase 1 Step 5 后段。

### 判断 2 · CUSTOM_INSTRUCTIONS 动态构造的"该折什么"边界

4 类 session 上下文（项目结构事实、风格倾向、session 内授权、跨文档语义约束）是 DungeonDescent trace 实证有效的；但新项目不一定有这 4 类。

**倾向方案**：正式化措辞用 conditional fold，**不强制填表**：

```markdown
CUSTOM_INSTRUCTIONS construction:
- Default: "N/A".
- Override only when the session has accumulated any of:
  - Project structural facts not yet in CLAUDE.md (e.g., no test project, no lint config).
  - User-authorized session-scoped permissions (e.g., auto-commit, auto-push).
  - Cross-document narrative anchors (e.g., F1 phrase from a brief).
  - Style preferences expressed in conversation (e.g., hobby pace, surgical fixes).
- Fold applicable items into 2-4 sentences in CUSTOM_INSTRUCTIONS body.
- If none of the four categories apply to this session, retain "N/A".
```

关键是 "**only when** ... applicable" + "**If none apply**, retain N/A"——避免模型为了填表而编。

### 判断 3 · generate-brief Discovery 冲突检测的"降级 vs 拒绝"二选

检测到 `<system-reminder>` 类 "work without stopping" 措辞时，两个走向：

- **方案 A · 降级 + 显式标记**：进入 rapid-inferred mode，brief Discovery Notes 段写 `Discovery Mode: rapid-inferred (reminder-driven)`，brief 内容里所有非直接来自 ROUGH_IDEA 的字段都标 `[Inferred from project context: ...]` 或 `[Inferred from prior session: ...]`
- **方案 B · 拒绝运行 + 推荐改走 `/kenspc-plan`**：告知用户冲突、建议直接走 plan（plan 的 Discovery 对 reminder 更宽容，因为 plan 输入通常已经更结构化）

**倾向方案 A**——用户已经触发了 `/kenspc-brief`，强制拒绝运行会让体感糟糕；rapid-inferred mode + 显式标记是诚实且不打断流程的折中。但 Discovery Notes 段必须有**强制字段** `Discovery Mode: full | rapid-direct | rapid-inferred (reminder-driven)`，否则降级输出与正常输出在视觉上无差，无法事后追溯。

**额外约束**：要区分两种合法的 rapid mode：
- `rapid-direct`：输入 Level 1（如本 brief，输入已高清晰），Discovery 合法压缩——**不是失败**
- `rapid-inferred (reminder-driven)`：被 system-reminder 撬开，靠推断填字段——**降级输出，需显式标记**

P1.1 的措辞必须让模型能识别这两种 mode 的差别，不能把所有"不做 Discovery"的情况都归为降级。

### 判断 4 · 何时算"修补完毕、可以发 v3.0.3"

v3.0.2 失败的元教训就是 "byte-identity 守护通过 ≠ runtime 正确"。v3.0.3 的发版门槛设计：

- **必要条件**（全做完才可发）：
  - 静态守护全过（4 个 JSON parse + 2 个 byte-identity 脚本）
  - `docs/release-checklist.md` 列的 smoke test 全跑过
  - **在一个非 DungeonDescent 项目上**跑完一次 brief→plan→task→implement→review 完整链路（端到端 trace 验证），trace 显示 P0.1+P0.2 起作用、generate-brief 降级声明真出现
  - `plugin.json` / `marketplace.json` / `CHANGELOG.md` 版本号同步
  - git commit 全部使用 conventional commit prefix
- **倾向条件**（最好做到）：
  - 端到端验证用一个**全新空项目**（如 `dotnet new console` + 一个虚构特性请求）——避免在 DungeonDescent 重复跑时 cache hit 或人为 prompt-engineering DungeonDescent 用例的副作用
  - 至少做完 P0 + P1（4 项）才发版；P2/P3 可分批合入或纳入下个 patch

端到端验证是关键——它替代了 v3.0.3 没有的自动化测试 harness。

## Constraints

**技术约束**：
- 本次只编辑 prompt 文本和 hook 脚本——不动 plugin 目录结构、不新增组件、不引入新依赖
- 所有 `${CLAUDE_PLUGIN_ROOT}` portable path 引用保持不变
- byte-identity 守护脚本（`check-review-agent-drift.sh`、`check-canonical-dispatch.sh`）必须仍 pass——若 P1.2 改动导致 canonical 块漂移，要么不改、要么两个 SKILL 同步改
- agent 的 `effort:` 配置不动；SKILL 的 `effort:` 配置不动——本次不调整 reasoning 深度（trace 已实证 v3.0.2 的 effort 配置成立）
- agent 的 CONTEXT 契约**键名不动**；新增字段内容（如 P1.2 的 `CUSTOM_INSTRUCTIONS` 动态填充）走现有字段，不引入新键
- 不引入新依赖（hooks 脚本如果要写，用 plain bash / POSIX sh，不引入 Python / Node 运行时依赖）

**版本约束**：
- `plugins/kenspc/.claude-plugin/plugin.json` `version`: 3.0.2 → 3.0.3
- `.claude-plugin/marketplace.json` 对应条目同步 bump
- `plugins/kenspc/CHANGELOG.md` 加 v3.0.3 段（patch release，列 9 项修补 + Stop hook 误判讨论作为元教训）
- 不允许 v3.0.3 包含 minor / major 级别改动——保持 3.0.x patch 节奏，新 SKILL 或破坏性改动留给 3.1.0+

**质量约束（v3 设计规则继承）**：
每条改动必须遵循 CLAUDE.md 已确立的 v3 设计五条规则：
1. Workflow SOP stays
2. Rationale-anchored business rules（"why" 框架，不是命令式 imperative）
3. DONE-criteria over step-by-step flow
4. No anti-rationalization scaffolding
5. Plain language over MUST / NEVER / CRITICAL / ULTRATHINK

**禁用措辞**：不允许引入 MUST / NEVER / CRITICAL / IMPORTANT / ULTRATHINK / ABSOLUTELY 类强语气词。这是 v3 design rule 5——违反等于回退到 v2 风格。P0/P1 的强 anchor 措辞要靠**位置、重复频次、artifact 强制契约**实现，不靠强语气词。

**自检约束**：每条 SKILL/agent 改动落地前必须做 F4 自检——逐条问"这个新措辞与本 SKILL/agent 其他段是否存在 anchor 冲突？"。冲突清单作为 plan 阶段的输出之一。

**验证约束**：
- 静态守护必须全过
- `docs/release-checklist.md` 列的 smoke test 必须全跑
- **至少一次端到端 trace 验证**——非 DungeonDescent 项目

**时间约束**：
- hobby 节奏，无硬截止
- 修补节奏建议：P0 一组（2 项一起改完一次 smoke + 端到端）→ P1 一组 → P2 一组 → P3 一组——每组独立可停手、可发版；不强求 9 项必须同版

## Context

**v3 系列的位置**：
- v3.0.0 引入"11 个可复用 subagent + author/reviewer effort asymmetry + Schema 规范化"三大架构改进
- v3.0.1 / v3.0.2 是 patch 级修补（CHANGELOG 可查具体内容）
- v3.0.3 是本仓**首次基于真实端到端 trace 证据**做的修补——之前的 patch 多是文档对齐、anchor 措辞优化，没经过具体故障 trace 校验

**DungeonDescent 试用的位置**：
- 该试用是 v3.0.2 第一次完整跑通 brief→plan→task→implement→review→push 流水线的 dogfooding
- trace 完整保存在 `\\wsl.localhost\Ubuntu-24.04\home\kenspc\.claude\projects\-home-kenspc-projects-DungeonDescent\4b594f65-...jsonl`（3.3 MB）+ `subagents/` 目录（9 个 agent 各自独立 jsonl，约 1.4 MB 合计）
- pixel-font-pass 是 DungeonDescent visual polish 三步走的第二步（step 1 palette-brogue-pass 已发；step 3 animation 暂搁）
- 这条 trace 的独特价值：**首次暴露 "Phase 转换 anchor" 这类架构级缺陷**，不只是文案漂移层的问题——值得作为 v3.0.3 修补的实证依据保留引用

**plugin 设计哲学的位置**：
- v3 的 5 条设计规则源于 v2 的过度 MUST/NEVER 语气导致 SKILL 失去 self-rationalization 能力的反思
- "Phase 转换靠 artifact 不靠措辞" 是本次复盘新提炼的**第 6 条候选规则**——v3.0.3 P3.3 把它落入 CLAUDE.md 作为长期沉淀
- "Hook 适合环境约束 / 事后遥测、不适合工作流状态机守护" 是 Stop hook 误判讨论中提炼的边界——值得作为 "Plugin Design Non-Goals" 段在 CLAUDE.md 提一句

**本 brief 起草会话中已发生的关键决策**：
- 上一轮（Stop hook 段）用户问"Stop hook 不会误判？"——这次问询让我们**删掉**了原 P2 的 Stop hook 项，改成 P3 的 SessionEnd 纯遥测。这个修正本身是 v3.0.3 brief 的输入证据之一——v3.0.3 的设计已经过一轮用户校验，rebatch 后才落入本 brief
- 用户两次显式说"这是 plugins、skills 和 agents，不是程式代码"——这条提醒被 elevated 为本 brief 的 F1，并在 The Hard Part 全段以"prompt 工程视角"贯穿

**Author 与 plugin 关系**：
- Author（Sim Poh Chuan / kenspc）同时是本 plugin 的开发者和本次 DungeonDescent dogfooding 的用户——v3.0.3 是 author-as-dogfooder 模式下迭代的产物，没有外部用户反馈渠道介入
- 这点对 brief 解读有意义：v3.0.3 不需要照顾外部用户兼容性 surprise，但**需要**保持 trace 复现能力——同一个 author 下次用 v3.0.3 重跑同类项目时应能得到对得上的体感

## Discovery Notes

**Input clarity = Level 1**（输入高清晰）。9 项修补在本对话上方已枚举、ROI 排过两次、Stop hook 误判讨论已校正完成。按 `${CLAUDE_PLUGIN_ROOT}/shared/discovery-framework.md` 的 Level 1 处理规则（1-2 rounds 即可），Discovery 阶段被合理压缩。**Discovery 不是被 system-reminder 抹掉的**——是因为输入本身已超过 Discovery 所能添加价值的临界点。

**Discovery Mode**: `rapid-direct`（Level 1 触发的合法快进，**不是** system-reminder 强制跳过；区别详见 The Hard Part 判断 3）

**会话中暴露的元层问题（与本 brief 内容自指）**：
- 本会话顶部带 "work without stopping" system-reminder——这正是 P1.1 要解决的同类冲突
- 但本次 brief 的 Discovery 跳过**是合法的 Level 1 快进**，不是被 reminder 撬开的 Discovery 失败——重要区分
- v3.0.3 P1.1 改动后，本次 brief 在新版下应能正常输出（输入仍 Level 1 + 显式声明 `rapid-direct` mode）——P1.1 契约必须支持这种合法快进，不能误伤 Level 1 输入

**已显式接受的未问出项**：
- 没问"v3.0.3 发版时间窗口"——用户多次表达 hobby 节奏，无截止
- 没问"是否所有 9 项都进 v3.0.3"——按 ROI 排序的暗含约定是"做多少看时间"，brief 只锁定优先级和文件粒度，不锁定批量边界
- 没问"v3.0.3 后是否立刻进 v3.0.4 规划"——本 brief 只覆盖 v3.0.3 输入；后续版本规划是独立 brief 的事
- 没问"端到端验证的目标项目具体是哪个"——留 plan 阶段决定（倾向新建最小项目，详见 The Hard Part 判断 4）

**被 deprioritize 的备选**：
- **拆成 v3.0.3 + v3.0.4 两版发**：拒绝。9 项总改动量小（估计 ~150 行 prompt 文本 + ~30 行 hook 脚本 + 3 个 JSON / 1 个 CHANGELOG 段 bump），单版承载合理；拆版反而增加版本号管理负担。但**允许实施时按 P0→P1→P2→P3 顺序分批 commit，单版本内分组发布**
- **P0 单独发 v3.0.3-patch.1、其他延后**：拒绝。同上
- **不做 P3 元教训沉淀**：可接受但不优。沉淀越早做、未来写新 SKILL 时遗忘越少；CLAUDE.md 元教训段一旦漏过版本就容易永久遗忘
- **把"端到端验证"列为 v3.0.3 必要条件之外**：拒绝。这恰恰是 v3.0.2 失败的根因（static guard 通过未必 runtime 守住），列为必要条件不可商量

**未明确决策项（plan 阶段处理）**：
- 端到端验证用哪个目标项目（DungeonDescent step 3 animation / 新建最小项目 / 其他既有项目）——倾向**新建最小项目**避免历史 prompt-engineering 污染
- `CUSTOM_INSTRUCTIONS` 动态构造的 4 类信息清单在 plan 阶段是否扩展或收窄
- P0.2 收口措辞禁用清单的**具体词条范围**（"完成" / "落地" / "收口" / "session 结束" / "整段交付" / "milestone landed" 边界在哪——见 The Hard Part 判断 1）
- SessionEnd 遥测 hook 的日志**格式选择**（CSV / JSON-lines / 自由文本）
- P3.2 静态守护脚本升级时，"关键 anchor 词组"具体列表（"unconditional" / "5 subagents in a single message" / "workflow contract" / 其他？）
- v3.0.3 发版后是否更新 plugin 仓 README.md 的 "What's New" 段——目前 README 不强调版本号，可选

**本 brief 的元自指特点**：
本 brief **同时是** v3.0.3 的输入 **和** v3.0.3 修补后 generate-brief 应能正确处理的输入样本——具有自验证性质。如果 v3.0.3 改完后重跑本 brief 的 ROUGH_IDEA 输入，generate-brief 应输出结构几乎相同的 brief（本次修补不改 brief 模板，只加 Discovery Mode 字段和 rapid-inferred 检测）。这条自指可作为 v3.0.3 端到端验证的**轻量补充检查**——但**不替代** Constraints 中要求的"在非 DungeonDescent 项目上跑完整链路"这条主验证。

**本 brief 写完后的下一步**：
按 generate-brief Phase 3 约定，brief 不自动触发 plan。建议下一步：

```
/kenspc-plan docs/briefs/v3-0-3-revision.md
```

由 generate-plan 把本 brief 的 9 项修补展开为具体 Implementation Steps（包括 The Hard Part 列出的 4 个判断在 plan 阶段的细化措辞、Constraints 中的自检流程操作化），plan 阶段还会触发 `plan-document-reviewer` 自动评审——按 v3.0.2 的设计本身就是 brief→plan 接力的标准下一步。
