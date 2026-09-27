# Batch G：`init-project` skill（`/kenspc-init`）

## 2. 规格：`init-project` skill

### 2.1 目标
一个新项目（可以是完全空、连 git 都没有的目录）或一个已有的 repo，执行一次这个 skill 之后，就具备 kenspc 流程要用的档案，以及一套按项目资讯写成的文件。这套文件由三部分组成：
- `AGENTS.md` 当索引；
- `CLAUDE.md` 只 import 它，再加上 Claude Code 专用的规则；
- 几份长期主题文件。

资讯靠多轮访谈收集。用户可以一题都不答，档案照样全部建好，缺的地方标 TBD。设计对象是小团队、中型项目。

### 2.2 入口
- Skill 名称 `init-project`，指令 `/kenspc-init`。写法和目录结构照 repo 现有的 skill 与 command。
- 可以带一段自由文字当参数（项目描述）。能从中取得的资讯就不再问。
- `description` 要有英文和中文的触发语。不能被关于 Claude Code 内建 `/init` 的问题，或者"init 是什么意思"这类问题触发。
- 不设 reviewer agent。Effort 跟随 session，不加 `effort:` frontmatter。

### 2.3 起点判断
先扫描，判断属于以下哪一种起点：

| 起点 | 怎样判断 | 可以询问时 | 无法询问时 |
|---|---|---|---|
| 空目录，没有 git | 没有任何档案，也没有 `.git` | 问要不要 `git init`（默认要，branch 用 `main`） | 直接 `git init`，branch 用 `main` |
| 有档案，但不是 git repo | 有档案，`git rev-parse` 失败 | 先列出看到的档案，确认这是项目目录才继续 | 停下，不写任何东西，说明原因 |
| 在别的 repo 的子目录里 | `git rev-parse --show-toplevel` 指向上层目录 | 问用户：这是上层 repo 里的新 app，还是应该独立的项目？新 app 就只建这个子目录的 AGENTS.md/CLAUDE.md 一对；独立项目则建议先搬出去 | 停下，不写任何东西，说明原因 |
| 已有 repo | 有 `.git` | 只补缺少的档案 | 同左，另见 2.12 |

Why 第三种要特别处理：在别人的 repo 里再 `git init`，会产生嵌套的 repo，之后很难收拾。

### 2.4 访谈
- 访谈用用户的语言。产出的档案一律用英文，除非用户要求别的语言。Why：这些档案是写给 agent 和日后的团队成员读的。插件"task 文件不设默认语言"的规则不受影响；这里的英文默认值要在 skill 里写明理由。
- 问之前先扫描：现有档案、stack 设定档、git remote、`gh` 和它的登入状态、`dotnet`/`node` 等工具。能推导出来的不问。但 repo 形状（单一 app 还是 monorepo）和托管位置，扫描后仍然要问一次确认。
- 访谈分五轮，每轮都可以跳过。用户随时说"全部用默认"，访谈就结束。
  1. 项目：名称、一句话简介、用户、范围和 non-goals
  2. 形状和 stack：单一 app 还是 monorepo、有哪些 app、各自用什么 stack
  3. UI：有没有 UI、哪些平台、用什么元件库或设计系统
  4. 交付：版本方案和版本号位置、环境、部署方式、migration 政策
  5. 协作：branch 和 commit 惯例
- 每个问用户的地方，都要按 `CLAUDE.md` 的规定写明无法询问时怎么做。

### 2.5 阶段顺序
| 阶段 | 内容 |
|---|---|
| 0 | 扫描，判断起点 |
| 1 | 需要时做 `git init` |
| 2 | 访谈第 1–2 轮 |
| 3 | Stack scaffolding（可选，见 2.6） |
| 4 | 重新扫描；访谈第 3–5 轮。Commands 从 scaffold 出来的档案读取，不用问 |
| 5 | GitHub（见 2.7）。这一步决定 backlog 用哪种做法 |
| 6 | 写档、做机械检查（见 2.14）、列出档案清单请用户确认、commit |
| 7 | 可选：push、建 labels，两件事各自再确认一次 |

Why 这样排：
- Scaffolding 放在写文件之前，commands 才能从真的档案读出来。
- GitHub 放在写文件之前，因为 backlog 的约定取决于它。
- Push 放在最后，第一次推出去的就是完整的 repo。

