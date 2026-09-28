# Batch I — autopilot 为 headless worker 明确传递 model 和 effort — Task Document

## Context

依据 `docs/plans/batch-i-autopilot-model-effort.md`（下称 spec）拆出的任务。autopilot 的每个 worker 是独立的 `claude -p` process，会按自己的 settings 解析 model 和 effort，并不沿用启动它的主 session。本批次让 skill 按角色传递 model 和 effort（spec `## Autopilot` 的 `Role settings:` 声明值，没有声明就用主 session 当下的沿用值），让 driver 在新启动和 `--resume` 两条路径上都带 flag。每个 worker 结束后，skill 从它的 transcript 读出实际值、判定是否一致，再记进 state file 和 reviewer report。

Related plan: `docs/plans/batch-i-autopilot-model-effort.md`。spec 的 Locked design（L1–L12）不可更改；S2 确认时的裁定记在 spec 的 `## Clarifications during implementation`（C5–C11），下面的任务在用到时注明。本文件用 L<n>、C<n> 指称 spec 的各点，这些编号只是给实作者看的指针（C11）。

所有任务的共同约束：
- 只改 spec `## Autopilot` 的 `Allowed files:` 列出的档案；`Zero diff:` 列出的路径不动。
- plugin 的 skill、agent、command 和 shared 档案里不出现任何 model 名称（家族名或 `claude-` 开头的 ID），由 `check-no-model-names.sh` 检查。文件里的例子一律用 `<model>` 这类占位符。
- spec 的编号标签（Locked design 的 L1–L12、Background 的 probe P0–P7、clarification 的 C1–C11）不写进任何交付档案（C11）。每个任务都用这个 diff grep 检查自己改动的档案，必须没有输出：
  `git diff -U0 <task 开始前的 HEAD> -- <本任务的档案> | grep -E '^\+.*\b(L([1-9]|1[0-2])|P[0-7]|C([1-9]|1[01]))\b'`
- 每个必须没有输出的搜索（上面的编号标签 grep、各任务的 `follows the session's model` grep），先对一个必定命中的对象跑同一个 pattern，对照命中了，空结果才算通过：编号标签的 pattern 对 spec 本身（`grep -cE '\b(L([1-9]|1[0-2])|P[0-7]|C([1-9]|1[01]))\b' docs/plans/batch-i-autopilot-model-effort.md` 大于 0），`follows the session's model` 对 spec 或 task 开始前的档案（`git show <task 开始前的 HEAD>:<档案>`）。理由：用户层 CLAUDE.md 要求必须为空的搜索带一个必定命中的对照，否则 pattern 写错、档案路径写错，看起来都跟通过一样。
- 新写的规则按 CLAUDE.md 的 Writing Rules 附上 "Why:" 散文。证据用自己的话写明什么失败、在哪个命令上，不引用 probe 或 dry-run 的编号。
- 字段 label 和固定行（settings line、state file 行、reviewer report 字段）一律用英文。

Dependency note: Task 2 depends on Task 1; Task 4 depends on Task 1 and Task 3; Task 5 depends on Tasks 1–4 (`Depends on: Task 1-4`); Task 6 depends on Tasks 1–5 (`Depends on: Task 1-5`). spec 没有 `## Documentation impact` 一节，文件的更新就是 Task 5（spec Step 4）和 Task 6（spec Step 5），所以没有 Doc-sync task（C4）。

## Tasks

### Task 1: run.sh 按两个新变量传 `--model` 和 `--effort`

**Status:** DONE

