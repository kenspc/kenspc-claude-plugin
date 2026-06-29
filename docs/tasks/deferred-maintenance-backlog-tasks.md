# Deferred Maintenance Backlog 处置 — Task Document

## Context

把 v3.1.0（Code-Craft Principles）自动评审遗留的 deferred tail 落地执行。整份计划真正可执行的工作只有 **Item 2**（CHANGELOG 三处死锚点机械修复）加一步验证；Item 1 与 Item 3 在计划层已分别处置为 **Parked** 与 **已失效**，本文档不为其生成任务（见下方"超出任务范围"）。

来源计划：[`docs/plans/deferred-maintenance-backlog.md`](../plans/deferred-maintenance-backlog.md)

### 超出任务范围（计划层已闭合，故意不拆任务）

- **Item 1 — `.gitattributes` LF 规范**：Parked / 待触发。仅当**实际观察到**跨平台换行符 drift 时才执行；触发前新增即投机式基础设施。计划第 5 节已记录触发条件与安全方案，本文档不生成任务。
- **Item 3 — `+50` CHANGELOG cap 重校准**：已失效 / Resolved by deletion。承载文档 `docs/tasks/code-craft-principles-tasks.md` 已在提交 `98993a7` 删除，工作树中无 live cap 可重校准，无对象可执行。

> 此处明示"故意不拆"，避免未来读者误以为 Item 1 / Item 3 被遗漏。

## Tasks

### Task 1: 修复 Item 2 — CHANGELOG 三处死锚点

**Status:** TODO

在 `plugins/kenspc/CHANGELOG.md` 中，把链接目标 `README.md#acknowledgments` 改为
`README.md#acknowledgements`（补回漏掉的 `e`），共 **3 处**，分别位于第 **647 / 699 / 755** 行
（落在 v3.0.0 / v2.0.0 / v1.5.0 历史条目内）。

**方向锁定（关键失败模式防护）**：改**链接 → 对齐 heading**，**绝不**反向改 heading。
`plugins/kenspc/README.md:206` 的 `## Acknowledgements`（生成锚点 `#acknowledgements`）是正确的真相源，
**保持不动** —— 若改 heading 去迁就断链，会反过来破坏其它所有正确引用。

**只改锚点目标**：链接的**显示文字** "Acknowledgments"（美式拼写）属历史散文，**不改**；
不触碰这 3 处之外的任何字符，不重写任何历史条目散文。

**Files to modify:**
- `plugins/kenspc/CHANGELOG.md`（仅第 647 / 699 / 755 行的锚点子串）

**Files that must NOT change:**
- `plugins/kenspc/README.md`（真相源 heading，保持不动）

**Acceptance criteria:**
- `grep -c 'README.md#acknowledgments)' plugins/kenspc/CHANGELOG.md` → **0**
- `grep -c 'README.md#acknowledgements)' plugins/kenspc/CHANGELOG.md` → **3**
- `git diff --stat` 仅显示 `plugins/kenspc/CHANGELOG.md` 为 `1 file changed`，净变化为 `+3 −3`（逐行只动锚点）
- `plugins/kenspc/README.md` 无任何改动
- 提交为单独一个 `docs:` conventional commit（建议信息：`docs(changelog): fix dead acknowledgements anchor in 3 historical entries`）

---

### Task 2: 跑 pre-flight 机械检查确认 invariant 未破坏

**Status:** TODO

**Depends on:** Task 1

运行 6 个守卫脚本，确认 Task 1 的锚点改动未破坏任何 byte-identity / 结构 invariant。
Task 1 只动 CHANGELOG 的链接锚点，预期对这些守卫零影响；此步是**确认**而非修复。

**Commands to run:**

```bash
bash scripts/check-review-agent-drift.sh
bash scripts/check-canonical-dispatch.sh
bash scripts/check-verdict-shared.sh
bash scripts/check-code-craft-canonical.sh
bash scripts/check-quality-reviewer-bullet-structure.sh
bash scripts/check-notes-format-sync.sh
```

**Files to modify:** 无（纯验证任务，不改动任何文件）

**Acceptance criteria:**
- 上述 6 个脚本全部 **exit 0**
- 若任一脚本 exit 非 0：停止并回报 —— 这意味着 Task 1 意外触动了某个 invariant，需回到 Task 1 排查，而非修改守卫脚本

## Notes

- 真相源：`plugins/kenspc/README.md:206` 的 `## Acknowledgements` 生成锚点 `#acknowledgements`，是 3 处链接应对齐的目标。
- 失败模式优先级：方向改错（改 heading 而非改链接）比漏改更危险 —— 它会把当前 3 处断链扩散成所有正确引用断链。Task 1 的双向 grep 验收即为捕捉此情形。