### 2.6 Stack scaffolding
- 只提议，不默认执行。逐个 app 问要不要做、用哪个官方 generator。无法询问时不做。
- Skill 里不写死 generator 的命令、参数或版本，执行前先看该 CLI 的 `--help` 或官方文件。Why：这些都会变，跟插件不写 model 名称是同一个道理。
- 需要的工具（例如 .NET SDK、Node）不存在，就停下来说明缺什么，不自动安装。
- Monorepo 用 `apps/<name>/`。每个 app 内部按该 stack 自己的惯例排，例如 .NET 放在 `apps/api/src/`。单一 app 时，按该 stack 在 repo root 的惯例。
- Generator 自带的东西要检查：
  - 同一次执行中由 generator 产生的 README，问用户一次后可以换成 init 的版本。无法询问时直接换，因为那是这次执行自己的产物，不会丢掉用户的东西。
  - 子目录里多出来的 `.git`：先问用户。要处理的话，就移到项目 root 的 `.trash/`，并确保 `.trash/` 在 `.gitignore` 里，不删除。无法询问时不动它，在最后讯息说明。
  - `.gitignore` 只追加缺少的行，不覆盖。
- 每个 app 一个 commit：`chore: scaffold <app>`，排在文件的 commit 之前。

### 2.7 GitHub 与 backlog
**建 GitHub repo：**
- 只在没有 remote 时才问要不要建。默认 private。Owner 每次都要问，因为可能是个人帐号，也可能是 organization。
- 建 repo 和设定 remote 是同一步；push 是另一步，放到最后另外确认。
- 需要 `gh` 已安装并已登入。不然就说明手动建 repo 的步骤，backlog 用 C。
- 无法询问时，不建 repo、不 push。

**Backlog 用哪种做法：**
- 有 GitHub remote（原本就有，或刚建的）→ A：GitHub Issues。
- 其他情况（没有 remote，或是非 GitHub 的 remote，例如 Azure DevOps）→ C：一项一档。已有非 GitHub remote 时，也不提议另建 GitHub repo。

**A 的约定：**
- Label 用 GitHub 默认就有的 `bug`、`enhancement`，再新建 `debt` 和 `found-by-agent`。
- 建 label 之前，先查 repo 现有的 labels，因为 organization 可能自订了默认 labels。
- 只在可以询问、而且用户同意时才建。无法询问时，只把要建的 label 列在最后讯息里。

**C 的约定：**
- 档名：`docs/backlog/YYYY-MM-DD-<slug>.md`。
- Frontmatter：`type`（`bug`、`enhancement` 或 `debt`）、`found-by`（`human` 或 `agent`）、`created`、`source`。
- 正文：是什么、为什么重要、在哪里、备注。
- 没有 status 栏。解决或放弃时，在那个 commit 里删掉这个档；放弃的要在 commit message 写原因。
- 这个目录在还没有任何项目时，也要能被 git 追踪。
- 格式只写在一个地方，而且从 AGENTS.md 找得到它。
- 不兼容 Backlog.md 工具的格式。

**A 和 C 共同的写入规则**（写进 AGENTS.md）：在互动 session 里，经用户同意才建新的 backlog 项目；无人值守的执行只把发现的事项列在报告里。

### 2.8 产出的档案
| 档案 | 内容 | 什么时候建 |
|---|---|---|
| `AGENTS.md` | 见 2.9 | 一律建 |
| `CLAUDE.md` | 见 2.9 | 一律建（已存在时见 2.12） |
| `README.md` | 给人看的：是什么、怎样开始 | 不存在时才建；已存在就不动（generator 产生的例外，见 2.6） |
| `docs/product.md` | 目的、用户、范围、non-goals、术语 | 一律建 |
| `docs/architecture/overview.md` | 技术栈、组件与边界、资料、外部整合、关键决策 | 一律建。用资料夹，是为了以后拆成 `<topic>.md` 时不必改名 |
| `docs/ui/design-system.md` | 见 2.10 | 一律建；没有 UI 就注明 |
| `docs/release.md` | 见 2.10 | 一律建 |
| `docs/deployment.md` | 见 2.10 | 一律建 |
| `CHANGELOG.md` | Keep a Changelog 格式 | 只在选了版本方案时建（不是"无"，也不是 TBD） |
| `docs/backlog/` | 2.7 的 C | 用 C 时建 |
| `apps/<name>/AGENTS.md` + `CLAUDE.md` | 该 app 的 commands 和专属规则 | monorepo 的每个 app |
| `.gitignore` | 追加 `.kenspc/` 和 `CLAUDE.local.md` | 一律处理，只追加缺少的行 |

