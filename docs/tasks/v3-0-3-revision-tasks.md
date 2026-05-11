# v3.0.3 修补输入 — Task Document

## Context

Decomposed from [docs/plans/v3-0-3-revision.md](../plans/v3-0-3-revision.md).
Source brief: [docs/briefs/v3-0-3-revision.md](../briefs/v3-0-3-revision.md).

**关键提示**：本任务集是 **prompt 工程修订**——编辑 SKILL/agent 文本、hooks 脚本、版本号文件——**不是程式代码改动**。失败模式不是"代码逻辑 bug"，而是 anchor 强度不够、措辞间冲突、artifact 强制契约未落实。每条 Task 都附带 plan 原 **F4 Conflict Self-Check** 字段，是该任务的强制验证条目。

**Discovery / Task 拆解 Mode**: rapid-inferred (reminder-driven) — 用户 session reminder 要求 "work without stopping for clarifying questions"，generate-task 在 Phase 2 跳过交互式确认，按合理推断直接落盘。Mode 选择本身体现了 plan P1.1 引入的同名 artifact 字段规则。

## Commit Strategy (binding to plan)

Plan 段 "Implementation Steps 依赖说明" 明示：每个优先级组一个 commit（共 4 个），加附属 bump 一个、验证记录一个，合计 **6 个 commit 上限**。任务编号与 commit 映射：

| Commit | Tasks | Conventional prefix | Notes |
|--------|-------|---------------------|-------|
| 1 | Task 1 (P0) | `fix:` | task-implement Phase 1 anchors |
| 2 | Task 2 (P1.1) + Task 3 (P1.2) | `feat:` | emergent behavior formalization |
| 3 | Task 4 (P2.1) + Task 5 (P2.2) | `fix:` | coverage gap fallbacks |
| 4 | Task 6 (P3.1) + Task 7 (P3.2) + Task 8 (P3.3) | `feat:` 或 `chore:` | long-term value |
| 5 | Task 9 (Aux.1) | `chore:` | version + CHANGELOG bump |
| 6 | Task 10 (Aux.2) | `docs:` | release-checklist + greenfield trace record |

**Commit message 附注要求**：
- 每个 commit message 在 body 列出该 commit 涉及任务的 F4 Conflict Self-Check 结论（plan 段 "Technical Approach" 已明示这是 commit message 附注内容）
- Task 3 (P1.2) commit message 要写清边界：本 commit 改的是**两个 SKILL dispatch 时如何填充 CUSTOM_INSTRUCTIONS 字段值**，不动 5 reviewer agent 的 "CUSTOM INSTRUCTIONS" 段（那是 byte-identity 锁定，不改）
- Task 2 (P1.1) commit message 要记 known asymmetry：generate-plan 不同步加 Mode Detection，留待 v3.0.4+

## Cross-Task Dependencies

- **Task 7 (P3.2) depends on Task 1 (P0)**：P3.2 的 anchor 词组频次断言 grep 需要在 P0.2 禁用清单落地后跑一遍当前 SKILL 文本，根据实测值定下限——所以 Task 7 必须晚于 Task 1 完成，但与同 commit-group 内的其它任务无依赖。
- **Task 9 (Aux.1) depends on Tasks 1-8**：版本号 bump 和 CHANGELOG 段必须在所有 prompt 修订落定后才写。
- **Task 10 (Aux.2) depends on Task 9**：端到端验证用的是已 bump 到 3.0.3 的 plugin 状态。

其他 task 间无顺序依赖；同 commit-group 内的任务可并行起手。

## Validation Strategy 速览

落地完成的判据不是 build/test pass，而是：
- 静态守护脚本全过（`check-canonical-dispatch.sh` 含新加 anchor 断言、`check-review-agent-drift.sh`、3 个 JSON 文件 `python -m json.tool`）
- 在新建 `dotnet new console` 最小项目跑完整 5-skill 链路，trace 上做 3 个 grep 串验证（详见 Task 10）
- `docs/release-checklist.md` smoke test 全过（含 Task 10 新增项）

详见 plan 段 "Validation Strategy"。

---

## Tasks

### Task 1: P0 · task-implement Phase 1 batch gate + closure wording boundary

**Status:** TODO

**Files:**
- `plugins/kenspc/skills/task-implement/SKILL.md` — modify

**改动一**（plan Step P0.1）— Phase 1 Step 3 "Confirm with user" 段（当前 line 99-113）升级为硬 gate：
- 仅允许 **batch 清单确认**（示例："以下任务我将依序实施：[task 1, task 2, ...]，OK？"）
- 禁止主动谈具体单一 task 的实现细节
- 给一个正例 + 一个反例对照（正例：batch 列表；反例：单 task 细节）

