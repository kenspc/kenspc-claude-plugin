# Implementation Plan: v3.0.3 修补输入 —— task-implement Phase 转换 anchor 与 emergent 行为正式化

> **Source brief**: [docs/briefs/v3-0-3-revision.md](../briefs/v3-0-3-revision.md)
> **Discovery Mode**: rapid-direct（Level 1 输入合法快进，详见 brief Discovery Notes）

## Objective

把 brief 列出的 9 项 prompt 修补（P0×2 + P1×2 + P2×2 + P3×3）+ 版本号 bump + CHANGELOG 段，作为 **patch release v3.0.3** 发版。

**显式范围边界**：
- 仅编辑既有 prompt 文本 + hook 脚本——不引入新 SKILL / agent / command / shared 文件
- 不动 Schema 名称（A/B/C/D/E/F/G 保持）、不重排 Phase、不动 `effort:` 配置、不动 agent CONTEXT 契约键名
- byte-identity 守护脚本仍需全 pass

**Out of scope**（同 brief）：
- 任何 SKILL / agent 重构、新增组件、shared/discovery-framework.md 改动、plugin 目录结构调整、自动化端到端测试 harness

## Background

v3.0.2 在 DungeonDescent `pixel-font-pass` 端到端 dogfooding 中暴露两类 prompt 工程缺陷——**Phase 转换可靠性不足**（task-implement Phase 1→Phase 2 不自动衔接、收口措辞溢出）+ **emergent 好行为未正式化**（CUSTOM_INSTRUCTIONS 动态构造无 SKILL 契约）。