以下不建：
- `docs/briefs/`、`docs/plans/`、`docs/tasks/`：skill 需要时会自己建。
- Guide：留给 generate-guide。AGENTS.md 写明它的位置，用 generate-guide 的默认位置。
- `.claude/` 底下的任何档案：那是 protected path，无人值守时写入会失败。
- CONTRIBUTING 或 roadmap 档。

档名要避开 `remind-plan-skill.sh` 的匹配模式，免得写档时触发"请用 generate-guide"的提醒。

### 2.9 AGENTS.md 与 CLAUDE.md
**CLAUDE.md：**
- 第一行是 `@AGENTS.md`。
- 下面一节 `## Claude Code`，至少要有一行说明：kenspc 的约定（文件位置、Durable documents 表、commit 规则、版本号位置）都在 AGENTS.md。只有 Claude Code 才用的其他规则也放在这一节。Why：插件的 skill 和 agent 都说"project's CLAUDE.md"，这一行让直接去读 CLAUDE.md 的模型知道该去哪里找。

**AGENTS.md 的结构：**
- 固定这几节：
  - Project：简介，细节指向 `docs/product.md`
  - Commands
  - Rules：硬规则，最多 12 条
  - Documents
  - Workflow：git 惯例、backlog，以及一行 `Version lives in <file> — rules in docs/release.md`
- 开头是一段 HTML 注释，内容包括：模板版本标记 `kenspc-init template: 1`、行数预算、准入规则。
- 准入规则的内容：一行内容要同时满足三个条件才能进 AGENTS.md。
  1. 每个 session 都需要；
  2. 不能从 code 推导出来；
  3. 少了它 agent 会做错，或者它是安全底线。
  
  不满足的，放主题文件、子目录的 AGENTS.md，或（Claude 专用的）path-scoped rule。

**Documents 节：**
- 一张表，栏位是 `Document | Holds | Changes when`，格式跟插件 repo 自己 `CLAUDE.md` 里的 Durable documents 表一样，列出所有建好的长期文件。
- AGENTS.md 自己那一行的 "Changes when" 要写得很窄：只有 commands 变、硬规则增删、文件增删时才改。
- 表下面一行说明：`docs/briefs/`、`docs/plans/`、`docs/tasks/`（以及 C 的 `docs/backlog/`）不是长期文件；前三个完成后即删除。

**行数预算：**
- init 完成时，root 的 AGENTS.md 加 CLAUDE.md 合计不超过 80 行。
- 每个 app 的一对合计不超过 40 行。
- 长期上限是 200 行。
- 目录结构、依赖清单这类能从 code 推导出来的内容，不写进 AGENTS.md。

### 2.10 主题文件的内容
**`docs/ui/design-system.md`**
- 章节参照 DESIGN.md 格式：视觉风格、色彩角色、字体、元件、版面、层次、Do/Don't、响应式。
- 写明 token 的真相在 code 里，并写出 token 档的路径（还不知道就写 TBD）。文件里不重复写 hex 值。

**`docs/release.md`**
- 内容：版本方案（SemVer、CalVer 或无）、版本号放在哪个档、什么时候 bump、CHANGELOG 惯例、tag 格式、谁负责发布。
- 选"无"也要明写，例如 "No versioning — deployed from main, identified by commit SHA"。
- 有 mobile app 时要注明：app store 要求 version 和 build number，这部分不能选"无"。

**`docs/deployment.md`**
- 环境表：名称、用途、URL、托管、资料库、谁能部署。
- 部署方式：pipeline、触发条件、审批。
- 设定和 secret 的**位置**，例如 Key Vault 名称、secret 名称，绝对不写值。
- migration 政策、rollback、监控入口。

**AGENTS.md 的 Rules 一律包含两条安全规则**（措辞可按项目调整）：
1. 不对 staging 或 production 部署、跑 migration 或读资料。
2. Secret 不进 repo。

### 2.11 默认值与 TBD
- 安全规则直接写入。政策类的项目（版本方案、部署方式、环境等）如果用户没答，就写 TBD，不替用户决定。
- TBD 统一写成 `TBD(init): <what is missing>`。TBD 主要放在主题文件里。AGENTS.md 里不知道的项目就少写，或者只写一行 TBD，不放占位段落。
- 无法询问时的默认值：