**Implementation notes:**
- Decisions: 两个 flag 加在共用的 `args` 末尾（`APPEND_SP` 之后），不写进 `extra`，所以 timeline 的 `start` 行不变。新增的两次新启动用独立的 tag：`selftest-s3`（两个变量设成 `selftest-model`/`low`）和 `selftest-s4`（两个都设成空字串），放在失败 stub（`selftest-s2`）之后、命令行 resume 之前；每次都先等 `.exit` 出现再读 `.err`，因为 stub 的参数是它启动后才写进 `.err` 的。变量用 shell 赋值、launch 之后 `unset`，写法跟现有的 `saved_exe` 换 stub 一致；命令行 resume 则跟另外三个变量一样放在环境前缀里。
- Changes/tradeoffs: 档头 "Always passed" 那段拆成两句：continue flag 那半句保留，另起一句 "Why" 说明 worker 按自己的 settings 解析、resume 保留 model 不保留 effort，证据用自己的话写（不带 `--effort` 的 resume 跑在 settings 的 effort 上）。突变检查在 `$TMPDIR` 下的副本上做，工作树没有改动过：把 `args+=(--effort …)` 换成 `:`，self-test exit 1，讯息是 `selftest-s3.err does not show --effort low`；把 `args+=(--model …)` 换成 `:`，exit 1，讯息是 `selftest-s3.err does not show --model selftest-model`；原档再跑一次 exit 0。另外做了两次任务没要求的突变：把非空判断改成只看有没有设（`${AUTOPILOT_EFFORT+x}`），`selftest-s4` 的空字串检查报错；只在新启动时传 `--effort`，`selftest-s1-r1` 的 resume 检查报错。调用端环境里已有 `AUTOPILOT_MODEL`、`AUTOPILOT_EFFORT` 时 self-test 照样通过，第一次启动前的 `unset` 挡住了它们。commit 里除了 `run.sh` 还有本 task 文件（状态和这段 notes）：实作流程要求代码和状态在同一个 commit，task 文件属于流程产物，不是交付档案；后面各任务同样处理。

修改 `plugins/kenspc/skills/autopilot/scripts/run.sh`，只改这一个档（spec Step 1；L5、L7、L11）。

- `launch()`：`AUTOPILOT_MODEL` 非空时加 `--model <value>`，`AUTOPILOT_EFFORT` 非空时加 `--effort <value>`。空字串与没设同样处理，写法跟 `AUTOPILOT_PLUGIN_DIR` 等三个选填变量一样（`${VAR:-}` 非空才加）。两个 flag 加进新启动和 resume 共用的 `args`，两条路径就都带上了。
- timeline 的 `start` 行保持原样，不记录 model 和 effort（C7）。
- 档头注释：
  - Environment 一节列出 `AUTOPILOT_MODEL` 和 `AUTOPILOT_EFFORT`：非空才传对应的 flag，空字串等同没设。
  - "Always passed" 一段里 "No model flag … the worker follows the session's model" 这句说法不准确，改成：没有 `--model`、`--effort` 的 worker 会按它自己的 settings 解析这两项，不会沿用启动它的 session；resume 保留 model 但不保留 effort，所以新启动和 resume 都要带。continue flag 那半句（resume 明确指名 session）保留。
- `self_test()`：
  - 第一次启动前，和另外三个选填变量一起 `unset AUTOPILOT_MODEL AUTOPILOT_EFFORT`，并断言它的 `.err` 里没有 `--model`、`--effort`（没设的情况）。
  - 新增一次两个变量都设值的新启动，断言 `.err` 显示 `--model <值>` 和 `--effort <值>`。
  - 经由命令行的 resume 启动（`$RTAG`）同时设这两个变量，断言 `.err` 显示两个 flag 和各自的值。
  - 新增一次两个变量都设成空字串的启动，断言 `.err` 里两个 flag 都不出现。
  - 测试值用占位名（例如 `selftest-model` 和 `low`），不能用 model 家族名或 `claude-` 开头的 ID：`check-no-model-names.sh` 会扫描 `skills/` 下的这个档。
  - `self_test()` 上方按顺序列出失败项的注释，补上新增的检查。

**Acceptance criteria:**
- `bash plugins/kenspc/skills/autopilot/scripts/run.sh --self-test` 印出 `self-test passed` 并 exit 0。
- self-test 里 stub 的 `.err` 显示：两个变量都设值时，新启动和 resume 都带 `--model <值>` 和 `--effort <值>`；两个都设成空字串、或两个都没设时，`--model` 和 `--effort` 都不出现。
- 这个检查能失败：临时拿掉 `--effort` 的传递，self-test 以 exit 1 结束，并点名缺少的 flag；`--model` 照样检查一次；还原后 self-test 再次通过。突变不提交，在本任务的 Implementation notes 里记下做过这两次检查。
- `grep -n "follows the session's model" plugins/kenspc/skills/autopilot/scripts/run.sh` 没有结果。
- 共同约束的编号标签 grep 对 `run.sh` 没有输出。
- `bash scripts/check-all.sh` exit 0，其中 `check-no-model-names.sh` 通过。
- 本任务的 commit 只改动 `run.sh`。