trace 完整保留在 `\\wsl.localhost\Ubuntu-24.04\home\kenspc\.claude\projects\-home-kenspc-projects-DungeonDescent\`（3.3 MB 主 jsonl + 9 个 subagent jsonl 共 1.4 MB），是本仓**首次基于真实端到端 trace 证据**做的修补——之前的 patch 多是文档对齐、anchor 措辞优化，没经过具体故障 trace 校验。

## Technical Approach（Prompt-Engineering Mindset, Not Code Mindset）

**核心心智**：本计划全部是 prompt 文本编辑——失败模式不是"代码逻辑 bug"，而是 **anchor 强度不够**、**措辞间冲突**、**artifact 强制契约未落实**（brief F1）。用代码 review 的 mindset（看 diff、跑 build、跑测试）做不出对的判断；要用 prompt 工程的 mindset：**模型读这段 prompt 时，在何种上下文压力下还会按指令做？anchor 词组出现的位置和频次是否够强？措辞与本 SKILL 其他段是否互斥？**

**策略**：
- Anchor 强度靠 **位置（Phase 头/尾、Step 紧邻）+ 重复频次 + artifact 强制契约（如 `Discovery Mode:` 字段）** 实现，不靠 MUST/NEVER 强语气词（v3 设计规则 5）
- 每条 SKILL/agent 改动落地前做 **F4 冲突自检**（新措辞与本 SKILL/agent 任意段是否互斥）——冲突清单作为本计划的 commit message 附注
- 所有 P0/P1 SKILL 编辑位置必须在 `<!-- canonical:dispatch:start -->` ~ `<!-- canonical:dispatch:end -->` 块**之外**（避免 F5 byte-identity 守护漂移）
- v3 五条设计规则继承不动（Workflow SOP / Rationale-anchored / DONE-criteria / No anti-rationalization scaffolding / Plain language）
- 验证策略：静态守护 + release-checklist smoke + **非 DungeonDescent 项目端到端 trace 验证**（替代 v3.0.3 暂无的自动测试 harness）

## Plan-Stage Decisions（Resolving Brief's Deferred Items）

Brief 段 "未明确决策项（plan 阶段处理）" 的六项决策：

| Brief 未决项 | 本计划决定 | 理由 |
|---|---|---|
| 端到端验证目标项目 | **新建 `dotnet new console` 最小项目** + 一个虚构特性请求（如 "add a CLI flag `--greeting` that prints a custom greeting"） | 避免 DungeonDescent 历史 prompt-engineering 污染；author 熟悉 .NET CLI；新建成本几分钟；hobby 节奏下负担可接受 |
| CUSTOM_INSTRUCTIONS 4 类清单是否扩展 | **保持 4 类不动**（项目结构事实 / 风格倾向 / session 内授权 / 跨文档语义约束） | DungeonDescent trace 实证有效；新项目可降级到 `N/A` 即可，不需要扩 4 类 |
| P0.2 收口措辞禁用清单具体词条 | 见 Step P0.2 详列（窄化定义 + 兜底句） | 边界要逐词列才能让模型识别；加 "and similar phrases" 兜底应对未列边缘措辞 |
| SessionEnd 遥测日志格式 | **JSON Lines**（每行一对象，UTF-8） | 机器可解析、append 安全、便于事后 `grep` / `jq` 分析；无文件锁定问题 |
| P3.2 anchor 词组列表 | 见 Step P3.2 详列（实施前 grep 实测后定） | 列出候选，最终在脚本里硬编码前需实测确认 |
| README "What's New" 更新 | **Deferred → v3.1+** | 与 patch release 性质不匹配；README 不强调版本号；不强求 |

## Implementation Steps

> **依赖说明**：单个优先级组（P0 / P1 / P2 / P3）内的 Step 互相独立。跨组依赖：P3.2（anchor 频次断言）的 grep 需在 P0.2（禁用清单）落地后执行，因为 P3.2 的 anchor 词组列表需要反映 post-P0.2 的 SKILL 文本状态。其他跨组步骤无顺序依赖。
> **Commit 节奏**：每个优先级组一个 commit（共 4 个），加附属 bump 一个、验证记录一个，合计 6 个 commit 上限。

每条 Step 含 4 个字段：**File** / **Edit** / **Acceptance Criteria** / **F4 Conflict Self-Check**。

---

### Step P0.1 · task-implement Phase 1 Step 3 升级为硬 gate

**File**: `plugins/kenspc/skills/task-implement/SKILL.md`

**Edit**: Phase 1 Step 3 "Confirm with user" 段。新增措辞约束：
- 仅允许 **batch 清单确认**（示例："以下任务我将依序实施：[task 1, task 2, ...]，OK？"）
- **禁止主动谈具体单一 task 的实现细节**——任何"我打算先动 `X.cs` 里的 `Y` 方法"类措辞不允许出现在 Step 3
- 给一个正例 + 一个反例对照，让模型识别边界（正例：batch 列表；反例：单 task 细节）

**Acceptance Criteria**:
- `bash scripts/check-canonical-dispatch.sh` 仍 pass（编辑位置在 canonical 块外）
- 在 Plan-Stage Decisions 第一行约定的新建 `dotnet new console` 验证项目里跑 `/kenspc-task-implement` 时，trace 显示 Step 3 输出仅含 batch 清单 + 一句 confirm 提示，不含具体实现描述
- Phase 2 在 Phase 1 Step 5 后自动触发（无需用户主动问 "跑完了吗"）

**F4 Conflict Self-Check**:
- 检查 Phase 1 既有的 Step 1/2/4/5 是否有任何措辞鼓励"提前谈具体 task"——若有，同段修订
- 检查 Phase 2 起头处是否依赖 Step 3 的某种宽松措辞——若有，同步收紧

---

### Step P0.2 · task-implement 禁用跨 Phase 收口措辞

**File**: `plugins/kenspc/skills/task-implement/SKILL.md`

**Edit**: Phase 1 Step 5 后段加入 "Closure Wording Boundary" 子段：

**禁用清单**（窄化定义为"任何暗示整条 `/kenspc-task-implement` 已完成的措辞"）：
- 跨 Phase 总结型：`整段落地` / `整段交付` / `所有工作完成` / `workflow 收口` / `session 结束`
- 里程碑措辞：`Step N of M 完成` / `✓ ... 落地` / `milestone landed`
- 终态宣告：`Workflow complete.` / `All phases done.` / `All implementation is done.` / `Ready to wrap up.`
- **兜底句**：`and similar phrases that imply the entire /kenspc-task-implement invocation has finished`

**允许保留**（Phase 内合法进度宣告）：
- `Implementation phase complete. Proceeding to code review.`（Phase 1 → Phase 2 转换提示）
- `Proceeding to Phase 2.`
- 单 task 完工提示（"Task 1 done"）

**调和处理（针对 brief 判断 1，Step 5 模板冲突）**：
- 在新加的 Closure Wording Boundary 段顶部用一句话点明区分："Phase-internal progress (allowed) ≠ workflow-level closure (disallowed)"
- 把 Step 5 既有模板的 `Implementation phase complete.` 措辞**保留不动**（这是合法 Phase 内宣告，不是跨 Phase 总结）

**Acceptance Criteria**:
- 端到端 trace 中 Phase 1 → Phase 2 衔接处不出现禁用清单中的任何措辞
- `Implementation phase complete.` 仍可出现（不是失败信号）
- `bash scripts/check-canonical-dispatch.sh` 仍 pass

**F4 Conflict Self-Check**:
- 通读 `task-implement/SKILL.md` 全文，grep `落地` / `收口` / `Step \d+ of` / `milestone` 关键词——既有 SKILL 文本若已出现禁用词，本次必须同步替换
- 检查 `task-review/SKILL.md`（canonical 块同步对象）是否也含禁用词——同步处理；若 canonical 块本身含禁用词，两个 SKILL 必须同步改

---

### Step P1.1 · generate-brief Phase 1 system-reminder 冲突检测

**File**: `plugins/kenspc/skills/generate-brief/SKILL.md`

**Edit**: 在 `## Phase 1: Discover`（line 63）的 **Goal/Inputs/DONE when/Constraints 块之前**插入新 `### Discovery Mode Detection` 子段。该子段作为 Phase 1 的开篇说明，约束后续 Discovery 行为的运行模式：

