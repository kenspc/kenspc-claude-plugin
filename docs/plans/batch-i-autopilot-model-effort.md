# Batch I — autopilot 为 headless worker 明确传递 model 和 effort（4.2.0）

Status: ruled（设计已于 2026-09-28 在 KENSPC Workbench 锁定）

## Background

autopilot 的 worker 是各自独立的 `claude -p` process。run.sh 和文件都写着 worker "follows the session's model"，其实不然：worker 会自己去解析 model 和 effort。2026-09-28 的 probe（Claude Code 2.1.283）结果如下：

- P1：按 run.sh 方式启动的 worker，跑的是 settings 解析出来的值（在 Sim 的机器上是 Opus 5.5 / xhigh），不是主 session 当下的选择。
- P6：resume 会保留 model，但**不会保留 effort**。第一轮用 `--effort low`，resume 时不带 flag，effort 就回到 settings 的值。
- P7：在 worker 里，subagent frontmatter 的 `effort` 照样生效；`model: inherit` 解析成 worker 自己的 model。
- P0：每条 assistant 记录都有 `effort` 字段，记的是实际套用的值（不支持 effort 的 model 没有这个字段）；model 在 `message.model`。这是没有文件记载的内部格式，只能当证据，不能当契约。
- P2：主 session 可以从 Bash 的 `$CLAUDE_EFFORT` 读到自己的 effort，也可以用 `$CLAUDE_CODE_SESSION_ID` 找到自己的 transcript，从中读出 model。
- 官方规则：`CLAUDE_CODE_EFFORT_LEVEL` 优先于 `--effort` 和 `/effort`。
- 官方文件：在 `-p` 模式下，Fable 的请求如果会计入 usage credits，Claude Code 不会询问，直接扣款；Max 方案每周可以把最多 50% 的用量限额用在 Fable 上，不另收费。

## Locked design

以下各点不可更改；提问若要重开其中任何一点，一律拒绝。

- L1 没有声明的角色，worker 沿用主 session **当下**的 model 和 effort：effort 取自 `$CLAUDE_EFFORT`，model 取自主 session 自己的 transcript。读不到的那一项就不传，并在记录里写明 "not determined"。
- L2 声明只写在 spec 的 `## Autopilot`，按角色写。plugin 本身不带任何默认表，plugin 的档案里不出现任何 model 名称。
- L3 请求值和实际值不一致时，记录下来并在报告里标出，不停止。唯一例外：`CLAUDE_CODE_EFFORT_LEVEL` 已设、而某个角色声明了 effort 时，视为 settings stop，停下来并点名这个变量。
- L4 Fable 可以用于 worker，无论是声明的还是沿用主 session 的；README 写明计费风险。
- L5 run.sh 的新启动和 `--resume` 两条路径，都要带上该角色的 model 和 effort flag。
- L6 每个 worker 结束后，从它的 transcript 读出实际的 model 和 effort，写进 state file 和 reviewer report。
- L7 更正 run.sh、SKILL.md、CLAUDE.md、README 里所有 "the worker follows the session's model" 之类不准确的说法。
- L8 README 的 Known behavior 写明：角色的 model 会连带影响该 worker 里所有 subagent；frontmatter 设了 `xhigh` 的 agent 不受角色 effort 影响。
- L9 字段文法：`Role settings:` 的子项为 `- <role>: model <model>[, effort <level>]`，或 `- <role>: effort <level>`。`<role>` 是 `S1`、`S2`、`S3`、`S3b`、`S4`、`S5`、`S6` 之一；`<model>` 是一个不含空白和逗号的 token，照原样传给 `--model`；`<level>` 是 `low`、`medium`、`high`、`xhigh`、`max` 之一。未知角色、同一角色出现两次、或任何一部分不符文法，都是 settings stop。
- L10 model 一致性的判定：先去掉请求值末尾的 `[...]`，再看实际的 model ID 是否（不分大小写）包含它。effort 一致性的判定：实际的 `effort` 字段等于请求值。实际记录里没有 `effort` 字段，也算不一致（"effort not applied"）。
- L11 每次启动，skill 都要明确设定 `AUTOPILOT_MODEL` 和 `AUTOPILOT_EFFORT`：有值就设成该值，没有就设成空字串；run.sh 把空字串当作没设。S4 启动的嵌套 session 经由环境变量沿用 S4 的值，这一点要写进文件。
- L12 transcript 用 session id 找（`~/.claude/projects/*/<session-id>.jsonl`），不推算目录名；只读主循环的 assistant 记录，不读 subagent 的档案。transcript 找不到，或读不到某个字段，就记为 "not observed"，绝不因此停止。