**改动二**（plan Step P0.2）— Phase 1 Step 5 后段加 "Closure Wording Boundary" 子段：
- 顶部一句话区分：`Phase-internal progress (allowed) ≠ workflow-level closure (disallowed)`
- 禁用清单（窄化为"任何暗示整条 `/kenspc-task-implement` 已完成的措辞"）：
  - 跨 Phase 总结型：`整段落地` / `整段交付` / `所有工作完成` / `workflow 收口` / `session 结束`
  - 里程碑措辞：`Step N of M 完成` / `✓ ... 落地` / `milestone landed`
  - 终态宣告：`Workflow complete.` / `All phases done.` / `All implementation is done.` / `Ready to wrap up.`
  - 兜底句：`and similar phrases that imply the entire /kenspc-task-implement invocation has finished`
- 允许保留（合法 Phase 内进度宣告）：`Implementation phase complete.`（line 149 既有模板保留不动） / `Proceeding to Phase 2.` / `Proceeding to code review.` / 单 task 完工提示
- Step 5 既有模板 `Implementation phase complete.` 措辞**保留不动**（合法 Phase 内宣告）

**位置约束**：两处改动必须在 canonical 块（line 199-226）**之外**——Step 3 与 Step 5 位置均符合。

**Acceptance criteria:**
- `bash scripts/check-canonical-dispatch.sh` 退出 0（编辑位置在 canonical 块外，应不触发 drift）
- `bash scripts/check-review-agent-drift.sh` 退出 0（本任务不动 5 reviewer agent）
- `cat plugins/kenspc/skills/task-implement/SKILL.md | grep -c "Implementation phase complete."` ≥ 1（既有模板措辞保留）
- 端到端 trace（Task 10 执行）显示 Phase 1 → Phase 2 衔接处不出现禁用清单任一词
- `Implementation phase complete.` 在 trace 中可出现（不是失败信号）
- Phase 2 自动触发（无需用户问"跑完了吗"）

**F4 Conflict Self-Check** (plan 强制条目；commit message 附注):
- 检查 Phase 1 既有 Step 1/2/4/5 是否含"提前谈具体 task"措辞——若有，同段修订
- 检查 Phase 2 起头处是否依赖 Step 3 的宽松措辞——若有，同步收紧
- grep 整文 `落地` / `收口` / `Step \d+ of` / `milestone` 关键词——既有 SKILL 文本若已出现禁用词，本次必须同步替换
- 检查 `task-review/SKILL.md`（canonical 块同步对象）是否含禁用词——本次复检确认 canonical 块内无禁用词（无需同步改），但若 canonical 块外有禁用词必须同步处理

---

### Task 2: P1.1 · generate-brief Discovery Mode Detection

**Status:** TODO

**Files:**
- `plugins/kenspc/skills/generate-brief/SKILL.md` — modify

在 `## Phase 1: Discover`（line 63）的 Goal/Inputs/DONE when/Constraints 块**之前**插入新 `### Discovery Mode Detection` 子段（plan 段 P1.1 提供完整文本）。该子段作为 Phase 1 开篇说明：

- 三模式表（`full` / `rapid-direct` / `rapid-inferred (reminder-driven)`），按 reminder 压力 + 输入清晰度区分
- 关键区分语：`rapid-direct` 是 Level 1 合法快进（非 degraded output）；`rapid-inferred (reminder-driven)` 是 degraded output（必须 visually distinguishable）
- 强制 artifact 契约：**所有 mode 下** brief Discovery Notes 段必须含 `Discovery Mode:` 字段——这是 artifact 层契约（schema 字段强制语义），不是行为强语气词

文本采纳 plan 段 P1.1 第 116-136 行的 markdown 块（含表 + 两段说明）。

**Known asymmetry**（commit message 必须记录）：本任务仅覆盖 generate-brief，不同步给 generate-plan 加 Mode Detection。理由：patch release 节奏 + generate-plan 输入通常更结构化、reminder 冲击面小。留待 v3.0.4+ 讨论。