```markdown
### Discovery Mode Detection

Read system-reminders at session start. If any reminder text contains
directives like "work without stopping" / "skip clarifying questions" /
"proceed without checking", interactive Discovery cannot run. Three modes
apply, distinguished by both input clarity and reminder pressure:

| Mode | Trigger | Behavior |
|---|---|---|
| `full` | Default; no reminder conflict; Level 2+ input | Normal 3-5 round discussion |
| `rapid-direct` | Level 1 input clarity per discovery-framework.md, regardless of reminder | Compress to 1-2 rounds; brief states `Discovery Mode: rapid-direct` |
| `rapid-inferred (reminder-driven)` | Reminder forces no-question mode AND input is Level 2+ (would normally need discussion) | Skip discussion; brief states `Discovery Mode: rapid-inferred (reminder-driven)`; all non-direct-from-ROUGH_IDEA fields tagged `[Inferred from project context: ...]` or `[Inferred from prior session: ...]` |

Critical distinction: `rapid-direct` is a legitimate fast-track of
Level 1 input, NOT a degraded output. `rapid-inferred (reminder-driven)`
IS a degraded output and must be visually distinguishable in the brief.

In all modes, brief output includes a `Discovery Mode:` field in the
Discovery Notes section. This is the artifact-level contract — closure
phrasing alone is insufficient; the field's presence is the anchor.
```

（注：上文 "all modes ... includes a `Discovery Mode:` field" 是 schema 字段强制语义，artifact 层面的契约，不是行为强语气词——与 brief 禁用 MUST/NEVER 的规则不冲突；schema 字段强制走 artifact 而非措辞强压）

**Known asymmetry**（commit message 记录）：
本 Step 仅覆盖 generate-brief，不同步给 generate-plan 加 Mode Detection。两 SKILL 在此点上 behavior 不对称，留待 v3.0.4+ 讨论是否同步。理由：patch release 节奏 + generate-plan 输入通常更结构化、reminder 冲击面小。

**Acceptance Criteria**:
- 在新建 .NET 项目跑 `/kenspc-brief "a rough idea"`（无 reminder 干扰）→ 输出 brief 含 `Discovery Mode: full` 或 `rapid-direct`
- 在带 "work without stopping" reminder 的 session 跑 `/kenspc-brief` 输入 Level 2+ 内容 → 输出 brief 含 `Discovery Mode: rapid-inferred (reminder-driven)` + 推断字段带 `[Inferred from ...]` 标记
- 本 brief（`v3-0-3-revision.md`）若重跑 ROUGH_IDEA 输入，新版 generate-brief 应输出 `Discovery Mode: rapid-direct`（Level 1 合法快进，不是 reminder-driven）——这是 P1.1 的自指验证

**F4 Conflict Self-Check**:
- 检查 generate-brief Phase 1 既有 Step 1-3 是否假设"用户必然回答问题"——若有，措辞需软化为 "if interactive Discovery applies"
- 检查 `shared/discovery-framework.md` 是否暗示 Discovery 必须 interactive——若有，加注 "see generate-brief Phase 1 Mode Detection"

---

### Step P1.2 · CUSTOM_INSTRUCTIONS 动态构造正式化

**Files**:
- `plugins/kenspc/skills/task-implement/SKILL.md`（dispatch 时构造 CONTEXT 块的位置）
- `plugins/kenspc/skills/task-review/SKILL.md`（同上）

**Edit**: 在两个 SKILL 的 dispatch CONTEXT 块构造说明里加入：

```markdown
CUSTOM_INSTRUCTIONS construction:
- Default: "N/A".
- Override only when the session has accumulated any of the four
  context categories below; fold applicable items into 2-4 sentences:
  1. Project structural facts not yet in CLAUDE.md (e.g., no test
     project in solution, no lint config, only one .csproj under
     solution root).
  2. User-authorized session-scoped permissions (e.g., auto-commit on
     trivial fixes, auto-push to feature branch).
  3. Cross-document narrative anchors (e.g., F1 phrase from a brief
     that the agent should treat as load-bearing context).
  4. Style preferences expressed in conversation (e.g., hobby pace,
     surgical fixes only, no scope creep).
- If none of the four apply to this session, retain "N/A".
```

**关键措辞设计**：`only when ... applicable` + `If none apply, retain N/A`——避免模型为填表而编内容（brief F3）。

**位置约束**：编辑必须位于两个 SKILL 的 canonical 块**之外**。如果 canonical 块本身已提到 `CUSTOM_INSTRUCTIONS`（实施前需 `grep -n CUSTOM_INSTRUCTIONS plugins/kenspc/skills/task-{implement,review}/SKILL.md` 确认），两个 SKILL 必须同步改、否则 `check-canonical-dispatch.sh` fail。

**Acceptance Criteria**:
- 在新建 .NET 项目（无 reminder、无 brief 上下文）跑 `/kenspc-task-implement` → CONTEXT 块 `CUSTOM_INSTRUCTIONS: N/A`
- 在带 brief 的 session 跑（如本 v3.0.3 实施） → CONTEXT 块 CUSTOM_INSTRUCTIONS 折入"参考 brief F1：prompt 改动非代码改动" + "v3 design rule 5: 不引入 MUST/NEVER 强语气"两条
- `bash scripts/check-canonical-dispatch.sh` 仍 pass
- `bash scripts/check-review-agent-drift.sh` 仍 pass（CUSTOM INSTRUCTIONS 在 5 reviewer agent 是 byte-identity 锁定——本 Step **不动 agent 文件**，只动 SKILL 的 dispatch 构造段，不会触发 drift）