---

### Task 2: run.ps1 做对等修改

**Status:** DONE

**Implementation notes:**
- Decisions: 两个 flag 用现有的 `$optional` 字串拼进 inner script 的 `$argv`（`ConvertTo-Literal` 包成单引号字面值），新启动和 resume 共用，也不写进 `$extra`，timeline 的 `start` 行不变。run.ps1 的 self-test 已经用掉 `selftest-s1` 到 `selftest-s8`，新增的两次新启动用 `selftest-s9`（两个变量设成 `selftest-model`/`low`）和 `selftest-s10`（两个都设成空字串），放在失败 stub（`selftest-s2`）的检查之后，位置与 `run.sh` 对应。档头 Environment 一节和 "Why --model and --effort" 那段与 `run.sh` 逐字相同（两段都用 `diff` 比对过）。
- Changes/tradeoffs: 在本机 pwsh 7.6.6 上确认过，`$env:X = ''` 会保留一个空字串变量，不会移除它，所以 `selftest-s10` 在这台机器上真的测到空字串的情况；注释里仍写明 pwsh 若移除它，这次启动就等于没设，flag 照样不出现。突变检查在 `$TMPDIR` 下的副本上做：删掉传 `--effort` 的那一行，self-test exit 1，讯息 `selftest-s9.err does not show --effort low`；删掉传 `--model` 的那一行，exit 1，讯息 `selftest-s9.err does not show --model selftest-model`；把 effort 的非空判断改成只看是否为 `$null`，`selftest-s10` 的空字串检查报错；原档 self-test 通过，解析检查 exit 0。

Depends on: Task 1

修改 `plugins/kenspc/skills/autopilot/scripts/run.ps1`，只改这一个档（spec Step 2）。改法与 Task 1 之后的 `run.sh` 对等。跟 batch F 一样，只在 macOS 上检查。

- `Invoke-Launch`：`$env:AUTOPILOT_MODEL` 非空时传 `--model`，`$env:AUTOPILOT_EFFORT` 非空时传 `--effort`，判断方式跟现有三个选填变量一样（`[string]::IsNullOrEmpty`）；新启动和 resume 都带。timeline 的 `start` 行保持原样（C7）。
- 档头：Environment 一节列出这两个变量，规则与 `run.sh` 相同；"Always passed" 一段改成与 `run.sh` 同样的准确说法。
- `Invoke-SelfTest`：覆盖跟 Task 1 一样的四种情况：
  - 没设：第一次启动前把 `$env:AUTOPILOT_MODEL` 和 `$env:AUTOPILOT_EFFORT` 清成 `$null`；
  - 两个都设值的新启动；
  - 两个都设值的 resume；
  - 两个都设成空字串：pwsh 可能把空字串赋值当作移除变量，不管怎样，flag 都不应出现。
  测试值一样用占位名。

**Acceptance criteria:**
- 在 macOS 上执行 `pwsh -NoProfile -File plugins/kenspc/skills/autopilot/scripts/run.ps1 --self-test`，印出 `self-test passed` 并 exit 0（需要 PowerShell 7.3 或以上；本机是 7.6.6）。
- 解析检查 exit 0：`pwsh -NoProfile -Command '$e = $null; [void][System.Management.Automation.Language.Parser]::ParseFile("plugins/kenspc/skills/autopilot/scripts/run.ps1", [ref]$null, [ref]$e); if ($e.Count) { $e; exit 1 }'`。
- self-test 的 stub `.err` 覆盖 Task 1 的四种情况，结果相同。
- 这个检查能失败：临时拿掉 `--effort` 的传递，self-test 以 exit 1 结束，并点名缺少的 flag；还原后通过。突变不提交，在 Implementation notes 里记下。
- 档头列出的环境变量和规则与 `run.sh` 一致；`grep -n "follows the session's model" plugins/kenspc/skills/autopilot/scripts/run.ps1` 没有结果。
- 共同约束的编号标签 grep 对 `run.ps1` 没有输出。
- `bash scripts/check-all.sh` exit 0。
- 本任务的 commit 只改动 `run.ps1`。

---

### Task 3: SKILL.md — `Role settings:` 字段、两个 settings stop、沿用值和 settings line