**Acceptance criteria:**
- 文本编辑落在 Phase 1 既有 Goal 段**之前**，不破坏既有 Goal/Inputs/DONE/Constraints 结构
- 在新建 .NET 项目跑 `/kenspc-brief "a rough idea"`（无 reminder 干扰）→ 输出 brief 含 `Discovery Mode: full` 或 `Discovery Mode: rapid-direct`
- 在带 "work without stopping" reminder 的 session 跑 `/kenspc-brief` 输入 Level 2+ 内容 → 输出 brief 含 `Discovery Mode: rapid-inferred (reminder-driven)` + 推断字段带 `[Inferred from ...]` 标记
- 自指验证：本 brief（`v3-0-3-revision.md`）若重跑 ROUGH_IDEA 输入，新版 generate-brief 应输出 `Discovery Mode: rapid-direct`（Level 1 合法快进）
- 文本不含 `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` / `ABSOLUTELY` / `IMPORTANT` 类强语气词（artifact 字段语义如 "includes a `Discovery Mode:` field" 是 schema 强制，符合 plan Constraints 例外条款）—— 验证：`grep -nwE 'MUST|NEVER|CRITICAL|ULTRATHINK|ABSOLUTELY|IMPORTANT' plugins/kenspc/skills/generate-brief/SKILL.md` 在新增 Discovery Mode Detection 子段内无匹配

**F4 Conflict Self-Check** (commit message 附注):
- 检查 generate-brief Phase 1 既有 Step 1-3 是否假设"用户必然回答问题"——若有，措辞软化为 "if interactive Discovery applies"
- 检查 `shared/discovery-framework.md` 是否暗示 Discovery 必须 interactive——若有，加注 "see generate-brief Phase 1 Mode Detection"

---

### Task 3: P1.2 · CUSTOM_INSTRUCTIONS dynamic construction formalization (cross-SKILL atomic)

**Status:** TODO

**Files:** (atomic — both edited in same task / same commit-group as Task 2)
- `plugins/kenspc/skills/task-implement/SKILL.md` — modify
- `plugins/kenspc/skills/task-review/SKILL.md` — modify

在两个 SKILL 的 dispatch CONTEXT 块构造说明里加入 CUSTOM_INSTRUCTIONS construction 段。文本采纳 plan 段 P1.2 提供的 markdown 块（4 类清单 + N/A default + "only when ... applicable" 语义）。

**关键措辞设计**：`only when ... applicable` + `If none apply, retain N/A` —— 避免模型为填表而编内容（brief F3）。

**位置约束**：编辑**必须位于两个 SKILL 的 canonical 块之外**。实施前先跑：
```bash
grep -n CUSTOM_INSTRUCTIONS plugins/kenspc/skills/task-{implement,review}/SKILL.md
```
- `task-implement/SKILL.md`：CUSTOM_INSTRUCTIONS 出现在 Step 1（line 176-183 的 CONTEXT 构造，canonical 块外，安全）
- `task-review/SKILL.md`：CUSTOM_INSTRUCTIONS 出现在 Step 2（line 72-76，canonical 块外，安全）

**边界声明**（commit message 强制）：本任务改的是**两个 SKILL dispatch 时如何填充 CUSTOM_INSTRUCTIONS 字段值**——**不动** 5 reviewer agent 的 "CUSTOM INSTRUCTIONS" 段（那是 byte-identity 锁定的固定模板）。这条边界写进 commit message 防止误改。

**Acceptance criteria:**
- 两个 SKILL 的 CUSTOM_INSTRUCTIONS construction 段文本一致（不要求 byte-identity，但 4 类清单 + N/A 措辞需一致）
- 在新建 .NET 项目（无 reminder、无 brief 上下文）跑 `/kenspc-task-implement` → CONTEXT 块 `CUSTOM_INSTRUCTIONS: N/A`
- 在带 brief 的 session 跑（如本 v3.0.3 实施） → CONTEXT 块 CUSTOM_INSTRUCTIONS 折入 2-4 句相关条目（如 "参考 brief F1：prompt 改动非代码改动" + "v3 design rule 5: 不引入 MUST/NEVER 强语气"）
- `bash scripts/check-canonical-dispatch.sh` 退出 0（canonical 块未动）
- `bash scripts/check-review-agent-drift.sh` 退出 0（reviewer agent 未动）

**F4 Conflict Self-Check** (commit message 附注):
- 5 reviewer agent 的 "CUSTOM INSTRUCTIONS" 段是 byte-identity 锁定的固定模板——本任务**不改这段**，这一条边界要在 commit message 写清楚
- 检查 `agents/task-implementer.md` 是否有"必须有 CUSTOM_INSTRUCTIONS"硬假设——若有，软化为 "may be N/A"

---

### Task 4: P2.1 · regression-verifier SPOT-CHECK fallback (3-file atomic)

**Status:** TODO

**Files:** (atomic — all three edited in same task / same commit-group as Task 5)
- `plugins/kenspc/agents/regression-verifier.md` — modify（主改动）
- `plugins/kenspc/skills/task-review/SKILL.md` — modify（Step 7 Verdict determination 段加 SPOT-CHECK 第三态说明）
- `plugins/kenspc/skills/task-implement/SKILL.md` — modify（Phase 2 Step 4 Verdict determination 段加 SPOT-CHECK 第三态说明）