**F4 Conflict Self-Check**:
- 5 reviewer agent 的 "CUSTOM INSTRUCTIONS" 段是 byte-identity 锁定的固定模板——本 Step 不改这段；改的是**两个 SKILL dispatch 时如何填充 CUSTOM_INSTRUCTIONS 字段值**。这个边界在 commit message 写清楚
- 检查 `agents/task-implementer.md` 是否有"必须有 CUSTOM_INSTRUCTIONS"硬假设——若有，软化为 "may be N/A"

---

### Step P2.1 · regression-verifier 无测试工程项目 fallback

**Files**:
- `plugins/kenspc/agents/regression-verifier.md` —— PROCESSING APPROACH 段加 fallback 子段（主改动）
- `plugins/kenspc/skills/task-review/SKILL.md` —— Step 7 Verdict determination 段加 `SPOT-CHECK` 第三态说明（canonical 块之外，安全）
- `plugins/kenspc/skills/task-implement/SKILL.md` —— Phase 2 Step 4 Verdict determination 段加 `SPOT-CHECK` 第三态说明（canonical 块之外，安全）

**Edit (regression-verifier.md)**: PROCESSING APPROACH 段加入 "Fallback for projects without test suite" 子段：

```markdown
**Fallback for projects without test suite**:
When the project has no test project / no `dotnet test` target /
no `npm test` target / no equivalent test runner, skip the test
execution step and replace it with a fallback spot-check of the
changed files:
- For each file in code-fixer's accountability list, read the file
  and confirm the claimed fix is present (grep for the new text or
  diff signature).
- Report the verification mode in the Schema C result table row for
  the "Tests pass" check by setting the Result cell to
  `SPOT-CHECK` and the Detail cell to `no test suite — accountability
  list spot-checked instead`. The Result value `SPOT-CHECK` is a
  third state alongside `PASS` / `FAIL` and surfaces in the verdict
  determination as neutral (does not force FAIL).
- This is not a failure mode; it is the correct behavior for
  projects without test infrastructure.
```

**Edit (both SKILLs Verdict determination)**: 在 `task-review/SKILL.md` Step 7 "#### Verdict determination" 段与 `task-implement/SKILL.md` "#### Verdict determination" 段，在 PASS 规则后加一行：

```markdown
- `SPOT-CHECK` from regression-verifier (no test suite available) is
  treated as neutral — it does not force FAIL; PASS may still apply
  if all other checks PASS and no HIGH issues remain. The Verdict
  paragraph should explicitly note "tests spot-checked due to no
  test suite" when this state is present.
```

**Acceptance Criteria**:
- 在新建 `dotnet new console` 项目（无测试项目）跑 `/kenspc-task-review` → regression-verifier 不报"测试失败"，而是 Schema C 表 row 3 ("Tests pass") 输出 Result=`SPOT-CHECK` + Detail=`no test suite — accountability list spot-checked instead`，并完成 accountability 验证
- 在有测试项目的项目里行为不变（fallback 不误触发——判定依据是检测不到 test target 而非"测试失败"）
- 影响范围确认：`SPOT-CHECK` 作为第三态进入 `task-review/SKILL.md` Step 7 与 `task-implement/SKILL.md` Phase 2 Step 4 的 Verdict 判定——在 PASS/FAIL/PARTIAL 决定中视为 neutral（不强制 FAIL），但需要在 Verdict 段说明"tests spot-checked due to no test suite"

**F4 Conflict Self-Check**:
- `check-review-agent-drift.sh` **不**校验 regression-verifier（该 agent 是 orchestration-only，不在 5 reviewer agent 的 byte-identity 锁定范围）——agent 改动安全
- 两个 SKILL 的 Verdict determination 段在 canonical 块之外（task-implement line 284+ / task-review line 235+，canonical 块 end 分别在 line 226 / line 118），新增 `SPOT-CHECK` 说明不会触发 `check-canonical-dispatch.sh`——SKILL 改动安全
- 两个 SKILL 的 Verdict 段措辞**非**byte-identity 锁定（task-implement 多 BLOCKED 状态），新增 `SPOT-CHECK` 行需符合各自既有结构，两段允许不同位置插入
- 检查 `task-review/SKILL.md` Step 6 / `task-implement/SKILL.md` Phase 2 Step 3 是否硬假设 regression-verifier 一定跑 `dotnet test` / `npm test`——若有，同步软化为 "or report SPOT-CHECK if no test target detected"

---

### Step P2.2 · generate-task Phase 3 Plan-Level Concerns 主动建议复跑 plan

**File**: `plugins/kenspc/skills/generate-task/SKILL.md`

**Edit**: Phase 3 Step 3（评审结果呈现）后加入 Conditional Suggestion 段：

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

**Hidden dependency**（commit message 记录）：本 Step 依赖 `task-document-reviewer.md` 输出 "Plan-Level Concerns" 字段。**plan review 已实测确认**：该字段已在 agent.md（line 102 OUTPUT FORMAT 与 line 121 `## Plan-Level Concerns` 段）存在，P2.2 纯 SKILL 改动，**无隐含子任务**。实施前可用 `grep -n "Plan-Level Concerns" plugins/kenspc/agents/task-document-reviewer.md` 复检（应见 ≥2 处匹配）。