| 项目 | 默认 |
|---|---|
| `git init` | 做（branch 用 `main`） |
| Scaffolding | 不做 |
| GitHub repo、push、labels | 都不做 |
| Backlog | 有 GitHub remote 用 A，否则用 C |
| 政策类 | 写 TBD |
| 安全规则 | 写入 |
| Commit | 做 |

### 2.12 已有 repo 与重跑
- 不覆盖任何既有档案。
- 已有 `CLAUDE.md` 时：先问用户。同意后，只在最上面加一行 `@AGENTS.md`，原有内容一字不改；然后报告两份合计的行数，以及看得出的重复内容。无法询问时不动它，并在最后讯息说明：AGENTS.md 因此还没有被 Claude Code 载入。
- 重跑时：只处理 `TBD(init):` 标记，填了答案的才改，其他内容一字不改。没有任何 TBD 时，不改任何东西，并说明这一点。
- 迁移旧格式的 repo（例如把一份很长的 CLAUDE.md 拆开），以及模板改版后的升级，v1 都不做（见 2.15）。

### 2.13 Commit
- 写完先列出所有档案，用户确认后才 commit。无法询问时直接 commit。
- Scaffold 的 commit：每个 app 一个 `chore: scaffold <app>`。文件的 commit：`docs: initialize project documentation`。
- 已有 repo 如果有成文的 commit 惯例，或者历史 commit 有一致的写法，就照它。

### 2.14 Skill 自己的机械检查（commit 前做）
- 符合 2.9 的行数预算；
- CLAUDE.md 第一行是 `@AGENTS.md`；
- AGENTS.md 有模板版本标记和准入规则的注释；
- Documents 表里的每个路径都存在；
- 没有看起来像 secret 的值（key、token、connection string）；
- 所有 TBD 都是 `TBD(init): …` 的格式；
- `.gitignore` 里有 `.kenspc/` 和 `CLAUDE.local.md`。

任何一项不通过，就先修正再检查，不 commit 一个不通过的结果。

### 2.15 v1 不做
**之后做，列进 roadmap：**
- 升级，包括两种：(1) 把旧格式的 repo 迁移过来；(2) 模板改版后，补上新版才有的内容。v1 写入的模板版本标记，就是为 (2) 准备的。
- Backlog 从 C 搬到 A。

**不做：**
- 安装 SDK 或其他工具
- 写 `.claude/` 底下的档案
- CONTRIBUTING 或 roadmap 档
- 行数提醒 hook
- reviewer agent
- `debt` 和 `found-by-agent` 以外的 label

### 2.16 插件层面的 DONE
- 新 skill 和 command 放在 repo 惯例的位置，结构照现有的 skill。需要的模板档放在 skill 目录里。
- Skill 的文字符合 `CLAUDE.md` 的 Writing Rules for Skill Content：
  - 规则用 Why 说理由；
  - 用 DONE criteria，不用编号的步骤流程；
  - 不用 MUST、NEVER、CRITICAL，也不用 anti-rationalization 表；
  - 每个问用户的地方，都以规定的 cannot-ask 句开头；
  - stack-agnostic：只从设定档侦测 stack，.NET 的 `src/` 只当作"按该 stack 惯例"的例子；
  - 证据用自己的话讲。
- `recon.md` 列出的每个连带改动都已完成，至少包括：
  - plugin README：Skills、Commands、一节说明、Known behavior；
  - 根 README：skills 表、Commands 那一行；
  - `CLAUDE.md`：layout tree、skill 计数句、cannot-ask 措辞那一条的列表加上本 skill 的问题；
  - CHANGELOG 的 `— unreleased` 条目。
- Pre-flight block 全部 exit 0，guard 和 self-test 的计数跟 checklist 一致。
- 验收记录已经 commit，发布准备按 1.7 完成，plan 档已经 `git rm`。

### 2.17 验收 cases
**A1　空目录、没有 git、无法询问**（H；H 不可用时用 S）
- 设定：参数给一句项目描述。
- PASS：
  - `.git` 存在，branch 是 `main`；
  - 2.8 里该建的档案都在，2.14 各项都通过；
  - 政策类项目都是 `TBD(init): …`，两条安全规则都在；
  - backlog 用 C；
  - 没有 scaffolding，没有任何 GitHub 动作；
  - 只有一个 `docs: initialize project documentation` commit，工作树干净。