**改动一**（regression-verifier.md）—— **Plan-Level concern noted**：plan 段 P2.1 说"PROCESSING APPROACH 段加 fallback 子段"，但 regression-verifier.md 实际结构是 PREREQUISITE CHECK / CONTEXT YOU WILL RECEIVE / ROLE / OBJECTIVE / INPUTS / PREREQUISITES / DONE CRITERIA / **VERIFICATION CHECKS** / OUTPUT FORMAT——**没有 "PROCESSING APPROACH" 段**。落地处理：在 VERIFICATION CHECKS 段（既有 line 52-69，4 个 check）之后、OUTPUT FORMAT 段（line 71+）之前，新增一个 `FALLBACK FOR NO-TEST-SUITE PROJECTS` 段。文本采纳 plan 段 P2.1 提供的 markdown 块（"When the project has no test project / no `dotnet test` target / ... skip the test execution step and replace it with a fallback spot-check of the changed files: ..."）。

**改动二**（两 SKILL 的 Verdict determination 段）—— 在 PASS 规则后加一行（plan 段 P2.1 提供文本）：
```
- `SPOT-CHECK` from regression-verifier (no test suite available) is
  treated as neutral — it does not force FAIL; PASS may still apply
  if all other checks PASS and no HIGH issues remain. The Verdict
  paragraph should explicitly note "tests spot-checked due to no
  test suite" when this state is present.
```
- `task-review/SKILL.md` Step 7 Verdict determination 段在 line 235+（canonical 块 end 在 line 118，安全）
- `task-implement/SKILL.md` Phase 2 Step 4 Verdict determination 段在 line 284+（canonical 块 end 在 line 226，安全）
- 两段措辞**非** byte-identity 锁定（task-implement 多 BLOCKED 状态），新增 SPOT-CHECK 行只需符合各自既有结构，允许不同插入位置

**Acceptance criteria:**
- regression-verifier.md 含新增 `FALLBACK FOR NO-TEST-SUITE PROJECTS` 段，引用 Schema C 的 Result `SPOT-CHECK` 第三态值 + Detail 字符串 `no test suite — accountability list spot-checked instead`
- 两个 SKILL 的 Verdict determination 段含 SPOT-CHECK neutral 说明
- 在新建 `dotnet new console` 项目（无测试项目）跑 `/kenspc-task-review` → regression-verifier 不报"测试失败"，而是 Schema C 表 row 3 ("Tests pass") 输出 Result=`SPOT-CHECK` + Detail=`no test suite — accountability list spot-checked instead`，并完成 accountability 验证
- 在有测试项目的项目里行为不变（fallback 判定依据是检测不到 test target 而非"测试失败"）
- `bash scripts/check-review-agent-drift.sh` 退出 0（regression-verifier 不在 5 reviewer agent 锁定范围；本任务不动 5 reviewer agent）
- `bash scripts/check-canonical-dispatch.sh` 退出 0（两个 SKILL 的改动都在 canonical 块外）

**F4 Conflict Self-Check** (commit message 附注):
- `check-review-agent-drift.sh` **不**校验 regression-verifier——agent 改动安全（commit message 注明）
- 两 SKILL Verdict determination 段措辞**非** byte-identity 锁定，新增 SPOT-CHECK 行按各自既有结构插入
- 检查 `task-review/SKILL.md` Step 6 / `task-implement/SKILL.md` Phase 2 Step 3 是否硬假设 regression-verifier 一定跑 `dotnet test` / `npm test`——若有，同步软化为 "or report SPOT-CHECK if no test target detected"
- **Plan-level concern surfaced**：plan 提到的 "PROCESSING APPROACH" 段名与 agent 实际结构不匹配，落地处理是新增 `FALLBACK FOR NO-TEST-SUITE PROJECTS` 段——commit message 记一句"PROCESSING APPROACH 段名 plan 笔误，落地为新增 FALLBACK 段"

---

### Task 5: P2.2 · generate-task suggests /kenspc-plan re-run when Plan-Level Concerns non-empty

**Status:** TODO

**Files:**
- `plugins/kenspc/skills/generate-task/SKILL.md` — modify

Phase 3 Step 3（评审结果呈现）后加入 Conditional Suggestion 段。文本采纳 plan 段 P2.2 提供的 markdown 块：

```markdown
If the task-document-reviewer's output contains a non-empty
`## Plan-Level Concerns` prose section (i.e., the section body is
something other than the agent's fallback string "No plan-level
concerns found."), proactively suggest:

> Plan-level concerns detected. Consider re-running:
> `/kenspc-plan {original-plan-path}`
> to address these upstream issues before proceeding to implementation.

Do not auto-invoke /kenspc-plan; this is a recommendation, not a
re-dispatch. The user decides whether plan re-work is warranted.
```

**位置**：当前 generate-task/SKILL.md Phase 3 Step 3 段在 line 185-203。新增段加在 Step 3 末尾。

**Hidden dependency 已确认**：`task-document-reviewer.md` 已在 line 82-83、line 121-129 包含 `## Plan-Level Concerns` 段定义（含 fallback 字符串 "No plan-level concerns found."）——P2.2 纯 SKILL 改动，无隐含子任务。

**Acceptance criteria:**
- 在 task-document-reviewer 返回 Plan-Level Concerns 非空时，generate-task 末尾输出建议提示（带 `/kenspc-plan {path}` 命令模板）
- 在 Plan-Level Concerns 为空（agent 返回 fallback 字符串）时，**不**输出该建议（避免噪音）
- 不 auto-invoke `/kenspc-plan`（建议而非 re-dispatch）

**F4 Conflict Self-Check** (commit message 附注):
- generate-task Phase 3 当前无显式 "reviewer 失败 / 错误处理" 段（实测：Step 3 仅描述"render the result table verbatim"）——本建议作为新增 conditional 段，与既有内容无直接冲突
- 检查 Phase 3 Step 3 末尾的 "Below the table, present" 列表（line 197-203）是否与本建议段语义重合——本建议是触发性"复跑 plan"提示，与"render 结果"段为独立行为，加在 Step 3 末尾

---

### Task 6: P3.1 · SessionEnd telemetry hook

**Status:** TODO

**Files:**
- `plugins/kenspc/hooks/hooks.json` — modify（新增 SessionEnd 事件项）
- `plugins/kenspc/hooks/scripts/session-end-telemetry.sh` — **新文件**（bash 脚本）

**改动一**（hooks.json）—— 在既有顶层 `"hooks": { ... }` 对象内，与 `SessionStart` / `PreToolUse` 并列，加入 `SessionEnd` 键。matcher 用 `"*"`（与既有 `SessionStart` 一致，不要写 `".*"`）。文本采纳 plan 段 P3.1 提供的 JSON 块。

**改动二**（session-end-telemetry.sh）—— bash 脚本，shebang `#!/usr/bin/env bash` + `set -euo pipefail`（与既有 `check-deps.sh` / `remind-plan-skill.sh` 风格一致）。逻辑：
- 读 session metadata（环境变量 `CLAUDE_SESSION_ID` 等；实施前查 Claude Code hook context API 文档确认变量名；若变量不存在回退用 timestamp + PID 组合）
- 检测 session 中是否调用过 `/kenspc-task-implement` 但未调用 `/kenspc-task-review`
- 若是，append 一行 JSON Lines 到 `${HOME}/.claude/kenspc/missed-reviews.log`（含 timestamp / session_id / reason 字段）
- 路径展开用 `${HOME}` 而非 `~`（嵌入字符串内 `~` 不展开；`${HOME}` 在任何上下文展开。Windows Git Bash 下 `${HOME}` 展开为 `/c/Users/kenspc` 类路径）
- 文件不存在则 `mkdir -p` 创建父目录
- **零干扰**：不输出 stdout、不阻断 session 退出、所有错误吞掉（`2>/dev/null || true`）
- 脚本以 git mode `100644` 入库（与既有 hook 脚本一致，`hooks.json` 用 `bash <path>` 调用，无需 executable bit）

**Open question 转 sub-todo**：实施前需查 Claude Code hook context API 文档确认 `CLAUDE_SESSION_ID` / `CLAUDE_CODE_SESSION_ID` 等变量是否存在；若不存在回退用 `$(date -u +%Y-%m-%dT%H:%M:%S%z)-$$` 组合。

**Acceptance criteria:**
- `cat plugins/kenspc/hooks/hooks.json | python -m json.tool > /dev/null` 退出 0
- 新脚本以 git mode `100644` 入库（验证：`git ls-files -s plugins/kenspc/hooks/scripts/session-end-telemetry.sh` 显示 `100644`）
- 在新建 .NET 项目跑 task-implement 后**未跑** review，退出 Claude Code session 后 `${HOME}/.claude/kenspc/missed-reviews.log` 出现新 JSON Lines 行
- 跑 task-implement 后**跑了** review，**无**新行 append
- 用户体感零干扰（hook 静默运行，无 stderr/stdout 可见输出）
- Windows Git Bash 兼容：`${HOME}` 展开后路径创建成功（`/c/Users/kenspc/.claude/kenspc/` 目录存在）
- 脚本内不引入 Python/Node 依赖（纯 bash，与既有 hook 脚本一致）