**Acceptance Criteria**:
- 在 Plan-Level Concerns 非空时，generate-task 末尾输出该建议
- 在 Plan-Level Concerns 为空时，**不**输出该建议（避免噪音）

**F4 Conflict Self-Check**:
- generate-task Phase 3 当前 SKILL.md 无显式的 "reviewer 失败 / 错误处理" 段（实测：Step 3 仅描述"render the result table verbatim"）——本建议作为新增的 conditional 段，与既有内容无直接冲突
- 仍需检查 Phase 3 Step 3 末尾的 "Below the table, present" 列表（line 197-203）是否与本建议段语义重合——本建议是触发性"复跑 plan"提示，与"render 结果"段为独立行为，加在 Step 3 末尾即可

---

### Step P3.1 · SessionEnd 纯遥测 hook

**Files**:
- `plugins/kenspc/hooks/hooks.json` —— 新增 SessionEnd 事件项
- `plugins/kenspc/hooks/scripts/session-end-telemetry.sh` —— 新脚本（bash，与既有 `check-deps.sh` / `remind-plan-skill.sh` 一致，shebang `#!/usr/bin/env bash` + `set -euo pipefail`；hooks.json 用 `bash <path>` 调用）

**Edit hooks.json**: 在既有顶层 `"hooks": { ... }` 对象内，与 `SessionStart` / `PreToolUse` 并列，加入 `SessionEnd` 键（matcher 用 `"*"` 与既有 `SessionStart` 一致，不要写 `".*"`）：

```json
{
  "description": "kenspc plugin hooks: session startup checks and skill reminders",
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/check-deps.sh",
            "timeout": 10
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/remind-plan-skill.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionEnd": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/scripts/session-end-telemetry.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

（仅 SessionEnd 段是新增；SessionStart / PreToolUse 段是既有内容，列出以表明插入位置。）

**Edit session-end-telemetry.sh**（bash，无 Python/Node 依赖）：
- 读 session metadata（环境变量 `CLAUDE_SESSION_ID` 等，按 Claude Code hook context API 实际可用变量决定——实施前查文档确认）
- 检测 session 中是否调用过 `/kenspc-task-implement` 但未调用 `/kenspc-task-review`
- 若是，append 一行 JSON Lines 到 `${HOME}/.claude/kenspc/missed-reviews.log`：

```jsonl
{"timestamp": "2026-05-11T14:23:45+08:00", "session_id": "abc...", "reason": "task-implement without task-review"}
```

- 路径展开用 `${HOME}` 而非 `~`（bash 下 `~` 仅在 word 开头展开，嵌入字符串内的 `~/.claude/...` 不展开；`${HOME}` 在任何上下文都展开。Windows Git Bash 下 `${HOME}` 展开为 `/c/Users/kenspc` 类路径，目录创建可靠）
- 文件不存在则创建（含父目录 `mkdir -p`）
- **零干扰用户**——不输出 stdout、不阻断 session 退出、所有错误吞掉（`2>/dev/null || true`）

**Acceptance Criteria**:
- `cat plugins/kenspc/hooks/hooks.json | python -m json.tool` 仍 pass
- 新脚本以 git mode `100644` 入库（与既有 `check-deps.sh` / `remind-plan-skill.sh` 一致；`hooks.json` 用 `bash <path>` 调用，无需 executable bit——实测既有脚本均为 `100644`）
- 在新建 .NET 项目跑 task-implement 后未跑 review，退出 Claude Code session 后 `${HOME}/.claude/kenspc/missed-reviews.log` 出现新 JSON Lines 行
- 跑 task-implement 后**跑了** review，无新行 append
- 用户体感零干扰（hook 静默运行，无 stderr/stdout 可见输出）
- **Windows Git Bash 兼容**：`${HOME}` 展开后路径创建成功（`/c/Users/kenspc/.claude/kenspc/` 目录存在）

**F4 Conflict Self-Check**:
- 检查 hooks.json 既有事件项是否已有 SessionEnd 项——若有，需 merge（同事件下加入 hook，不覆盖）
- 脚本路径用 `${CLAUDE_PLUGIN_ROOT}`（plugin 内引用）+ `${HOME}`（用户家目录）两个变量，不混淆

---

### Step P3.2 · check-canonical-dispatch.sh 升级为双重检测

**File**: `scripts/check-canonical-dispatch.sh`（项目根，不在 plugin 内）

**Edit**: 当前脚本只做 sha256 byte-identity 检查。升级为双重检测：
1. **byte-identity**：保留 sha256 当前逻辑不变
2. **anchor 词组频次断言**：在两个 SKILL（task-implement 与 task-review）的 canonical 块内，对若干关键 anchor 词组做出现次数下限检查

**实施前 grep 步骤**：
```bash
grep -cE "unconditional|single message|5 subagents|automatically|in parallel" \
  plugins/kenspc/skills/task-implement/SKILL.md \
  plugins/kenspc/skills/task-review/SKILL.md