**A2　空目录、互动、monorepo**（S）
- 脚本回答：
  - 第 1 轮：给项目名称和一句话简介。
  - 第 2 轮：monorepo，有两个 app：`api`（ASP.NET Core）和 `web`（React + TypeScript）。
  - Scaffolding：两个都要。
  - 第 3 轮：有 UI，平台是 web。
  - 第 4 轮：SemVer，版本号放在各 app 的项目档；环境是 dev、staging、production；部署方式 TBD。
  - 第 5 轮：跳过。
  - 没有 remote，不建 GitHub repo。
  - 确认档案清单。
- PASS：
  - 访谈分轮进行，每轮都可以跳过；
  - 布局是 `apps/api/`（.NET 在 `apps/api/src/`）和 `apps/web/`；
  - 每个 app 有一对 AGENTS.md/CLAUDE.md，每对不超过 40 行；
  - 缺少的工具会停下说明，不会安装；
  - 有工具的 app 用官方 generator，skill 文字里没有写死版本或参数；
  - 每个 scaffold 过的 app 有一个 `chore: scaffold <app>` commit，排在文件 commit 之前；
  - 有 `CHANGELOG.md`；backlog 用 C。

**A3　有档案、不是 git repo**
- 设定：目录里放三个无关的档案。
- 互动（S）PASS：先列出档案并询问；回答"这是项目目录"后才继续。
- 无法询问（H）PASS：停下；目录内容（档名和 sha256）不变。

**A4　在别的 repo 的子目录里**
- 设定：先建一个有一个 commit 的上层 repo。
- 互动（S）PASS：问是新 app 还是独立项目；回答"新 app"后，只在该子目录建一对 AGENTS.md/CLAUDE.md，不做 `git init`。
- 无法询问（H）PASS：停下；上层 repo 的 `git status --porcelain` 和 HEAD 都不变。

**A5　已有 repo，有一份 60 行的 CLAUDE.md 和一份 README**
- 互动（S），同意加 import，PASS：
  - CLAUDE.md 第一行变成 `@AGENTS.md`，其余内容和原档 byte-identical；
  - README 的 sha256 不变；
  - 报告了合计行数和重复内容。
- 无法询问（H）PASS：CLAUDE.md 的 sha256 不变；最后讯息说明 AGENTS.md 还没被载入。

**A6　重跑**（S）
- 在 A1 的结果上重跑，用户回答其中两个 TBD。PASS：只有那两处改变，`git diff` 只碰到 TBD 的行。
- 在没有任何 TBD 的 repo 上重跑。PASS：零改动，并说明原因。

**A7　有 GitHub remote、无法询问**（H）
- 设定：`git remote add origin https://github.com/example/seed.git`，不 push。
- PASS：
  - backlog 约定是 GitHub Issues；
  - 要建的 labels 只列在最后讯息；
  - 没有提议建 repo；
  - 没有任何网络写入。

**A8　非 GitHub remote、无法询问**（H）
- 设定：remote 是 `https://dev.azure.com/example/seed/_git/seed`。
- PASS：backlog 用 C；没有提议建 GitHub repo。

**A9　没有 remote、`gh` 不存在、互动**（S）
- 设定：用 PATH 遮蔽来模拟 `gh` 不存在；用户选择要建 GitHub repo。
- PASS：说明手动建 repo 的步骤；backlog 用 C。

**A10　Generator 冲突**（S，optional，需要 npm）
- 设定：scaffold web。
- PASS：
  - generator 的 README 经询问后被换掉；
  - `.gitignore` 是合并，不是覆盖；
  - 如果 generator 自己做了 `git init`，子目录的 `.git` 会被询问，然后移到 `.trash/`，而且 `.trash/` 在 `.gitignore` 里。

**A11　相容性**（H，optional）
- 设定：在 A1 的 seed 里加一句需求，然后 headless 跑 `/kenspc-plan`（无法询问时会停在 draft）。
- PASS：draft 的 Documentation impact 列出的档案，来自 AGENTS.md 的 Documents 表。

**A12　静态检查**（直接读档）
- PASS：
  - skill 文字里没有 MUST、NEVER、CRITICAL；
  - 每个问用户的地方都有规定开头的 cannot-ask 句；
  - description 有中英文触发语；
  - pre-flight block 全部 exit 0。

## Clarifications