**F4 Conflict Self-Check** (commit message 附注):
- 检查 hooks.json 既有事件项是否已有 SessionEnd 项——若有，merge（同事件下加入 hook，不覆盖）。实测当前 hooks.json 无 SessionEnd 项，直接新增
- 脚本路径用 `${CLAUDE_PLUGIN_ROOT}`（plugin 内引用）+ `${HOME}`（用户家目录）两个变量，不混淆

---

### Task 7: P3.2 · check-canonical-dispatch.sh anchor frequency dual check

**Status:** TODO
**Depends on:** Task 1 (P0)

**Files:**
- `scripts/check-canonical-dispatch.sh` — modify

当前脚本只做 sha256 byte-identity 检查（line 41-48）。升级为双重检测：
1. **byte-identity**：保留 sha256 当前逻辑不变（line 24-48 保留）
2. **anchor 词组频次断言**：在两个 SKILL（task-implement 与 task-review）的 canonical 块内，对若干关键 anchor 词组做出现次数下限检查

**实施前 grep 步骤**（必须在 Task 1 落地后执行——anchor 频次清单要反映 post-P0.2 的 SKILL 文本状态）：

```bash
grep -cE "unconditional|single message|5 subagents|automatically|in parallel" \
  plugins/kenspc/skills/task-implement/SKILL.md \
  plugins/kenspc/skills/task-review/SKILL.md
```

根据实测计数定下限。

**候选词组清单**（plan 段 P3.2 提供；实测后可微调）：

| 词组 | 期望下限 | 理由 |
|---|---|---|
| `unconditional` | ≥ 1 次 | Phase title 词，标志"无条件 dispatch review"语义 |
| `single message` 或 `in a single message` | ≥ 1 次 | 并行 dispatch anchor |
| `5 subagents` 或 `five subagents` | ≥ 1 次 | 数量约束 anchor |
| `automatically` 或 `auto-` 前缀 | ≥ 1 次 | 不依赖用户主动触发的 anchor |

Open question（plan #1，实施时定）：具体下限数字按 grep 实测——可能差异化（如 `single message` 至少 2 次因为是关键并行 anchor）。

**Acceptance criteria:**
- 当前两个 SKILL 跑新脚本 → exit 0
- 故意改一个 SKILL 删掉 `unconditional` 词 → 脚本 exit 非 0 + 报错指出哪个词在哪个 SKILL 缺失（错误信息须明确列出文件名 + 缺失词组）
- 在 CI / pre-commit 触发时也能跑（不依赖交互输入）
- 兼容现有 `git pre-commit` 钩子集成（如已有；release-checklist 第 28 行已列入 pre-flight）
- 脚本保留 sha256 byte-identity 逻辑不变（双重检测，不是替换）

**F4 Conflict Self-Check** (commit message 附注):
- `check-review-agent-drift.sh` 与本脚本职责分离——本任务不动它
- anchor 词组若与 P0.2 禁用清单有交叉（理论上不会，禁用清单是"收口"词、anchor 是"工作流"词），实施前逐词比对确认

---

### Task 8: P3.3 · CLAUDE.md two design lessons

**Status:** TODO

**Files:**
- `CLAUDE.md`（项目根） — modify

在既有 `## Skill Development Conventions` 章节末尾或独立新节 `## Plugin Design Lessons (Cumulative)` 加入两条元教训。文本采纳 plan 段 P3.3 提供的 markdown 块（"Phase transitions rely on artifacts, not wording" + "Hooks are for environment constraints and post-hoc telemetry, not workflow state-machine guarding"）。

每条教训含三部分：标题 / 正文 / `Background:` 短句（援引 v3.0.2 trace 或早期 v3.0.3 设计踩坑）。

**Acceptance criteria:**
- CLAUDE.md 渲染正常（markdown 语法不破）—— 验证：`python -c "import re; t=open('CLAUDE.md').read(); assert '## Plugin Design Lessons' in t"` exit 0
- 两条教训在文件中可被未来 SKILL/agent 设计 review 时引用
- 文本本身遵守 v3 设计规则 5：不引入 `MUST` / `NEVER` / `CRITICAL` / `ULTRATHINK` / `ABSOLUTELY` / `IMPORTANT` 词（"Avoid using" 替代 "Do NOT use"）—— 验证：`grep -nwE 'MUST|NEVER|CRITICAL|ULTRATHINK|ABSOLUTELY|IMPORTANT' CLAUDE.md` 在新增段内无匹配（既有 CLAUDE.md 内容不在本任务范围）