## Implementation Steps

### Step 1: run.sh

- `AUTOPILOT_MODEL` 非空时传 `--model <value>`；`AUTOPILOT_EFFORT` 非空时传 `--effort <value>`。新启动和 `--resume` 两条路径都要传（L5、L11）。
- 档头注释改成准确的说法（L7），并列出这两个新变量。
- `--self-test` 增加以下情况：两个变量都设值时，新启动和 resume 都带有两个 flag；设成空字串或没设时，两个 flag 都不出现。

DONE：`run.sh --self-test` 印出 `self-test passed`；新增的情况都包含在 self-test 里。

### Step 2: run.ps1

照 Step 1 同样改。只在 macOS 上检查，跟 batch F 一样。

DONE：`run.ps1` 的档头和参数处理与 run.sh 对等；README 维持"只在 macOS 检查过"的说明。

### Step 3: autopilot SKILL.md

- 在字段表加上 `Role settings:`（L9），默认值是 empty。
- start checks 加两项：L9 的文法检查；L3 的 `CLAUDE_CODE_EFFORT_LEVEL` 检查——在主 session 的 Bash 里执行 `printenv CLAUDE_CODE_EFFORT_LEVEL`，有值、而且有任何角色声明了 effort，就是 settings stop，并点名这个变量。
- Phase 0 决定沿用给主 session 的值（L1），写进 state file。
- 每次启动都按 L11 设定两个变量；resume 时沿用该 tag 原本的值。
- 每个 `<tag>.exit` 出现之后，按 L12 读出实际值，按 L10 判定，写进 state file，一行一个 worker：
  `<tag> requested <model|—>/<effort|—> (<declared|pass-through>) applied <model|not observed>/<effort|not observed>[ MISMATCH: <what>]`
- settings line 末尾加上：`, roles <S2 <model>/<effort>; …|none declared>, pass-through <model|not determined>/<effort|not determined>`
- Reviewer report 在 `Total cost` 之前加一行：`- Models and efforts: <n> workers, <k> mismatches` 并附上 state file 里那几行；没有不一致时写 `mismatches: none`。
- S4 的 task block 注明：嵌套 session 经由环境变量沿用 S4 的值（L11）。
- 更正文中所有 "follows the session's model" 之类的说法（L7）。

DONE：以上每一项都能在 SKILL.md 里找到对应文字；gates 表和 stop conditions 反映新的 settings stop；plugin 的档案里不出现任何 model 名称（`check-no-model-names.sh` 通过）。

### Step 4: README 和 CLAUDE.md

- plugin README 的 autopilot 一节：新字段、沿用规则、记录格式。
- plugin README 的 Known behavior 加四项：
  - 角色 model 会连带影响 subagent（L8）；
  - 设了 xhigh 的 agent 不受角色 effort 影响（L8）；
  - Fable 在 `-p` 模式下计入 usage credits 时不会询问就直接扣款：Max 方案超过每周 50% 的 Fable 份额时会发生；在 Fable 需要 usage credits 的方案上，每次都会发生（L4）；主 session 跑 Fable 时，所有没有声明的角色也会跟着跑 Fable；
  - transcript 的字段是没有文件记载的格式，读不到时记为 "not observed"（L12）。
- CLAUDE.md：更正 worker 跟随 session model 的说法（L7）；guard 和 self-test 的计数有变动的话一并更新。

DONE：`grep -rn "follows the session's model" plugins/kenspc CLAUDE.md README.md` 没有结果；pre-flight block 全部 exit 0。

### Step 5: CHANGELOG

新增 4.2.0 条目：改了什么，以及对"worker 跟随 session"这个旧说法的更正。4.1.0 以前的条目不改写。

DONE：条目存在，日期在发布准备时填入。

