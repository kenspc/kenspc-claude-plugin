# Requirement Brief: v3 过度约束清理（Language Forcing + Status Table）

## Outcome

撤销 v3.0.0 引入但实际上没有产生效用、甚至误导用户的两条「正向约束」——
强制英文输出（English-only output）与 Planned Dispatch 表中的 Status 列——
让 plugin 把 v3 自己定下的 bitter-lesson 原则贯彻得更彻底：把语言决策交回
给 Claude 的上下文判断，把状态制品的"假象"从静态 markdown 中拿掉。

成功后的可观察变化：
- 用户用中文/英文/混合语言触发 skill 时，Claude 的进度提示和最终摘要会
  自然地匹配用户语言，不再被 SKILL/agent 文件硬性限定为英文。
- VS Code Claude Code 用户看到的 "Planned Dispatch" 表不再永远停在
  `pending` 假装是 live status，而是诚实地呈现"即将派发哪些 agents"
  这份意图清单。

## Scope

**In scope:**

1. **移除强制英文输出条款**
   - 5 个 agent .md 中的 "Summaries are in English" / "in English only" 段落：
     `task-implementer.md`、`code-fixer.md`、`plan-document-reviewer.md`、
     `guide-document-reviewer.md`、`task-document-reviewer.md`。
   - 项目根 `CLAUDE.md`「Writing Rules for Skill Content」中的
     "Output in English only" 条目。
   - `plugins/kenspc/README.md` 中的 "English-only output" feature 卖点。
   - `docs/plans/v3-bitter-lesson-refactor.md` 中 AC6（双语输出 grep guard）
     的处理：直接删除该 AC，对应放弃 release-check 中的 grep 拦截。

2. **改写 Planned Dispatch 表（去 Status 列）**
   - 5 个 dispatching SKILL.md 的 Planned Dispatch 表：
     `generate-plan/SKILL.md`、`generate-task/SKILL.md`、
     `generate-guide/SKILL.md`、`task-implement/SKILL.md`、
     `task-review/SKILL.md`。
   - 表头从 `# / Agent / Status` 改为 `# / Agent / Role`（或类似纯描述列），
     去掉 `pending` 字面值。
   - 表前的引导句改写为"即将派发以下 Agents"或 "Planned Dispatch:"，
     明确这是 *intent* 不是 *status*。
   - dispatch 之后的 *result table*（事后写、能正确填值的那张）保留不动。

3. **更新对应的不变量 guard**
   - `docs/plans/v3-bitter-lesson-refactor.md` 中 AC8 反向化：
     从「`pending` 必须出现在 markdown 表格行中」改为
     「Planned Dispatch 表必须列出该 skill 派发的所有 agents
     （`# / Agent / Role`），不得出现 Status 列或 `pending` 字样」。
   - `CHANGELOG.md` 增补 v3.0.2 段落，记录两项撤销的判断与原因。
   - 检查 `scripts/check-review-agent-drift.sh` 和
     `scripts/check-canonical-dispatch.sh` 是否需要相应调整
     （初步判断：仅按当前共享段位置/边界做哈希，应不受影响，但需验证）。

**Out of scope:**

- Claude Code CLI 底栏 agents-list 行为（属 harness，不在 plugin 内）。
- VS Code Claude Code 宿主端的 live agents-list 实现（属宿主端能力缺口，
  plugin 无法补救）。
- `shared/discovery-framework.md` 中"How to ask"中文例句——这是 v3.0.0
  CHANGELOG 已声明的 deliberate exception（教学性 illustrative phrasings），
  本次不动。
- 全局 user-private CLAUDE.md（`~/.claude/CLAUDE.md`）——属用户私有偏好，
  本次仅改项目内 `c:/Projects/KENSPC/Claude Plugin/CLAUDE.md`。

**Deferred:**

- 是否要为 VS Code Claude Code 宿主提供任何形式的 live 状态反馈——目前
  plugin 无可用机制，先观察 VS Code 是否会跟进 CLI 的底栏 UI。