**F4 Conflict Self-Check** (commit message 附注):
- 检查既有 CLAUDE.md `### Non-Goals` 段是否与"hook 边界"教训互补不互斥——Non-Goals 谈的是 `shared/discovery-framework.md` 不下沉为 agent，与 hook 边界教训正交，无冲突

---

### Task 9: Aux.1 · version bump + CHANGELOG entry

**Status:** TODO
**Depends on:** Tasks 1-8

**Files:**
- `plugins/kenspc/.claude-plugin/plugin.json` — modify（`"version": "3.0.2"` → `"3.0.3"`）
- `plugins/kenspc/CHANGELOG.md` — modify（在 line 3 即 `## 3.0.2 — 2026-05-06` 之上插入 v3.0.3 段）
- `.claude-plugin/marketplace.json` — **保持现状不动**（实测仅含 `name` / `description` / `source` 三键，无 `version` 字段；marketplace 注册摘要的版本号由 `source` 指向的 `plugin.json` 提供，两层故意分层）

**CHANGELOG v3.0.3 段大纲** 采纳 plan 段 Aux.1 提供的 markdown 块（含 4 个小节：P0 / P1 / P2 / P3 + Meta-lessons + Known asymmetry）。

**Acceptance criteria:**
- `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null` exit 0
- `cat .claude-plugin/marketplace.json | python -m json.tool > /dev/null` exit 0
- `python -c "import json; m=json.load(open('plugins/kenspc/.claude-plugin/plugin.json')); assert m['version']=='3.0.3'"` exit 0
- `python -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); assert 'version' not in m['plugins'][0]"` exit 0（验证 marketplace 注册仍无 plugin 级 version 字段）
- CHANGELOG v3.0.3 段在 v3.0.2 段**之上**（最新版在最前）
- CHANGELOG 含 "Known asymmetry (deferred to v3.0.4+)" 子节，注明 generate-plan 不同步加 Mode Detection

**F4 Conflict Self-Check** (commit message 附注):
- marketplace.json 是注册表，不带 plugin 级 version——commit message 注明"marketplace.json 不参与 bump，是注册表分层设计"，避免下一轮 review 误判漏 bump
- CHANGELOG 顺序：当前文件 newest 在 line 3，bump 后 v3.0.3 段插在 line 3 之上（即新 line 3-N），既有 v3.0.2 段顺移

---

### Task 10: Aux.2 · end-to-end greenfield trace verification + release-checklist update

**Status:** TODO
**Depends on:** Task 9

**Files:**
- `docs/release-checklist.md` — modify（在 Smoke checklist 表格末尾新增一项）
- `docs/traces/v3-0-3-greenfield.md` — **可选新文件**（端到端 trace 摘录；hobby 节奏不强制；plan Open Question #3 列为非阻塞）

**改动一**（release-checklist.md）—— 不修改既有 pre-flight + smoke checklist 内容；在表格（line 48-56 范围内的 markdown 表格）末尾新增一行：

| # | Check | Pass criterion |
|---|---|---|
| 9 | End-to-end trace verification on greenfield project (non-DungeonDescent) | Phase 2 auto-triggers without user prompt; no closure-wording disablelist words appear in trace; `Discovery Mode:` field present in brief output |

**改动二**（端到端 trace 验证执行）—— 在新建 `dotnet new console` 最小项目跑完整链路：
```
/kenspc-brief → /kenspc-plan → /kenspc-task → /kenspc-task-implement → /kenspc-task-review
```

虚构特性请求：`add a CLI flag --greeting that prints a custom greeting`（plan Plan-Stage Decisions 第一行已建议）

**人工 trace grep 三个具体串**（plan 段 Validation Strategy 第 3 项）：

| 验证点 | grep 串 | 期望结果 |
|---|---|---|
| Phase 2 自动触发 | `Proceeding to Phase 2` 或 `Proceeding to code review` | 在 Phase 1 Step 5 之后**自动**出现（不是用户问后才出现） |
| 收口禁用守住 | `整段落地` / `session 结束` / `workflow 收口`（3 个最常踩词） | 在 Phase 2 dispatch 前**零出现** |
| Discovery Mode 字段 | `Discovery Mode:` | 在 brief 输出中**真出现**，值为 `full` / `rapid-direct` / `rapid-inferred (reminder-driven)` 之一 |

建议端到端验证里专门跑一段带 "work without stopping" reminder 的 brief 生成子 session，验证 `rapid-inferred (reminder-driven)` 路径。