## Out of scope

- 由主 session 按角色自行判断 model 或 effort（C 方案）；每次 subagent dispatch 都传 model（D 方案）。
- plugin 自带的角色默认表。
- 改变 subagent 的 `model: inherit` 或 frontmatter effort。
- kenspc-dev-setup 的 effort 设定（另案）。
- Windows 上的 `run.ps1` 验收。
- 在验收中实际跑 Fable。

## Constraints

- plugin 档案中不出现 model 名称；文件里的例子一律用 `<model>` 这类占位符。
- 字段一律以英文 label 书写；写作规则遵守 CLAUDE.md 的 Writing Rules。

## Testing Strategy

见 `## Autopilot` 的 `Acceptance:`。

## Clarifications during implementation

- **C1（Phase 0，名称与记录路径）** batch 名称按 autopilot skill 的规则取 spec 的档名 `batch-i-autopilot-model-effort`，用在 workspace 里的 tag、日志和 prompt 档名上；主 session 的名称是 `batch-i-main`（ListAgents 第一行）。验收记录写在 `docs/dry-runs/batch-i-acceptance.md`，也就是 `Allowed files:` 点名的路径，而不是 skill 模板由 batch 名称推出的 `docs/dry-runs/batch-i-autopilot-model-effort-acceptance.md`。commit 标题里的 batch 名称写 `i`，跟本 spec 自己的 commit（`docs(plans): add batch i spec`）及仓库一贯的写法一致。理由：spec 明确点名了记录的路径，而模板推出的路径落在 `Allowed files:` 之外。
- **C2（Phase 0，Allowed files 的范围）** `Allowed files:` 管的是本批次的交付档案。流程本身的产物不在此列：S2 写在 `docs/tasks/` 的 task 文件、主 session 记在本 spec 的 clarification，以及 S6 按 `Release preparation: default` 用 `git rm` 移除的 spec 和 task 文件。理由：`Release preparation: default` 本来就要移除这两份文件，可见改动它们是预期之内的事。
- **C3（Phase 0，第 6 个验收案例）** 第 6 个案例开头的 `（optional）` 视为 `(optional)` 标记，不计它的位置和全形括号。这只在预算检查不通过、需要删减案例时才用得上。
- **C4（Phase 0，Documentation impact）** 本 spec 没有 `## Documentation impact` 一节。文件的更新就是 Step 4（README、CLAUDE.md）和 Step 5（CHANGELOG），所以 task 文件不需要另外的 Doc-sync task；若 task-document-reviewer 报出这个缺口，以 Step 4 和 Step 5 作答。
- **C5（S2 确认，部分声明；用户裁定）** 只声明 model 或只声明 effort 的角色，没声明的那一项用沿用值，也就是主 session 当下的值；沿用值读不到时，那一项就不传。这样的角色在 state file 行里标作 `declared`，settings line 的 roles 列表里没声明的那一项写 `—`。
- **C6（S2 确认，实际值的归结；用户裁定）** 读 transcript 里全部主循环 assistant 记录。只有一个不同值就照原样印出，有几个不同值就用 `+` 连起来；每一条都相符才算一致。resume 的 tag 那一行涵盖整个 session，包括之前的那一轮。
- **C7（S2 确认，timeline）** timeline 的 `start` 行不记录 model 和 effort。Step 1 列出的 run.sh 改动不包括这一项，而 state file 已经按 worker 记下请求值。
- **C8（S2 确认，不改的句子）** CLAUDE.md 讲 `check-no-model-names.sh` 的那句 "Skills and agents follow the session's model and effort"，以及 `scripts/check-no-model-names.sh` 档头和错误讯息里的同类说法，都保持不变。它们讲的是同一个 session 里的 skill 和 agent，说法准确；L7 要更正的只是关于 worker 的不准确说法，目前只在 run.sh 和 run.ps1 的档头。
- **C9（S2 确认，改动的边界）** settings line 末尾加上新的一段之后，plugin README 的 Known behavior 和 release checklist smoke 第 11 行里"以 `wait headless` 结尾"的说法都跟着改写。不新增 smoke 检查，根目录 README 不改。
- **C10（S2 确认，not observed；用户裁定）** `not observed` 照原样印出，不加 `MISMATCH:`，也不算进 reviewer report 的 `<k> mismatches`。
- **C11（S2 确认，编号规则；用户裁定）** 本 spec 的编号标签（Locked design、Background 里的 probe、clarification 的编号）不写进任何交付档案，并用 diff grep 检查。
- **C12（S2 结束，model 名称的范围）** L2 和 Constraints 所说的"plugin 的档案里不出现 model 名称"，范围是 `check-no-model-names.sh` 扫描的档案（`skills/`、`agents/`、`commands/`、`shared/`），Step 3 的 DONE 就是这样写的。L4 和 Step 4 要求 README 写出 Fable 的计费风险，所以 README 的 Known behavior 里 Fable 计费那一项是本批次唯一写出 model 名称的地方，其他例子一律用 `<model>` 占位符。

