# 计划书：Deferred Maintenance Backlog 处置（v3.1.0 Review Tail）

> 来源 brief：[`docs/briefs/deferred-maintenance-backlog.md`](../briefs/deferred-maintenance-backlog.md)
> 生成日期：2026-06-29

## 1. Objective（目标与边界）

把 v3.1.0（Code-Craft Principles）自动评审遗留的三项 deferred 工作，在**单一计划文档**中给出明确处置（disposition）与可追溯记录，使每一项的状态、依据、触发条件不再散落，并执行其中唯一的 active 工作（Item 2）。

**范围内：**
- 为三项各自给出一个确定的处置。
- 执行唯一的 active 工作 Item 2（CHANGELOG 锚点修复）的规划与验收定义。

**范围外：**
- 重做 v3.1.0 已修的六项（#15、#16、#17、#31、#32、#33，均 DONE）。
- 改动任何 v3.1.0-locked invariant：3-file byte-identity hash、Task 12 四-phrase relocation grep、5-reviewer-agent drift guard、`task-review` ↔ `task-implement` 的 canonical-dispatch / verdict-shared byte-identity。
- 重写任何 CHANGELOG 历史条目的散文（Item 2 只动断裂的锚点目标）。

> **决策记录（可追溯）**：本计划把三项**合并为一份计划**，这**与原 brief 的下游处理建议相悖** —— brief 在 *The Hard Part* 与 *Discovery Notes* 明确建议三项各有归宿、不应合成一个计划，并特意提醒"a future `/kenspc-plan` run is not misled into treating them as one work-stream"。合并为单一计划是 **2026-06-29 经用户明确确认**的决定，特此如实记录，不作掩盖。

## 2. Background / Context（背景）

- 三项均源自 **2026-05-14** 的 v3.1.0 自动 5-angle 评审，当时被 triage 为 **DEFERRED**（同批已修的六项均 DONE）。
- brief（提交 `c10bb45`，`docs(briefs): add self-contained deferred-maintenance-backlog brief`）把这条 deferred tail 归档留存。
- **起草本计划期间核实出的两处新事实（brief 未预见）：**
  1. **Item 3 的 literal 目标已消失。** 含 `+50` cap 的 v3.1.0 任务文档 `docs/tasks/code-craft-principles-tasks.md` 已在**更晚的提交 `98993a7`**（`chore(docs): remove completed planning artifacts and fix stale doc paths`）中被删除。该 subtraction audit 是**逐文档手写**的一次性检查（源自各 plan 的 Step 4.3 / 对应 task 文档的 Task 14），从来不是 `generate-task` 模板里的现存约定。brief 写于 `c10bb45`、删除发生于其后的 `98993a7`，故 brief 中"the `+50` cap remains in the v3.1.0 task document's Task 14"一句现已过时。
  2. **Item 1 触发未满足。** 用户确认尚未实际观察到跨平台换行符 drift。

## 3. 三项处置总览（Technical Approach）

| Item | 性质 | 本计划处置 | 是否产生改动 |
|---|---|---|---|
| **Item 2** — CHANGELOG 三处锚点拼写 | 无条件机械修复 | **立即执行步骤**（见 Step A） | 是（`docs:` 一次提交） |
| **Item 1** — `.gitattributes` LF 规范 | 触发门控基础设施 | **Parked / 条件步骤**：记录触发条件 + 安全方案，现在不新增文件 | 否 |
| **Item 3** — `+50` cap 重校准 | 计划约定问题 | **标记为已失效**：承载文档已删除，无 live cap 可重校准 | 否 |

设计取舍说明：三项性质截然不同，本计划**不**强行给它们统一的实施节奏 —— 只有 Item 2 是可执行步骤，Item 1 是待触发的条件记录，Item 3 是闭合结论。这是"三项合一"前提下唯一诚实的形态。

## 4. Implementation Steps

### Step A（active）：修复 Item 2 — CHANGELOG 三处死锚点

- **做什么**：在 `plugins/kenspc/CHANGELOG.md` 中，把链接目标 `README.md#acknowledgments` 改为 `README.md#acknowledgements`（补回漏掉的 `e`），共 **3 处**，分别位于第 **647 / 699 / 755** 行（落在 v3.0.0 / v2.0.0 / v1.5.0 历史条目内）。
- **方向（关键失败模式防护）**：改**链接 → 对齐 heading**，绝不反向改 heading。`plugins/kenspc/README.md:206` 的 `## Acknowledgements`（生成锚点 `#acknowledgements`）是正确的真相源，**保持不动** —— 若改 heading 去迁就断链，会反过来破坏其它所有正确引用。
- **只改锚点目标**：链接的**显示文字** "Acknowledgments"（美式拼写）属历史散文，**不改**；不触碰这 3 处之外的任何字符，不重写历史条目散文。
- **输入 → 输出**：3 处 `#acknowledgments` → `#acknowledgements`；其余字节不变。
- **验收标准（acceptance criteria）**：
  - `grep -c 'README.md#acknowledgments)' plugins/kenspc/CHANGELOG.md` → **0**
  - `grep -c 'README.md#acknowledgements)' plugins/kenspc/CHANGELOG.md` → **3**
  - `git diff --stat` 仅显示 `plugins/kenspc/CHANGELOG.md` 为 `1 file changed`，且净变化为 `+3 −3`（逐行只动锚点）。
  - `plugins/kenspc/README.md` 无任何改动。
