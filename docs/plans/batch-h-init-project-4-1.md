# Batch H：kenspc-claude-plugin 4.1.0 — init-project 修正与 AGENTS.md 原生载入的相容

## 2. 规格

### 2.1 事实基础
这些事实由 1.3 逐条验证。验证结果不同时，以验证结果为准，并记入 Clarifications。

- Claude Code 2.1.277 起，内建插件 `agents-md@builtin` 会原生读取 AGENTS.md（包括 `.claude/AGENTS.md`）。设定项 `instructionFiles` 有四个值：
  - `claude-md`：只读 CLAUDE.md。
  - `claude-md-or-agents-md`（默认）：从根目录到工作目录，任何一层只要有 `CLAUDE.md`、`.claude/CLAUDE.md` 或 `CLAUDE.local.md`，就完全不读 AGENTS.md，而且没有任何提示。
  - `claude-md-and-agents-md`：两者都读；已被 CLAUDE.md import 或 symlink 的档案，不会重复载入。
  - `managed-only`：只保留组织的 managed 档案。
- 这个设定只从用户设定、`--settings` 或 managed settings 读取，项目的 `.claude/settings.json` 不算。
- 原生支援需要从 Anthropic 取得 feature flags，所以用第三方 provider 或关掉 telemetry 时不可用。
- 原生载入的 AGENTS.md 不会出现在 `/memory`，也不会触发 InstructionsLoaded hook；经 import 或 symlink 载入的则会。
- 原生载入的 AGENTS.md 算作 project 指令档：没有省略 project 指令的 subagent 看得到它；Explore、Plan，以及设了 `omitClaudeMd` 的 agent 看不到。
- 插件支援的最低版本仍是 v2.1.0，所以不能假设用户的 Claude Code 有原生支援。

### 2.2 两个名词（全插件统一使用）
- **项目指令档（the project's instruction files）**：项目的 CLAUDE.md 档案、它们用 `@` import 进来的档案，以及所有 AGENTS.md 档案（root、`.claude/AGENTS.md`、子目录里的），不论 Claude Code 这次有没有载入它们。
- 这个定义只在插件里写一个地方。其他地方要么引用它，要么用经 guard 保护的同一句话；选哪一种由 implementer 提议，main 裁决。Why：Read CLAUDE.md 这个档案时，只会看到 `@AGENTS.md` 一行；而只有 AGENTS.md 的 repo，在默认模式下根本没有 CLAUDE.md。

### 2.3 与 AGENTS.md 原生载入相容

**H1 改成带条件的措辞。** init-project 里凡是说"AGENTS.md 不会被载入"的地方（SKILL.md、plugin README、final message 的模板），都改成以下事实：
- 有 import 行时，CLAUDE.md 会被载入的地方，AGENTS.md 都会跟着载入；
- 旁边已有 CLAUDE.md、又没有 import 时，AGENTS.md 只在 `claude-md-and-agents-md` 模式下载入，而且需要 Claude Code 2.1.277 以上、该环境可以用原生支援。

**H2 行数报告。** 用户拒绝加 import 时，final message 要报告两个档案合计的行数，并说明：在两者都会载入的模式下，重复的内容照样占用 context。

**H3 保留 import 行和 kenspc 指路行，并在 SKILL.md 用 Why 写明理由：**
- init 写的 CLAUDE.md 本身，就会让默认模式停读 AGENTS.md；
- 团队成员私人的 `CLAUDE.local.md` 也会造成同样的结果；
- 模式无法在项目层级设定；
- 有些环境没有原生支援；
- 只有经 import 载入的 AGENTS.md，才看得到（`/memory`、InstructionsLoaded）。

**H4 全插件改用"项目指令档"。**
- recon 列出的 (a)、(b) 两类，全部改用 2.2 的名词；(d) 类维持原样。
- 找惯例（Documents table、commit 规范、版本位置）时，读的是所有项目指令档。
- code-fixer 判定 NOT APPLICABLE 之前，要在所有项目指令档里找被引用的规则，找不到才可以判。

**H5 "尚未记录的 structural facts" 建议写到哪里**（task-implement、task-review）：
- 项目指令档里有 Documents table 的：建议写进表里负责该主题的档案；
- 项目指令档本身带有准入规则注释的（例如 kenspc-init 写的 AGENTS.md）：只有在该事实通过准入规则时，才建议写进它；
- 其他项目：维持现状，建议写进 CLAUDE.md；
- 项目有 AGENTS.md 并被 CLAUDE.md import 的：新的惯例建议写进 AGENTS.md，不复制进 CLAUDE.md。