## Autopilot

- Mode: plugin
- Version: 4.2.0
- Budget: USD 200
- Must read: CLAUDE.md, plugins/kenspc/skills/autopilot/SKILL.md, plugins/kenspc/skills/autopilot/scripts/run.sh, docs/dry-runs/batch-f-acceptance.md
- Prior specs: 2375556^:docs/plans/batch-f-autopilot.md
- Allowed files: plugins/kenspc/skills/autopilot/SKILL.md, plugins/kenspc/skills/autopilot/scripts/run.sh, plugins/kenspc/skills/autopilot/scripts/run.ps1, plugins/kenspc/README.md, plugins/kenspc/CHANGELOG.md, plugins/kenspc/.claude-plugin/plugin.json, .claude-plugin/marketplace.json, CLAUDE.md, README.md, docs/release-checklist.md, docs/roadmap.md, docs/dry-runs/batch-i-acceptance.md, scripts/
- Zero diff: plugins/kenspc/agents/, plugins/kenspc/shared/, plugins/kenspc/skills/init-project/, plugins/kenspc/skills/generate-plan/, plugins/kenspc/skills/generate-task/, plugins/kenspc/skills/task-implement/, plugins/kenspc/skills/task-review/
- Acceptance:
  - `run.sh --self-test`（driver copy） — PASS: 印出 `self-test passed`；stub 的 `<tag>.err` 显示：两个变量都设值时，新启动和 resume 都带 `--model` 和 `--effort`；设为空字串或没设时两者都没有
  - 用 driver 实跑一个 worker：`AUTOPILOT_MODEL=sonnet AUTOPILOT_EFFORT=low`，prompt 只有一句，结束后用同样的变量 `--resume` 一次 — PASS: transcript 里两次执行的主循环 assistant 记录全部是 `effort: low`，`message.model` 都包含 `sonnet`
  - 嵌套 autopilot，headless，跑在一个小 seed 上：spec 的 `Role settings:` 写 `- S2: model sonnet, effort low` 和 `- S6: model haiku, effort low`，其余角色不声明，`Acceptance: none` — PASS: settings line 列出两个角色和 pass-through 的值；state file 每个 worker 一行；S2 实际值包含 `sonnet` 且 effort 是 low；S3 和 S3b 的实际值等于嵌套主 session 的 model 和 effort；S6 标出 `MISMATCH: effort not applied`，但 run 照常跑到 `Autopilot finished`；reviewer report 有 `Models and efforts` 一行，写着 1 个不一致
  - 嵌套 autopilot，以 `CLAUDE_CODE_EFFORT_LEVEL=high` 启动，spec 声明 `- S2: effort low` — PASS: 在第一个 worker 之前以 `Autopilot stopped:` 结束，讯息点名 `CLAUDE_CODE_EFFORT_LEVEL`；timeline 里没有任何 `start` 行
  - 嵌套 autopilot，spec 写 `- S3: effort extreme` — PASS: settings stop，讯息点名 `Role settings` 和 `extreme`；没有 worker 启动
  - （optional）嵌套 autopilot，没有 `Role settings:` — PASS: 每个 worker 的实际值都等于嵌套主 session 的值，settings line 写 `roles none declared`
  - `bash scripts/check-all.sh --self-test` — PASS: 全部 exit 0，计数与 checklist 一致
- Release preparation: default