- **提交**：单独一个 `docs:` conventional commit（建议信息：`docs(changelog): fix dead acknowledgements anchor in 3 historical entries`）。

### Step B（verification）：pre-flight 机械检查仍 exit 0

- 运行 6 个守卫脚本，确认 Step A 未破坏任何 invariant：

  ```bash
  bash scripts/check-review-agent-drift.sh
  bash scripts/check-canonical-dispatch.sh
  bash scripts/check-verdict-shared.sh
  bash scripts/check-code-craft-canonical.sh
  bash scripts/check-quality-reviewer-bullet-structure.sh
  bash scripts/check-notes-format-sync.sh
  ```

- **验收标准**：全部 exit 0。Step A 只动 CHANGELOG 的链接锚点，预期对上述守卫零影响；此步是**确认**而非修复。

## 5. Parked / 已失效项（不执行，仅记录）

### Item 1 — `.gitattributes` LF 规范（Parked，待触发）

- **触发条件**：仅当**实际观察到**跨平台换行符 drift（本 repo 在 Windows / Git Bash 与 WSL2 Ubuntu 之间开发）。触发前新增 `.gitattributes` 即 brief 警告的投机式基础设施，且会带来一次性 normalization churn（一个触及大量文件的提交）的风险。
- **触发后的安全方案（备查，届时单独成一小计划/提交）**：
  - 采用**统一 LF** 规范。根 `.gitattributes` 例如：`* text=auto eol=lf`，并对脚本显式 `*.sh text eol=lf`、文档 `*.md text eol=lf`。
  - **绝不**对 `.sh` 强制 CRLF（会破坏 Unix 下的 shell 执行）。
  - **守卫安全性已核实**：`scripts/check-*.sh` 以 `sed` 抽取标记块 + `sha256sum` 做**跨 `.md` 文件**的 byte-identity 比对（比的是两文件之间相等，而非对存档 hash）。统一 LF 规范会让被比对的两块**一起**变 LF → identity 仍成立；危险**仅**在于非统一规范（如对某类文件单独强制 CRLF）。
  - 落地后必须跑 Step B 的 6 个脚本 + `git diff` 确认无意外 churn。

### Item 3 — `+50` CHANGELOG cap 重校准（已失效 / Resolved by deletion）

- **结论**：随承载文档 `docs/tasks/code-craft-principles-tasks.md` 在 `98993a7` 被删除而**自然解决**。当前工作树中**不存在**任何 live 的 `+50` cap 或 subtraction-audit 实例，因此不会再产生那个 known-false breach，无对象可"重校准"。
- **依据**：该 audit 是 per-document 手写检查（各 plan 的 Step 4.3 → 对应 Task 14），**非** `generate-task` 模板的现存约定 —— 已对 `generate-task` SKILL、`plugins/kenspc/references/`、`docs/release-checklist.md` 核实，均无该约定文本。
- **不做**（按用户选择）：不新建前瞻约定，避免引入一条目前并不存在的模板表面（speculative convention）。若未来某次确需为 v3-era CHANGELOG 设界，再在那次 task/plan 模板修订中一并处理。

## 6. Risks and Mitigations

| 风险 | 缓解 |
|---|---|
| Item 2 被改成动 heading（会破坏所有正确引用） | 方向锁定 link→heading；README heading 明令不动；验收 grep 双向校验 |
| Item 2 误伤 3 处之外的锚点，或重写历史散文 | 精确替换子串 `README.md#acknowledgments)`；`git diff --stat` 须为单文件 `+3 −3` |
| Step A 意外触动某个 byte-identity 守卫 | Step B 跑全部 6 个脚本确认 exit 0 |
| Item 1 若日后仓促上马，配置不当破坏守卫或 churn | 严守触发门控；落地走第 5 节安全方案 + Step B |

## 7. Open Questions

- **Item 1 触发监测**：目前无自动监测换行符 drift 的机制，依赖人工留意；一旦观察到，再就 Item 1 单独起一份小计划。
- 其余无 —— Item 3 已闭合，Item 2 处置完全确定。