**Status:** DONE

**Implementation notes:**
- Decisions: 字段表的 `Role settings:` 一行放在表末（`Workspace:` 之后），表下加一段说明部分声明和 `not determined` 的处理，并附 Why（plugin 不带默认表、不写 model 名称）。沿用值写成 Phase 0 里新的一小节 `### The pass-through values`，放在 `### The wait path` 之后，因为两者都是"在这里决定一次、记进 settings line"；主循环 assistant 记录写成"`type` 为 `assistant` 的行，在该档本身、不在 subagent 的档里"，写之前用本机一份 transcript 核对过 `type`、`message.model`、`effort` 这三个字段确实存在。两个新的 start check 紧接在通用文法检查之后，在 clean tree 检查之前，都在第一个 worker 启动之前。stop conditions 加了第 10 项，把两个新的 settings stop 点名写出；gates 表那一行也写出这两项。
- Changes/tradeoffs: Phase 0 的 DONE 句原本写 settings line "ending `wait <interactive|headless>`"，改成 "ending with the pass-through values"，所以 `wait <interactive|headless>` 现在只出现在 settings line 模板里。settings line 模板下加了一段说明 roles 列表的写法（`S3 —/low` 这个例子里 `—` 代表没声明的那一项）和 `none declared`，并附 Why。worker 不沿用主 session 的那句更正、`AUTOPILOT_MODEL`/`AUTOPILOT_EFFORT` 的设定、实际值的读取，都留给 Task 4。

修改 `plugins/kenspc/skills/autopilot/SKILL.md`，只改这一个档（spec Step 3 的前半；L1、L2、L3、L9、L12；C5、C9）。

- § The `## Autopilot` section 的字段表加一行 `Role settings:`：
  - 值是子项，每项为 `- <role>: model <model>[, effort <level>]` 或 `- <role>: effort <level>`；
  - `<role>` 是 `S1`、`S2`、`S3`、`S3b`、`S4`、`S5`、`S6` 之一；
  - `<model>` 是一个不含空白和逗号的 token，照原样传给 `--model`；
  - `<level>` 是 `low`、`medium`、`high`、`xhigh`、`max` 之一；
  - 默认 empty，也就是每个角色都用沿用值。
  附 Why：声明只写在 spec 里，plugin 不带默认表，也不写任何 model 名称，因为写死的 model 名称会在下一个 model 世代悄悄过时。
- 只声明了一部分的角色（只写 model，或只写 effort）：没声明的那一项用沿用值；沿用值是 `not determined` 时，那一项就不传（C5）。
- § The start checks 加两项，都在第一个 worker 启动之前：
  1. `Role settings:` 的文法：未知角色、同一角色出现两次、任何一部分不符文法，都是 settings stop。讯息点名 `Role settings` 和出错的值，例如 `- S3: effort extreme` 的讯息要点名 `extreme`。
  2. 在主 session 的 Bash 执行 `printenv CLAUDE_CODE_EFFORT_LEVEL`：有值、而且有任何角色声明了 effort，就是 settings stop，讯息点名 `CLAUDE_CODE_EFFORT_LEVEL`。Why：这个变量优先于 `--effort`，声明的 effort 会被默默盖掉。
- Phase 0 决定沿用值：
  - effort 取主 session Bash 里的 `$CLAUDE_EFFORT`；
  - model 取主 session 自己的 transcript：用 `$CLAUDE_CODE_SESSION_ID` 找 `~/.claude/projects/*/<session-id>.jsonl`（用 session id 找，不推算目录名），读最后一条主循环 assistant 记录的 `message.model`，也就是主 session 当下的 model；
  - 读不到的那一项记为 `not determined`，之后不传；
  - 两个值写进 state file。
  Phase 0 的 Inputs 列出 `$CLAUDE_EFFORT`、`$CLAUDE_CODE_SESSION_ID` 和 `printenv CLAUDE_CODE_EFFORT_LEVEL`。
- § The settings line 的模板末尾加上 `, roles <S2 <model>/<effort>; …|none declared>, pass-through <model|not determined>/<effort|not determined>`。roles 列表里，角色没声明的那一项写 `—`（C5）。SKILL.md 里所有说 settings line 以 `wait <interactive|headless>` 结尾的句子都要跟着改，包括 Phase 0 的 DONE 句（C9）。
- § The state file 的模板加一行沿用值。
- § The gates 表里 settings stop 那一行，以及 § The stop conditions，都要反映这两个新的 settings stop：`Role settings` 文法，和 `CLAUDE_CODE_EFFORT_LEVEL`。