```
根据实测计数定下限。

**候选词组清单（实施时根据 grep 实测调整）**：

| 词组 | 期望下限 | 理由 |
|---|---|---|
| `unconditional` | ≥ 1 次 | Phase title 词，标志"无条件 dispatch review"语义 |
| `single message` 或 `in a single message` | ≥ 1 次 | 并行 dispatch anchor，去掉则模型可能误以为可序列 dispatch |
| `5 subagents` 或 `five subagents` | ≥ 1 次 | 数量约束 anchor |
| `automatically` 或 `auto-` 前缀（如 `auto-dispatch`） | ≥ 1 次 | 不依赖用户主动触发的 anchor |

**Acceptance Criteria**:
- 当前两个 SKILL 跑新脚本 → `exit 0`
- 故意改一个 SKILL 删掉 `unconditional` 词 → 脚本 `exit` 非 0 + 报错指出哪个词在哪个 SKILL 缺失
- 在 CI / pre-commit 触发时也能跑（不依赖交互输入）
- 兼容现有 `git pre-commit` 钩子集成（如已有）

**F4 Conflict Self-Check**:
- `check-review-agent-drift.sh` 与本脚本职责分离——本 Step 不动它
- anchor 词组若与 P0.2 禁用清单有交叉（理论上不会，禁用清单是"收口"词、anchor 是"工作流"词），实施前逐词比对确认

---

### Step P3.3 · CLAUDE.md 加两条元教训

**File**: `c:\Projects\KENSPC\Claude Plugin\CLAUDE.md`（项目根 CLAUDE.md）

**Edit**: 在既有 `## Skill Development Conventions` 章节末尾或独立新节 `## Plugin Design Lessons (Cumulative)` 加入：

```markdown
## Plugin Design Lessons (Cumulative)

### Phase transitions rely on artifacts, not wording
Closure phrases ("complete", "landed", "wrapped up") are decorations.
The model treats Phase N+1 as triggered only when Phase N has produced
the artifact Phase N+1 reads as input. Anchor cross-phase contracts via
artifacts (files written, fields filled, dispatch CONTEXT blocks) — not
via closure-style natural language alone.
Background: v3.0.2 task-implement Phase 1 → Phase 2 sometimes failed to
auto-trigger because Phase 1 closure phrasing read as "session over" to
the orchestrator.

### Hooks are for environment constraints and post-hoc telemetry, not workflow state-machine guarding
Hooks fire on harness events (SessionStart, SessionEnd, Stop, etc.) and
do not observe SKILL-internal Phase state. Using a hook to enforce
"task-implement must be followed by task-review" leads to false-positive
blocking (Stop hook fires on legitimate Phase 1 → Phase 2 transitions
within a single SKILL run). Use hooks for:
- Environment setup / teardown
- Cross-session telemetry (post-hoc analysis)
- External system notifications
Avoid using hooks for SKILL-internal workflow guarantees.
Background: an early v3.0.3 design considered a Stop hook to force
task-review dispatch; rebatched into a SessionEnd telemetry log after
recognizing the misjudgement.
```

**Acceptance Criteria**:
- CLAUDE.md 渲染正常（markdown 语法不破）
- 两条教训在文件中可被未来 SKILL/agent 设计 review 时引用
- 文本本身遵守 v3 设计规则 5（不引入 MUST/NEVER/CRITICAL/ULTRATHINK 词；"Avoid using" 替代 "Do NOT use"）

**F4 Conflict Self-Check**:
- 检查既有 CLAUDE.md `### Non-Goals` 段是否与"hook 边界"教训互补不互斥——Non-Goals 谈的是 `shared/discovery-framework.md` 不下沉为 agent，与 hook 边界教训正交，无冲突

---

### Step Aux.1 · 版本号 + CHANGELOG bump

**Files**:
- `plugins/kenspc/.claude-plugin/plugin.json` —— `"version": "3.0.2"` → `"3.0.3"`
- `.claude-plugin/marketplace.json` —— 当前 `kenspc` 条目无 `version` 字段（实测：marketplace 注册表仅含 `name` / `description` / `source` 三键），无需 bump；保持现状即可，不要新增 `version` 字段（marketplace 注册摘要的版本号由 `source` 指向的 `plugin.json` 提供，两层故意分层——见项目 CLAUDE.md "Marketplace Structure"）
- `plugins/kenspc/CHANGELOG.md` —— 加 v3.0.3 段

**CHANGELOG v3.0.3 段大纲**：

```markdown
## v3.0.3 — Phase Transition Anchors & Emergent Behavior Formalization

Patch release based on the first end-to-end DungeonDescent dogfooding
trace (pixel-font-pass). Nine prompt-engineering refinements + meta-
lessons captured in CLAUDE.md. All edits are prompt-text refinements;
no new SKILLs, agents, or components.

### Phase 1 transitions (P0)
- task-implement Phase 1 Step 3 hardened as batch-confirmation gate
- task-implement Phase 1 Step 5+ disables cross-Phase closure wording
  (with explicit allowlist for Phase-internal progress phrases)

### Emergent behavior formalization (P1)
- generate-brief Phase 1 system-reminder conflict detection + Discovery
  Mode artifact field (full / rapid-direct / rapid-inferred)
- task-implement / task-review CUSTOM_INSTRUCTIONS dynamic construction
  formalized as conditional fold with N/A default

### Coverage gaps (P2)
- regression-verifier fallback for projects without test suite
  (spot-check mode)
- generate-task suggests /kenspc-plan re-run when reviewer reports
  non-empty Plan-Level Concerns

### Long-term value (P3)
- SessionEnd telemetry hook for missed-review tracking (zero
  user-visible disruption; JSON Lines log at ~/.claude/kenspc/missed-reviews.log)
- check-canonical-dispatch.sh upgraded to byte-identity + anchor phrase
  frequency dual check
- CLAUDE.md adds two design lessons: Phase transitions via artifacts;
  hook scope boundaries

### Meta-lessons (informing this patch)
- Stop hook misjudgement: rebatched to SessionEnd telemetry after
  recognizing hooks cannot observe SKILL-internal Phase state
- Author warning: prompt changes are not code changes — verification
  must be runtime trace inspection, not build/test pass

### Known asymmetry (deferred to v3.0.4+)
- generate-plan does NOT mirror generate-brief's Discovery Mode
  Detection — generate-plan input is typically more structured;
  reminder pressure has not been observed in plan generation traces
```