**H6 init-project 的扫描**
- 已有 `.claude/CLAUDE.md` 的：当作"已有 CLAUDE.md"，不另建 root 的 CLAUDE.md。要在它最上面加 import 时先问用户，因为写入会触发 protected path 的提示；无法询问时不动它，并在 final message 说明。
- 已有 `.claude/AGENTS.md` 的：当作"已有 AGENTS.md"，不另建 root 的 AGENTS.md。
- 只有 AGENTS.md、没有任何 CLAUDE.md 的 repo：照旧建一个带 import 的 CLAUDE.md，并在 final message 用一句话说明原因：建了 CLAUDE.md，默认模式就会停读 AGENTS.md，import 让它继续被载入。
- 判断 "AGENTS.md already loads" 时，仍然只看 import 和 symlink。Why：只有这两种方式跟模式和环境无关。

**H7 README 的 Known behavior**：如果 1.3 证实 Claude Code 内建的 `/init` 会把 AGENTS.md 的内容抄进 CLAUDE.md，就加一条：`/kenspc-init` 之后不要再跑内建的 `/init`；已经跑过的，把抄进来的内容删掉。没证实就不写。

### 2.4 init-project 的修正

**N1 对话语言。** 第一则讯息写明这次执行用的对话语言，以用户的讯息为准，用户没有讯息时看参数。之后每个问题（包括 AskUserQuestion 的问题、header、选项和描述）以及 final message，都用这个语言；只有写进档案的内容用英文。Why：之前在 Mac 上跑，读了英文模板和工具输出之后，中途两次漂成英文；在开头留一个明确的锚点，比只靠一条规则可靠。

**N2 长期文件不引用短命文件。**
- init 写的长期文件用自己的话写出决策，不引用 `docs/briefs/`、`docs/plans/`、`docs/tasks/` 底下的档案；真的需要出处，就写 `git show <hash>:<path>`。
- AGENTS.md 里关于短命文件的那一行，只陈述约定：它们不是长期文件、长期文件不引用它们、kenspc 流程在工作完成后会删除它们。不宣称 repo 里现在没有这类档案。
- 已有 repo 里如果已经追踪着这类档案，在 final message 里列出来。

**#1 来源检查。** commit 前，topic 文件里每一句既不是 TBD、也不是模板固定文字的内容，都要能指出来源：用户的回答、参数，或某个档案（写出路径）。指不出来源的，改成 `TBD(init):`，并在 final message 列出改了哪些句子。这一项属于 § Checks，不通过就不 commit。

**#2 commit 身份。** 一律用 repo 已设定的 git 身份，不加 `-c user.name` 或 `-c user.email`，也不去设定身份。git 没有身份时，在 commit 之前停下，说明原因，档案留在工作树；无法询问时也一样。

**N3 空目录的判断。** 一个目录里如果只有 file browser 的 metadata，或者只有"用自己的 `.gitignore` 完全忽略自己"的目录（例如 `.gitignore` 的内容是 `*`），就算空目录。不写死任何插件或工具的名字。

**#3 跳过档案清单。** 在可以询问的 session 里，用户跳过档案清单的确认，就等于不 commit：档案留在工作树，final message 说明。无法询问的 session 照旧 commit。

**N4 lockfile。** 如果某个 stack 的套件管理器会用 lockfile 记录解析后的版本，而 generator 没有安装依赖，就在 scaffold 之后执行一次安装（不启动 dev server），让 lockfile 进入 scaffold commit；依赖目录照旧加进 `.gitignore`。安装失败的话，保留 scaffold 的结果，并在 final message 说明。

**N5 未安装的套件。** 选定了但还没安装的库，不写成 app AGENTS.md 里 Stack 的现况，而是在 topic 文件里写"已选定，尚未安装"。

**N6 README 的文件清单。** README 模板列出的文件，要跟 Documents table 列出的一致。

**N7 `.gitignore` 的内容放进哪个 commit。**
- 因为 scaffolding 才加进 root `.gitignore` 的行，放进第一个需要它们的 scaffold commit；
- `.kenspc/` 和 `CLAUDE.local.md` 这两行，放进文件的 commit。