**Acceptance criteria:**
- 字段表有 `Role settings:` 一行，文法和默认值如上，并写明部分声明的处理。`grep -n "Role settings" plugins/kenspc/skills/autopilot/SKILL.md` 命中字段表、start checks、gates 表和 stop conditions。
- `grep -n "CLAUDE_CODE_EFFORT_LEVEL" plugins/kenspc/skills/autopilot/SKILL.md` 命中 start checks 和 stop conditions，start checks 那一项写明 `printenv CLAUDE_CODE_EFFORT_LEVEL`。
- Phase 0 写明 `$CLAUDE_EFFORT`、`$CLAUDE_CODE_SESSION_ID`、`~/.claude/projects/*/<session-id>.jsonl` 和 `not determined`；state file 模板有沿用值那一行。
- settings line 模板以 `pass-through <model|not determined>/<effort|not determined>` 结尾，前面是 `roles <S2 <model>/<effort>; …|none declared>`，并写明 roles 列表里角色没声明的那一项写 `—`。
- `grep -n "wait <interactive|headless>" plugins/kenspc/skills/autopilot/SKILL.md` 的每一处都没有说 settings line 以它结尾。
- 新增的每条规则都有 Why。
- 共同约束的编号标签 grep 对 `SKILL.md` 没有输出。
- `bash scripts/check-all.sh` exit 0，其中 `check-no-model-names.sh` 和 `check-instruction-files.sh` 通过。
- 本任务的 commit 只改动 `SKILL.md`。

---

### Task 4: SKILL.md — 每次启动设两个变量、读出实际值、判定一致、写进记录和报告

**Status:** DONE

**Implementation notes:**
- Decisions: 读出实际值的规则写在 The return 那一条 bullet 里、原有文字之后的续段，一条子列表列出判定规则，state file 那一行的模板逐字放在续段里，也放进 § The state file 模板新增的 `models and efforts:` 一节，以及 reviewer report 模板 `- Models and efforts:` 下面。transcript 里有主循环记录、只是缺 `effort` 字段的情况，spec 同时有两条可套用的说法（缺 `effort` 字段算 `effort not applied` 的不一致；读不到字段算 `not observed`）。这里取较具体的那条：缺字段就是 `effort not applied`，applied 那一栏对这条记录写 `—`；`not observed` 只用在 transcript 找不到、没有读得到的主循环 assistant 记录，或 `message.model` 读不到的时候。这样 `MISMATCH: effort not applied` 和"`not observed` 不加 `MISMATCH:`"不会互相冲突。`<what>` 定为 `model`、`effort`、`effort not applied` 三者之一或几项，用 `, ` 连接。reviewer report 模板那一行写成 `<n> workers, <k> mismatches|mismatches: none`，沿用 settings line 里 `acceptance <k> cases|none` 的写法，Phase 4 的叙述另外写明没有不一致时的完整写法。
- Changes/tradeoffs: worker 不沿用主 session 的 model 和 effort 这句写在 The launch 的续段开头，后面接着写每次启动都要设这两个变量、重跑 tag 对应的角色和 resume 的规则，各附 Why。S4 task block 里的那句用 plain text（跟 block 里其他提到变量的文字一样没有反引号），因为它是 worker 读的 prompt；Templates 的 S4 bullet 同步写明，并附 Why。§ The driver 的变量表插在 `APPEND_SP` 之后，顺序与 `run.sh` 档头一致（用脚本逐项比对过）。"follows the session's model" 的空结果对照用 spec（命中 4 行），因为 task 开始前的 SKILL.md 本来就没有这句。另外留意到：spec 要求读全部主循环 assistant 记录，Claude Code 可能在 transcript 里写入 model 不是真实 model ID 的合成记录（例如 API 错误时），这种记录会让 model 那一栏出现 `+` 连接的多个值并被判为不一致；本任务照 spec 写，没有另外排除，记在这里供 reviewer 判断。

Depends on: Task 1, Task 3