**Acceptance criteria:**
- release-checklist.md 表格末尾含新增第 9 行（pass criterion 完整）
- 在新建 `dotnet new console` 项目跑完整 5-skill 链路，3 个 grep 串验证全过
- 静态守护全过：
  - `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool` exit 0
  - `cat plugins/kenspc/hooks/hooks.json | python -m json.tool` exit 0
  - `cat .claude-plugin/marketplace.json | python -m json.tool` exit 0
  - `bash scripts/check-review-agent-drift.sh` exit 0
  - `bash scripts/check-canonical-dispatch.sh` exit 0（含 Task 7 新加的 anchor 频次断言）
- 既有 smoke checklist 第 1-8 项也跑过
- `docs/traces/v3-0-3-greenfield.md`（可选）若落地，记录端到端 trace 关键段（brief Discovery Mode 字段值、task-implement Phase 1→2 衔接句、task-review Schema F verdict）

**F4 Conflict Self-Check** (commit message 附注):
- release-checklist.md 既有 8 行表格不动，仅末尾新增 1 行
- 端到端 trace 文件若落地，路径 `docs/traces/`（与 `docs/plans/` / `docs/briefs/` 同级）；docs 目录的 listing 不变更（新建 traces/ 子目录是 docs 既有约定的自然扩展）

---

## Notes

### Validation gates (plan 段 Validation Strategy 必要条件)

落地完成判据（按 plan 段 "必要条件" 5 项）：

1. **静态守护全过**：3 个 JSON 文件 `python -m json.tool` + `check-review-agent-drift.sh` + `check-canonical-dispatch.sh`（含 Task 7 新加 anchor 频次断言）
2. **release-checklist smoke test 全过**（含 Task 10 新增第 9 行）
3. **端到端 trace 验证**（Task 10 详）—— 3 个 grep 串全过
4. **版本同步**：plugin.json 3.0.3 + CHANGELOG v3.0.3 段；marketplace.json 保持现状不动
5. **git commit 全用 conventional commit prefix**（`fix:` / `feat:` / `docs:` / `chore:`）

### Risk recap (plan 段 Risks and Mitigations 摘要)

| Risk (brief F#) | 任务级缓解 |
|---|---|
| F1 · 把 prompt 改动当代码改动做 | 每条 Task 含 F4 Conflict Self-Check；commit message 附冲突清单；Task 10 用 grep 串而非 build pass 判定 |
| F2 · 改完没人跑端到端 | Task 10 为必要条件（依赖 Tasks 1-9） |
| F3 · emergent 行为锁过死 | Task 3 措辞采用 conditional fold + N/A fallback；Task 2 区分 `rapid-direct` 与 `rapid-inferred` |
| F4 · 引入新 anchor 冲突 | 每条 Task 含 F4 自检；Task 1 显式调和与 Step 5 既有 "Implementation phase complete." 关系 |
| F5 · 误改 byte-identity 守护段 | Tasks 1/3/4 编辑位置约束在 canonical 块外；Task 3 边界声明（不动 reviewer agent CUSTOM INSTRUCTIONS） |
| F6 · 版本号 / CHANGELOG 漏 bump | Task 9 显式列两处 bump + 验证 + marketplace.json 保持现状的命令式校验 |
| F7 · P3 被拖入 P0/P1 节奏 | 任务编号清晰 + 文档顶部 Commit Strategy 表允许 P2/P3 延后 |

### Open questions deferred to implementation

1. **Task 7 anchor 词组频次下限的具体数字** —— grep 实测后定（plan #1）
2. **Task 6 SessionEnd hook 环境变量名** —— 实施前查 Claude Code hook context API 文档确认（plan #2）
3. **Task 10 trace 文件是否落地** —— hobby 节奏下不强制（plan #3）

### Constraints inherited from plan + brief

- 不引入新 SKILL / agent / command / shared 文件
- byte-identity 守护脚本必须仍 pass（`check-review-agent-drift.sh` 与 `check-canonical-dispatch.sh`）
- 不引入 `MUST` / `NEVER` / `CRITICAL` / `IMPORTANT` / `ULTRATHINK` / `ABSOLUTELY` 类强语气词（例外：schema 字段强制语义如 P1.1 中 `Discovery Mode:` 字段）
- bash only（与既有 hook 脚本一致），无 Python / Node 运行时依赖（Task 6 hook 脚本）
- conventional commit prefix（`fix:` / `feat:` / `docs:` / `chore:`）
- hobby 节奏，无硬截止
- 端到端验证必跑，不可省（Task 10）