**#4 访谈的问法。** 请用户确认预填答案时，不在里面夹带开放问题；开放问题要单独问。用选项提问时，"跳过这一题"和"其余全部用默认"是两个不同的选项。

### 2.5 验收 cases
H 模式没有特别说明的，一律用 `--settings` 指定默认模式 `claude-md-or-agents-md`。

**B1（P）四种模式的载入行为**
- 做法：就是 1.3 的探针，结果表收进验收记录。
- PASS：第 2.3 节写进档案的每一句，都跟结果表一致。

**B2（H，跑三次）空目录、无法询问、参数只有一句话**
- PASS：三次的 `docs/product.md` 都没有参数以外的产品主张；final message 列出被改成 TBD 的句子（如果有的话）。

**B3（H）空目录里只有一个自我忽略的目录**
- 设定：`mkdir .tool && printf '*\n' > .tool/.gitignore`。
- PASS：判定为空目录，执行了 `git init`，没有停下来。

**B4（H）没有 git 身份**
- 设定：`GIT_CONFIG_GLOBAL` 指向一个空档案，并设 `GIT_CONFIG_NOSYSTEM=1`；repo 层级也没有身份。
- PASS：在 commit 之前停下，档案都留在工作树，final message 说明原因；所有命令里都没有 `-c user.`。

**B5（S）已有 repo，而且追踪着 `docs/briefs/`、`docs/plans/` 底下的档案**
- PASS：
  - 新写的长期文件没有引用这些路径；
  - AGENTS.md 里短命文件那一行，没有宣称这些档案已被删除；
  - final message 列出了这些档案。

**B6（S）已有 CLAUDE.md，用户拒绝加 import**
- PASS：final message 对载入的说明是带条件的（H1），并报告两个档案合计的行数（H2）。

**B7（S）只有 AGENTS.md（没有模板标记），没有任何 CLAUDE.md**
- PASS：
  - 建了 CLAUDE.md，第一行是 `@AGENTS.md`；
  - AGENTS.md 的 sha256 没有变；
  - final message 有 H6 规定的那句说明。

**B8（S）已有 `.claude/CLAUDE.md`**
- PASS：没有建 root 的 CLAUDE.md；有询问用户，或在 final message 里说明。

**B9（S）用中文进行的互动执行**
- PASS：
  - 第一则讯息写明对话语言；
  - 每个问题和 final message 都是中文；
  - 写进档案的内容是英文。

**B10（S）可以询问时，用户跳过档案清单**
- PASS：没有 commit，档案留在工作树，final message 说明。

**B11（S）scaffold 一个 npm 的 web app**
- 设定：第 3 轮回答"选定 shadcn/ui + Tailwind"。
- PASS：
  - scaffold commit 里有 lockfile，没有 `node_modules`；
  - `.gitignore` 各行所在的 commit 符合 N7；
  - README 的文件清单等于 Documents table；
  - app AGENTS.md 的 Stack 没有把 shadcn/ui 或 Tailwind 写成现况。

**B12（静态）**
- PASS：
  - recon 列出的 (a)、(b) 两类已经全部改用"项目指令档"；
  - code-fixer 的 NOT APPLICABLE 判定涵盖 AGENTS.md；
  - skill 文字里没有 MUST、NEVER、CRITICAL；
  - 每个问用户的地方都有 cannot-ask 句；
  - pre-flight block 全部 exit 0。

**B13（H，optional）与 generate-plan 的相容性**
- 做法：在两个 seed 上，headless 执行 `/kenspc-plan`（无法询问时，它会停在 draft）：
  - 一个只有 AGENTS.md、没有 CLAUDE.md 的 seed，用默认模式；
  - B2 的 seed。
- PASS：两个 draft 的 Documentation impact，都来自 AGENTS.md 的 Documents table。

### 2.6 不做（留在或加进 roadmap）
- batch G deferred 的四个边界情况：已有自己格式的 `docs/backlog/`、第一次 commit 失败后重跑、generator 改到原本就有未 commit 改动的档案、在别的用户拥有的目录里执行 `git init`。
- 两种升级：迁移旧格式的 repo；把已初始化的项目升级到新版模板。
- backlog 从档案搬到 GitHub Issues。
- 侦测用户的 `instructionFiles` 设定。Why：这个设定可能来自三个地方，还会互相覆盖；写成带条件的事实，比去猜可靠。
- `/import codex`。
- 下游 repo（例如 DungeonDescent）的任何修正。

## Clarifications