修改 `plugins/kenspc/skills/autopilot/SKILL.md`，只改这一个档（spec Step 3 的后半；L1、L3、L5、L6、L7、L10、L11、L12；C5、C6、C10）。

- § Launch, wait, return 的 The launch：
  - 每次启动都明确设定 `AUTOPILOT_MODEL` 和 `AUTOPILOT_EFFORT`：用该角色声明的值；没有声明的项用 Phase 0 的沿用值；沿用值是 `not determined` 就设成空字串。Why：没有 flag 的 worker 会按自己的 settings 解析；明确设成空字串，也挡住主 session 环境里已有的同名变量。
  - 重跑的 tag 用它那一步的角色：`-s3<字母>`（`-s3c`、`-s3d` …）是 S3b，`-s4<字母>`（`-s4b`、`-s4c` …）是 S4，`-s5<字母>`（`-s5b` …）是 S5。
  - resume（`<tag>-r<k>`）沿用该 tag 原本的值。Why：resume 会保留 model 但不保留 effort，不带 flag 的 resume 会回到 settings 的 effort。
- The return：每个 `<tag>.exit` 出现之后，用 `<tag>.session` 里的 session id 找 `~/.claude/projects/*/<session-id>.jsonl`。只读主循环的 assistant 记录，也就是这个档本身，不读 subagent 的档案；读出 `message.model` 和 `effort`，然后判定：
  - model 一致：先去掉请求值末尾的 `[...]`，实际的 model ID 不分大小写包含它，就算一致；
  - effort 一致：实际的 `effort` 字段等于请求值；记录里没有 `effort` 字段也算不一致，写作 `effort not applied`；
  - 请求值是 `—`（没有传）的那一项不判定；
  - 读档里全部主循环 assistant 记录：只有一个不同值就照原样印出，有几个不同值就用 `+` 连起来；每一条都相符才算一致；resume 的 tag 那一行涵盖整个 session，包括之前的那一轮（C6）；
  - transcript 找不到、或读不到某个字段，就记为 `not observed`，绝不因此停止；`not observed` 照原样印出，不加 `MISMATCH:`，也不算进不一致的数目（C10）；
  - 不一致只记录并标出，不停止。

  结果写进 state file，一行一个 worker：
  `<tag> requested <model|—>/<effort|—> (<declared|pass-through>) applied <model|not observed>/<effort|not observed>[ MISMATCH: <what>]`

  只声明了一部分的角色标作 `declared`，它 requested 里没声明的那一项是传出去的沿用值（C5）。§ The state file 的模板加上这一节。Why 里要写明：transcript 的字段是没有文件记载的内部格式，只能当证据、不能当契约，所以读不到时不停止。
- § The reviewer report 的模板在 `- Total cost:` 之前加 `- Models and efforts: <n> workers, <k> mismatches`，下面附上 state file 里那几行；没有不一致时写 `mismatches: none`。Phase 4 讲 reviewer report 的叙述也要同步。
- S4 的 task block（plugin mode）注明：嵌套 session 经由环境变量沿用 S4 的 `AUTOPILOT_MODEL` 和 `AUTOPILOT_EFFORT`；Templates 里 S4 那条 bullet 的说明同步。
- § The driver：变量表加上这两个变量；"Every worker starts with …" 那一句补上：变量非空时，新启动和 resume 都带 `--model`、`--effort`。
- 更正说法：SKILL.md 写明 worker 不会沿用主 session 的 model 和 effort。没有 flag 时它按自己的 settings 解析，所以每次启动都要传。