## Failure Modes

如果交付后出现以下情况，等于做错了：

1. **Guard 与文本不同步**：删除了 SKILL/agent 中的英文化语句但 AC6 grep
   guard 还在 release-checklist 里跑，导致 release 时 CI 失败。或者反过来，
   guard 已删但漏改某个 agent 文件，行为不一致，反而比之前还乱。
2. **误删 result table**：在删 Planned Dispatch 表的 Status 列时，连带
   把 dispatch 之后的 result table（带 Status 列、事后写、能正确填值）
   一起删了。result table 是合法的，必须区分清楚。
3. **半截改造**：5 个 SKILL.md 中只改了 4 个，或者 5 个 agent .md
   中只改了部分——因为这些文件之间有 byte-identity 共享段位（见 CLAUDE.md
   "Maintenance note"），漏改会触发 drift script。
4. **误伤 Discovery Framework 例句**：把 `shared/discovery-framework.md`
   中的中文 illustrative phrasings 当成"英文化遗漏"删掉——这些是被 CHANGELOG
   明确豁免的 deliberate exception。
5. **误改全局 CLAUDE.md**：把 `~/.claude/CLAUDE.md`（user-private）当成
   项目文件改动——只能动项目内的 `CLAUDE.md`。
6. **AC8 反向化做成"删 AC8"而非"反向 enforce"**：直接删 AC8 等于放任
   未来的 plugin 修订把 Status 列加回来；正确做法是把 AC8 改成"反向
   guard"——主动 enforce 不出现 Status 列。

## The Hard Part

最需要判断的是 **AC6 / AC8 这两条 release-check guard 的处置方式**。

它们是 v3.0.1 刚刚加固过的（见 `CHANGELOG.md` L46–54），现在要主动撤销
它们的方向。三种处理路径已比较：

| 选项 | 方向 | 决定 |
|---|---|---|
| A. 删 AC6、删 AC8 | 完全放任 | ❌ 不取——等于让未来修订无障碍地把 anti-pattern 加回来 |
| B. 删 AC6，把 AC8 改成反向 guard | 一删一翻 | ✅ 采用 |
| C. 把两条都改成反向 guard | 双反向 | ❌ 不取——AC6 没有合理的反向语义可写（"必须双语"是错的） |

**采用 B 的理由**：
- AC6（英文化）属于"约束输出语言"，本身就不该有约束——既不该正向，也不该
  反向。Claude 应根据用户语言自然决定，AC6 的恰当结局是消失。
- AC8（Status Table）属于"约束 markdown 制品形态"——这是合法的 enforcement
  对象，只是方向反了。把它从「enforce 错事」翻成「enforce 对事」即可：
  Planned Dispatch 表必须存在并列出所有 agents（保留可见性），但不得有
  Status 列或 `pending`（不撒谎）。

这条 hard-part 判断也回答了 brief 的元问题：v3 的 bitter-lesson 哲学
不是"少加 guard"，而是"guard 应当 enforce 真正有效的事"。删 AC6 + 反向
AC8 是对这个哲学的一次更彻底的执行。

## Constraints

**版本号**：建议作为 v3.0.2 patch 发布。
- 不引入新 SKILL 接口、不变更 agent 名称、不改变 dispatch 数量。
- 但 README 会移除一条已宣传的 "English-only output" feature——严格来说
  这是行为可见的回退，部分用户可能依赖。考虑是否升 v3.1.0。
- 倾向 v3.0.2：v3.0.0 引入的两条都属于"v3 自身的执行偏差"而非真实功能，
  撤销它们是修正而非破坏，patch 语义合适。

**跨文件一致性**：
- 5 个 SKILL.md 的 Planned Dispatch 表必须改造一致。
- 5 个 agent .md 中的英文化语句必须一并清掉。
- `scripts/check-review-agent-drift.sh` 和
  `scripts/check-canonical-dispatch.sh` 在改动后须重跑，确保字节恒等
  不变量未被破坏（受影响行不在共享段内的话应自动通过）。