**Acceptance Criteria**:
- `plugin.json` `version` 字段为 `3.0.3`
- `marketplace.json` 仍无 `version` 字段（保持现状）——验证：`python -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); assert 'version' not in m['plugins'][0]"` exit 0
- CHANGELOG 段 v3.0.3 加在 v3.0.2 段**上方**（文件中最新版在最前——见现有 CHANGELOG.md 顺序）
- `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool > /dev/null` pass
- `cat .claude-plugin/marketplace.json | python -m json.tool > /dev/null` pass

---

### Step Aux.2 · release-checklist 跑通

**File**: `docs/release-checklist.md`（既有）

**Edit**:
- 不修改既有 checklist 内容
- 跑一遍现有 smoke test
- **新增一项**："End-to-end trace verification on greenfield project (non-DungeonDescent)" —— 列入既有 checklist 末尾

**Acceptance Criteria**:
- checklist 现有项全 pass
- 新增项也通过

---

## Validation Strategy

按 brief 判断 4 的发版门槛细化。

### 必要条件（全做完才可发 v3.0.3）

1. **静态守护全过**：
   - `cat plugins/kenspc/.claude-plugin/plugin.json | python -m json.tool` → exit 0
   - `cat plugins/kenspc/hooks/hooks.json | python -m json.tool` → exit 0
   - `cat .claude-plugin/marketplace.json | python -m json.tool` → exit 0
   - `bash scripts/check-review-agent-drift.sh` → exit 0
   - `bash scripts/check-canonical-dispatch.sh` → exit 0（含新加的 anchor 频次断言）

2. `docs/release-checklist.md` 列的 smoke test 全跑过（含 Aux.2 新增项）

3. **端到端 trace 验证**——在新建 `dotnet new console` 最小项目上跑完整链路：
   `/kenspc-brief` → `/kenspc-plan` → `/kenspc-task` → `/kenspc-task-implement` → `/kenspc-task-review`

   **人工 trace grep 三个具体串**（替代 v3.0.3 暂无的自动 harness）：

   | 验证点 | grep 串 | 期望结果 |
   |---|---|---|
   | Phase 2 自动触发 | `Proceeding to Phase 2` 或 `Proceeding to code review` | 在 Phase 1 Step 5 之后**自动**出现（不是用户问后才出现） |
   | 收口禁用守住 | `整段落地` / `session 结束` / `workflow 收口`（3 个最常踩词） | 在 Phase 2 dispatch 前**零出现** |
   | Discovery Mode 字段 | `Discovery Mode:` | 在 brief 输出中**真出现**，值为 `full` / `rapid-direct` / `rapid-inferred (reminder-driven)` 之一 |

   建议端到端验证里专门跑一段带 "work without stopping" reminder 的 brief 生成子 session，验证 `rapid-inferred (reminder-driven)` 路径。

4. 版本同步：`plugin.json` 升到 `3.0.3` + `CHANGELOG.md` 含 v3.0.3 段（`marketplace.json` 当前无 plugin 版本字段，不参与 bump——见 Aux.1）

5. git commit 全部用 conventional commit prefix（`fix:` / `feat:` / `docs:` / `chore:`）

### 倾向条件（最好做到）

- 至少做完 P0 + P1（4 项）才发版；P2/P3 可分批合入或纳入下个 patch
- 端到端验证用**全新空项目**（不复用既有项目）——已在 Plan-Stage Decisions 确认
- 端到端 trace 记录到 `docs/traces/v3-0-3-greenfield.md`（可选，hobby 节奏下不强制；若有则便于未来 dogfooding 对照）

## Risks and Mitigations