**Acceptance criteria:**
- `grep -n "AUTOPILOT_MODEL\|AUTOPILOT_EFFORT" plugins/kenspc/skills/autopilot/SKILL.md` 命中 The launch、The driver 和 S4 task block。
- The launch 写明：resume（`<tag>-r<k>`）沿用该 tag 原本的 `AUTOPILOT_MODEL` 和 `AUTOPILOT_EFFORT`；重跑的 tag 按它那一步的角色取值，`-s3<字母>` 是 S3b、`-s4<字母>` 是 S4、`-s5<字母>` 是 S5。
- SKILL.md 有一句写明 worker 不沿用主 session 的 model 和 effort，没有 flag 时按自己的 settings 解析。
- state file 那一行的模板逐字出现：`<tag> requested <model|—>/<effort|—> (<declared|pass-through>) applied <model|not observed>/<effort|not observed>[ MISMATCH: <what>]`。
- 判定规则写明：去掉末尾的 `[...]`、不分大小写的包含、`effort not applied`、多个值用 `+` 连接且每一条都要相符、`not observed` 不加 `MISMATCH:` 也不计数。
- reviewer report 模板里 `- Models and efforts:` 的行号小于 `- Total cost:` 的行号，并写明 `mismatches: none` 的情况；Phase 4 讲 reviewer report 的那一段也提到 `Models and efforts`。
- 新增的每条规则都有 Why。
- § The driver 列出的环境变量与 Task 1 之后的 `run.sh` 档头一致。
- `grep -n "follows the session's model" plugins/kenspc/skills/autopilot/SKILL.md` 没有结果。整个 `plugins/kenspc` 的检查在 Task 5：`run.ps1` 那一句由 Task 2 更正，本任务不依赖 Task 2。
- 共同约束的编号标签 grep 对 `SKILL.md` 没有输出；`bash scripts/check-all.sh` exit 0。
- 本任务的 commit 只改动 `SKILL.md`。

---

### Task 5: README、CLAUDE.md 和 release checklist

**Status:** TODO

Depends on: Task 1-4

修改 `plugins/kenspc/README.md`、`CLAUDE.md` 和 `docs/release-checklist.md`（spec Step 4；L4、L7、L8、L12；C8、C9）。

`plugins/kenspc/README.md` § Autopilot：
- 字段列表加上 `Role settings:`，写明文法、默认值（empty）和部分声明的处理；"The sixteen labels" 改成十七个。
- 沿用规则：没有声明的角色，或角色没声明的那一项，用主 session 当下的 model 和 effort（effort 来自 `$CLAUDE_EFFORT`，model 来自主 session 自己的 transcript）；读不到的那一项不传，记为 `not determined`。另外写明两个 settings stop：`Role settings` 文法不符；`CLAUDE_CODE_EFFORT_LEVEL` 已设、而有角色声明了 effort。
- 记录格式：settings line 的新尾段、state file 每个 worker 一行的格式、reviewer report 的 `Models and efforts` 那一行；"The reports" 一段列出的字段也加上它。
- The drivers 一段：`AUTOPILOT_MODEL`、`AUTOPILOT_EFFORT` 非空时传 `--model`、`--effort`，新启动和 resume 都传；S4 的嵌套 session 经由环境变量沿用 S4 的值。
- 写明 worker 不会沿用主 session 的 model 和 effort，没有 flag 时按自己的 settings 解析。
- `run.ps1` 维持 "checked on macOS only" 的说明。

`plugins/kenspc/README.md` § Known behavior 加四项：
- 角色的 model 会连带影响该 worker 里所有的 subagent（`model: inherit` 解析成 worker 自己的 model）；
- frontmatter 设了 `xhigh` 的 agent 不受角色 effort 的影响；
- Fable 的计费风险：在 `-p` 模式下，Fable 的请求如果计入 usage credits，Claude Code 不会询问，直接扣款。Max 方案超过每周 50% 的 Fable 份额时会发生；在 Fable 需要 usage credits 的方案上，每次都会发生。主 session 跑 Fable 时，所有没有声明的角色也会跟着跑 Fable；
- transcript 的字段是没有文件记载的格式，读不到时记为 `not observed`，不会停止。

另外，现有那一项说 headless autopilot 的 "settings line ends with `wait headless`"，要改成跟新的尾段相符（C9）。

`CLAUDE.md`：
- § Sessions, not agents (autopilot) 加上准确的说法：每个 worker 是独立 process，会自己解析 model 和 effort，所以 skill 通过 run.sh 的 `AUTOPILOT_MODEL`、`AUTOPILOT_EFFORT` 传角色的值（声明值或沿用值），新启动和 resume 都传。
- 讲 `check-no-model-names.sh` 的那句 "Skills and agents follow the session's model and effort" 保持不变，`scripts/check-no-model-names.sh` 也不改（C8）。
- guard 和 self-test 的计数有变动就更新；预期不变，仍是 `guards run: 11`、`self-tests run: 10`。