**流程**：
- 改完后必须按 `docs/release-checklist.md` 的 smoke checklist 走一遍
  （加载 plugin、触发每个 entry-point 的首屏交互），AC1–AC11 的机械检查
  无法捕获 SKILL.md 字段缺失或路径破损。

**语言决策**：
- 移除强制英文输出后，agent 文件中保留的语言相关指引应仅约束 *code 类
  artifacts*：commit messages、code comments、变量名、log messages
  等仍保持英文（这与本次撤销的"summaries / progress messages 的英文
  约束"是不同概念）。

## Context

**v3.0.0 的 bitter-lesson 哲学**：v3.0.0 主动删除了 anti-rationalization
表、假数字 Red Flags、`ULTRATHINK` directives、大写 `MUST`/`NEVER`/
`CRITICAL`/`STOP immediately` 等"正向 enforce 错事"的脚手架。但同一版本
*同时*引入了：

- "English-only output" 作为六条设计原则之一（CHANGELOG.md L75–82）。
- "Dispatch Status Tables (Planned Dispatch + result table)" 在所有
  dispatching skill（CHANGELOG.md L106–108）。

这两条本身就违反了 v3.0.0 自己的哲学：

- 强制英文 = 用 SKILL 文本约束 Claude 的运行时输出语言决策——本应交由
  上下文判断，跟"删 ULTRATHINK 让 effort: frontmatter 决定 reasoning 深度"
  是同一类问题。
- Status Table = 用静态 markdown 假装提供 live UX，但 markdown 写出去
  即冻结，dispatch 后无法回写——这是一个"加了表格以为对用户好，但实际上
  撒谎"的脚手架。

v3.0.1（昨天发布）甚至**加固**了这两条对应的 AC6 / AC8 grep guard
（CHANGELOG.md L46–54），现在又要反向调整，是有点反复，但属于"修正
v3 自身的执行偏差"，不是"反复改主意"。

**Status Table 失效的根因**：markdown 是字面文本，写出去即冻结。Claude
的 tool-use（包括 Agent dispatch）走另一个 channel，无法回头编辑先前的
markdown 输出。dispatch 之前渲染的 `pending` 表格永远停在 `pending`，
不管 agents 跑没跑完。CLI 新底栏才是真正的 live state；VS Code Claude
Code 暂时没有同等组件，所以 plugin 内的静态表反而是误导而非补偿。

## Discovery Notes

- 用户最初把两件事提为两个独立问题（语言强制 + 状态表 pending），
  Discovery 中合并为一个 brief，因为根因相同——都是 v3 引入了违反 v3
  自身哲学的"正向约束"。
- Status Table 失效根因在 Discovery 中确认：markdown 字面文本不可回写，
  Claude tool-use channel 与文本输出 channel 分离。
- Issue B 的处置方式比较了 4 条路径（完全删 / 删 Status 列 / 加注释 /
  环境探测），决定走 (2)：保留 Planned Dispatch 表的可见性意图，去掉
  误导的 Status 列。表头变为 `# / Agent / Role`，引导句改成"即将派发
  以下 Agents"或 "Planned Dispatch:"。
- AC6 / AC8 处置选了 B 方案：删 AC6（无合理反向语义）、反向 AC8
  （enforce "必须有 Planned Dispatch 表，但不得有 Status 列"）。这条
  判断同时回答了 brief 的元问题：bitter-lesson 不是"少加 guard"，而是
  "guard 应 enforce 真正有效的事"。
- 全局 user-private `~/.claude/CLAUDE.md` 与项目内 `CLAUDE.md` 已区分，
  本次只动项目内的。
- `shared/discovery-framework.md` 中的中文"How to ask"例句已确认为
  CHANGELOG 中声明的 deliberate exception，本次不动。
- 版本号选择倾向 v3.0.2 patch，但 README 移除一条已宣传 feature 的
  可见性影响留待 plan 阶段最终确定。