| 风险（对应 brief F#）| 缓解 |
|---|---|
| F1 · 把 prompt 改动当代码改动做 | 每条 Step 含 F4 自检字段；commit message 必须附冲突清单；Validation 用端到端 trace + 三个具体 grep 串而非"build 过" |
| F2 · 改完没人跑端到端 | Validation 把端到端列为必要条件第 3 项（不是 nice-to-have）；细化为 3 个具体 grep 串 |
| F3 · emergent 行为锁过死 | P1.2 措辞采用 conditional fold + N/A fallback；P1.1 区分 `rapid-direct` 与 `rapid-inferred` 两种 rapid mode |
| F4 · 引入新 anchor 冲突 | 每条 Step 含 F4 自检；P0.2 显式调和与 Step 5 既有 "Implementation phase complete." 措辞的关系 |
| F5 · 误改 byte-identity 守护段 | 所有 P0/P1 编辑位置约束在 canonical 块外；P1.2 明确改的是 SKILL 的 dispatch 构造段而非 agent 的 CUSTOM INSTRUCTIONS 段 |
| F6 · 版本号 / CHANGELOG 漏 bump | Aux.1 显式列出 `plugin.json` + `CHANGELOG.md` 两处 bump + 验证步骤；marketplace.json 无 version 字段需保持现状（见 Aux.1）；release-checklist 兜底 |
| F7 · P3 被拖入 P0/P1 节奏 | Implementation Steps 顶部依赖说明明示 "每组独立可停手"；倾向条件允许 P2/P3 延后 |

## Open Questions

实施过程中可能浮现的待决项（plan reviewer 评后或实施时再处理，不阻塞 plan 落盘）：

1. **P3.2 anchor 词组频次下限的具体数字** —— 本计划列了"至少 1 次"作为通用下限，但实施前 grep 当前 SKILL 实测后，可能需要差异化（如 `unconditional` 至少 1 次，`single message` 至少 2 次因为是关键并行 anchor）。最终数字以 grep 实测结果为准。

2. **P3.1 SessionEnd hook 在 Windows Git Bash 下的具体环境变量名称** —— `CLAUDE_SESSION_ID` 等变量是否真存在、是否有别名（`CLAUDE_CODE_SESSION_ID`？）——实施前查 Claude Code hook context API 文档确认；若变量不存在，回退用 timestamp + PID 组合作为 session 标识。

3. **端到端 trace 验证记录文件** —— 是否落地为 `docs/traces/v3-0-3-greenfield.md`？hobby 节奏下不强制；由实施者决定。

4. ~~**P2.2 隐含子任务的工作量**~~ —— **plan review 已确认 agent.md 现有 Plan-Level Concerns 输出字段**，P2.2 为纯 SKILL 改动；此 open question 已结清。

5. **P2.1 引入 `SPOT-CHECK` 第三态对 SKILL Verdict 判定的连锁影响** —— 在 regression-verifier Schema C 增加 `SPOT-CHECK` 第三态后，`task-review/SKILL.md` Step 7 与 `task-implement/SKILL.md` Phase 2 Step 4 的 Verdict determination 段（PASS/FAIL/PARTIAL 规则）需同步声明"`SPOT-CHECK` 视为 neutral，不强制 FAIL"。该改动落在两个 SKILL 的 Verdict 子段、**在 canonical 块之外**——实施 P2.1 时一并修改这两段，否则 PASS 规则文字"build / tests / lint all PASS"会与 Schema C 中的 `SPOT-CHECK` 状态冲突。**plan 阶段评估**：纳入 P2.1 scope，不另立 Step；实施时 P2.1 commit 同时改一个 agent + 两个 SKILL 共 3 个文件。

## Constraints（继承 brief）

- 不引入新 SKILL / agent / command / shared 文件
- byte-identity 守护脚本必须仍 pass（`check-review-agent-drift.sh` 与 `check-canonical-dispatch.sh`）
- 不引入 `MUST` / `NEVER` / `CRITICAL` / `IMPORTANT` / `ULTRATHINK` / `ABSOLUTELY` 类强语气词
  - 例外：schema 字段强制语义（如 P1.1 中 `Discovery Mode:` 字段在 brief 输出中"includes"——artifact 层契约，不是行为强压）
- bash only（与既有 hook 脚本一致），无 Python / Node 运行时依赖（P3.1 hook 脚本）
- conventional commit prefix（`fix:` / `feat:` / `docs:` / `chore:`）
- hobby 节奏，无硬截止
- 端到端验证必跑，不可省（替代 v3.0.3 暂无的自动 harness）

---

## Self-Challenge Log（plan 起草过程中的 6 处修订，留作 plan-document-reviewer 参考）

本 plan Phase 2 自挑战后合入的修订：

1. **P0.2 禁用清单加 "and similar phrases" 兜底句** —— 避免模型在未列边缘措辞踩雷（如 `Ready to wrap up.`）
2. **P1.1 known asymmetry 记入 commit message** —— generate-plan 不同步加 Mode Detection，留待 v3.0.4+
3. **Validation 第 3 项细化为 3 个具体 grep 串** —— 替代 v3.0.3 暂无自动 harness 的人工核验形态
4. **P3.1 脚本路径用 `${HOME}` 不用 `~`** + 加 Windows Git Bash 兼容 acceptance criteria
5. **P2.2 隐含子任务（agent 字段存在性 grep）记入 hidden dependency 段**
6. **Implementation Steps 顶部加跨优先级依赖说明** —— P3.2 grep 需在 P0.2 落地后执行

## Next Step

按 generate-task skill 的约定，本 plan 写入后可由 `plan-document-reviewer` 自动评审。下一步建议：

```
/kenspc-task docs/plans/v3-0-3-revision.md
```

由 generate-task 把本 plan 的 9 项修补 + 附属 + 验证步骤展开为具体 Task 文档（含每条 Task 的文件粒度操作、F4 自检 checklist、commit 节奏）。