- **C1（pre-flight）版本号。** 问题：1.7 说从现值升一个 minor（3.9.0 → 3.10.0），用户在任务末尾补充"版本可以直接上 4.0.0。先 commit，不要 push 和 tag"。裁决：release commit 用 4.0.0；只 commit，不 push、不 tag。理由：用户的补充比 1.7 的通用规则更具体，以补充为准。
- **C2（pre-flight）Headless 模式的环境变量。** 问题：container 以 root（uid 0）执行，`claude -p --permission-mode bypassPermissions` 直接报错 `--dangerously-skip-permissions cannot be used with root/sudo privileges`。裁决：H 模式的命令一律加 `IS_SANDBOX=1`；探测证实加上后能跑，并载入 `--plugin-dir` 的插件。理由：这是验收环境的限制，不是插件行为；不加就没有 H 模式可用。
- **C3（pre-flight）缺少的工具。** 问题：`gh` 和 `dotnet` 都不存在。裁决：A2 的 `api` app 用来验收"缺工具就停下说明、不安装"；A7 与 A9 照原 case 执行（A9 仍然做 PATH 遮蔽）。理由：缺工具正好是 spec 要测的路径，不需要改 case。
- **C4（recon 之后）Guide 的位置。** 问题：2.8 要 AGENTS.md 写出 generate-guide 的默认位置，但 generate-guide 没有默认路径（它的顺序是：CLAUDE.md 里写明的惯例 → 已有的 guide 档 → 问用户）。选项：(a) AGENTS.md 写 `docs/guides/`；(b) 给 generate-guide 加默认值；(c) AGENTS.md 写"`/kenspc-guide` 会问位置"。裁决：(a)。AGENTS.md 写一行 guide 放在 `docs/guides/`、由 `/kenspc-guide` 产生；guide 还不存在，所以这一行不进 Documents 表（2.14 要求表里每个路径都存在）。理由：CLAUDE.md import AGENTS.md，写在 AGENTS.md 的位置就是 generate-guide 第一优先读的"CLAUDE.md 惯例"；`docs/guides/` 是插件自己的 reminder hook 认定为 guide 的第一个模式，最接近插件的默认；(b) 会改变既有 skill 的行为，不在本 spec 范围。
- **C5（recon 之后）4.0.0 与 "v3" 字样。** 问题：plugin 升到 4.0.0，但每个 skill 的 `version: 3.0.0` 代表 v3 架构世代，CLAUDE.md 说"只在 v4 重写时才改"。裁决：新 skill 也用 `version: 3.0.0`；架构没变，所以各 skill 的 version 不动。描述架构世代的 "v3" 字样保留；release 步骤在 CLAUDE.md 的 per-skill version 段落补一句"plugin 4.0.0 是维护者的版本选择，不是架构改写"，CHANGELOG 的 4.0.0 条目不写"so a minor release"，改写版本号来自维护者的决定。理由：减法原则，只修正会让人误读的地方。
- **C6（recon 之后）第 1 节不在 repo 里。** 问题：spec 档只有第 2 节，2.16 与 C1 提到的 1.7 只在 main 手上。裁决：流程部分（1.4–1.7）由 main 写进各 subagent 的 prompt；规格仍以本档为准。理由：第 1 节是 main 的流程，不是 skill 的规格。
- **C7（recon 之后）模板档的命名与用字。** 问题：skill 目录里的模板若叫 `CLAUDE.md`，会被在本 repo 工作的 session 当成嵌套的 memory 档载入；`check-no-model-names.sh` 会拦下 `Claude-specific`、`Claude-only` 这类 `claude-` 开头的词和 model 家族名。裁决：模板档不用 `CLAUDE.md` 或 `AGENTS.md` 这种会被工具当成 memory/指示档的档名（例如加 `.tmpl` 后缀）；文字写 "specific to Claude Code"，不写 "Claude-specific"。理由：避免模板在维护者的 session 里生效，也避免 guard 失败。
- **C8（recon 之后）A12 的 MUST/NEVER/CRITICAL 怎么判。** 问题：现有 skill 用小写的 never/must 当普通英文。裁决：A12 与 reviewer 只查大写的 `MUST`、`NEVER`、`CRITICAL`（整字、区分大小写）；小写是普通用语，可以用，但两条安全规则的模板措辞尽量不用。理由：CLAUDE.md 的规则针对的是大写的强调标记，不是英文单字。
- **C9（recon 之后）H 模式怎样成为"无法询问"的 session。** 问题：`claude -p` 本身不一定带"work without stopping"的 system reminder。裁决：无法询问的 H case 照 batch C–E 的先例，加 `--append-system-prompt "Work without stopping; do not ask clarifying questions."`。理由：这是 repo 验收记录里已用过的做法，让 skill 的 cannot-ask 分支有明确的触发条件。