`docs/release-checklist.md`：
- smoke 第 11 行 "a line opening `Autopilot settings —` and ending `wait headless`" 改成跟新的 settings line 相符：仍然检查 `wait headless`，但不再说它在行尾（C9）。不新增 smoke 检查，根目录 `README.md` 不改（C9）。
- 计数有变动的话一并更新。

**Acceptance criteria:**
- `grep -rn "follows the session's model" plugins/kenspc CLAUDE.md README.md` 没有结果。
- README 的字段列表有 `Role settings:`，写出的标签数与 SKILL.md 字段表的行数一致（十七个）。
- README § Autopilot 出现 `AUTOPILOT_MODEL`、`AUTOPILOT_EFFORT`、`not determined`、`CLAUDE_CODE_EFFORT_LEVEL` 和 `Models and efforts`，并逐字写出与 SKILL.md 相同的 state file 那一行模板；CLAUDE.md § Sessions, not agents (autopilot) 出现 `AUTOPILOT_MODEL` 和 `AUTOPILOT_EFFORT`。
- README § Known behavior 有上面四项新条目，每项都写明所列内容。本任务在这三个档新增的文字里，只有 Fable 计费那一项写出 model 名称，其他例子都用 `<model>` 占位符：`git diff -U0 <task 开始前的 HEAD> -- plugins/kenspc/README.md CLAUDE.md docs/release-checklist.md | grep -iE '^\+.*\b(opus|sonnet|haiku|fable)\b'` 印出的每一行都属于 Fable 计费那一项。README 原有的 model 名称（例如 Acknowledgements 里的）不在此列。
- README 和 release checklist 里，不再有说 settings line 以 `wait headless` 结尾的句子。
- `git diff -U0 <task 开始前的 HEAD> -- CLAUDE.md | grep -E '^-.*(Skills and agents follow the|session.s model and effort; a model name)'` 没有输出，也就是 "Skills and agents follow the session's model and effort" 那一句（CLAUDE.md 里分在两行）没有被改动；对照：去掉 `^-.*` 的同一个 pattern，`git show <task 开始前的 HEAD>:CLAUDE.md | grep -E '(Skills and agents follow the|session.s model and effort; a model name)'`，命中两行。`git diff --quiet <task 开始前的 HEAD> -- scripts/check-no-model-names.sh` exit 0。
- release checklist 的 pre-flight block 全部 exit 0，输出 `guards run: 11`，最后一行是 `self-tests run: 10`。如果计数变了，CLAUDE.md 和 checklist 写的是新的计数，而且与输出一致。
- 共同约束的编号标签 grep 对这三个档没有输出。
- 本任务的 commit 只改动这三个档。

---

### Task 6: CHANGELOG 的 4.2.0 条目

**Status:** TODO

Depends on: Task 1-5

修改 `plugins/kenspc/CHANGELOG.md`（spec Step 5）。

- 在 `## 4.1.0 — 2026-09-28` 之上加 `## 4.2.0 — unreleased`，写 Batch I 的内容：
  - 改了什么：`Role settings:` 字段、沿用规则、run.sh 和 run.ps1 的两个变量、实际值的记录和一致性判定、两个 settings stop，以及 README Known behavior 新增的四项；
  - 对"worker 跟随主 session 的 model"这个旧说法的更正：worker 自己按 settings 解析 model 和 effort，resume 保留 model 但不保留 effort。证据用自己的话写。
- 条目不引用旧句子的原文 "follows the session's model"，否则 Task 5 的 grep 会命中这个条目。
- 4.1.0 以前的条目不改写；日期留到发布准备时才填。

**Acceptance criteria:**
- `grep -n "^## 4.2.0 — unreleased" plugins/kenspc/CHANGELOG.md` 命中一行，行号小于 `## 4.1.0` 那一行。
- `git diff --numstat <task 开始前的 HEAD> -- plugins/kenspc/CHANGELOG.md` 印出一行，第二栏（删除的行数）是 `0`、第一栏大于 0，也就是只有新增的行。跟 task 开始前的 HEAD 比，而不是跟 index 比：暂存或提交之后，`git diff` 不带 commit 就没有输出，检查也就不可能失败。
- `grep -rn "follows the session's model" plugins/kenspc CLAUDE.md README.md` 仍然没有结果。
- 共同约束的编号标签 grep 对 `CHANGELOG.md` 没有输出。
- 本任务的 commit 只改动 `CHANGELOG.md`。
