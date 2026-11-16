# 参与贡献

感谢关注校安通（Campus Safety Connect）。本文档说明如何准备开发环境、提交 Issue / PR，以及提交前必须执行的验证。项目定位、构建命令与 CI 门禁见 [README.md](README.md)；发布流程见 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md)。

## 开始之前

- 先搜索现有 Issue，避免重复报告；Bug 与功能建议请使用 `.github/ISSUE_TEMPLATE/` 中的模板。
- **不要**在 Issue、PR 或截图中粘贴签名口令、API Key、真实账号口令、本机绝对路径和未脱敏日志。
- 本项目遵循 Apache License 2.0，见 [LICENSE](LICENSE)。
- 仓库维护者的部分规范文档（`CLAUDE.md`、`WORKFLOW.md`、`TESTING.md`、`docs/` 等）被 `.gitignore` 排除，干净克隆拿不到；外部贡献者以 README、本文档和仓库内可公开获取的文件为准。

## 1. 环境准备

| 依赖 | 要求 |
| :--- | :--- |
| DevEco Studio | 可编译 HarmonyOS 6 / API 20 工程的版本 |
| HarmonyOS SDK | 配置 `DEVECO_SDK_HOME`，或在 `local.properties` 中写 `hwsdk.dir` |
| Node.js | 22（与 CI 一致），用于 hvigor 构建与 Node 回归 |
| Python 3 | 模型准备与发布打包脚本 |
| PowerShell 7 | 执行 `scripts/build-xiaoan-runtime.ps1` |

### 1.1 local.properties

`local.properties` 是本机配置，已被 `.gitignore` 排除，**不得提交**。至少指向本机 SDK，Windows 下反斜杠需要转义：

```properties
# DevEco Studio 生成的 Windows 路径会转义反斜杠
hwsdk.dir=D\:\\DevEco Studio\\sdk
```

首次使用可在 DevEco Studio 中打开项目根目录并等待 Sync 完成。仓库不内置 `hvigorw` 包装脚本，构建命令需在 DevEco Studio 终端中执行（或直接调用其 `tools/hvigor/bin/hvigorw.js`），详见 [README 的「构建与运行」](README.md#构建与运行)。

### 1.2 干净克隆：准备原生运行库与模型

小安依赖的 `libMNN.so` 与模型二进制不入库，干净克隆必须先执行：

```powershell
$env:DEVECO_SDK_HOME = '你的 DevEco SDK 路径'
./scripts/build-xiaoan-runtime.ps1
python scripts/prepare-xiaoan-model.py --bundle
```

- `build-xiaoan-runtime.ps1` 按固定提交 `6b1db4c2eacf8193e6b7a1841acb6e31a1938e82` 构建 arm64-v8a 与 x86_64 的 `libMNN.so`，输出到 `entry/libs/<abi>/`；可通过 `-SdkRoot`、`-Architectures` 覆盖参数。
- `prepare-xiaoan-model.py` 下载并校验固定的 Qwen3-0.6B MNN 导出（约 454 MB）；`--bundle` 会把校验后的模型与 `manifest.json` 复制到 `entry/src/main/resources/rawfile/xiaoan/`。默认缓存目录为 `.regression/models/qwen3-06`。
- 以上目录均被 Git 忽略，**不得提交**。更多边界见 [AI_ASSISTANT.md](AI_ASSISTANT.md) 的「模型与构建」。

### 1.3 Node 回归环境

两个 Node 回归脚本直接执行生产代码，不依赖 DevEco Studio、`local.properties`、设备或网络，合计 65 项断言。

```bash
npm install --no-save --no-package-lock typescript@5.9.3
TYPESCRIPT_PATH="$PWD/node_modules/typescript" node scripts/test-assistant.cjs
TYPESCRIPT_PATH="$PWD/node_modules/typescript" node scripts/test-markdown.cjs
```

Windows PowerShell：

```powershell
npm install --no-save --no-package-lock typescript@5.9.3
$env:TYPESCRIPT_PATH = "$PWD\node_modules\typescript"
node scripts/test-assistant.cjs
node scripts/test-markdown.cjs
```

CI 的 `regression (Node, no device)` job 使用同一组命令，详见 [README 的「测试」](README.md#测试) 与 [「持续集成」](README.md#持续集成)。

## 2. 分支与提交信息

- `main` 是唯一稳定分支，禁止直接在 `main` 上开发或提交；所有改动通过 PR 合并。
- 从最新 `origin/main` 创建分支：

```bash
git fetch origin
git switch -c docs/issue-41-contributing-templates origin/main
```

- 分支命名与现有分支保持一致：`feature/<简短说明>`、`fix/<issue 号>-<简短说明>`、`docs/<简短说明>`、`ci/<简短说明>`。
- Commit message 使用 `<type>: <说明> (#<issue>)`，中文描述实际修改；仓库现有 type 包括 `feat:`、`fix:`、`docs:`、`ci:`、`test:`、`release:`、`chore:`。例如：

```text
fix(ai): 修正响应体超限保护并补回归 (#46)
docs: 补充贡献指南、协作模板与发布检查清单 (#41)
```

- 一个 PR 聚焦一个问题，避免顺手重构、无关格式化或文件重排；公共模型、数据库结构、状态机、权限入口、导航契约和发布签名的变更需在合并前人工评审。
- Git 的 Author 与 Committer 必须为 `Lycorius03 <Lycorius03@outlook.com>`；禁止添加 Claude、Codex、ChatGPT 等 AI co-author trailer，禁止伪造其他贡献者。提交前用 `git log -1 --format=fuller` 检查。

## 3. 提交前必须验证

### 3.1 所有改动

```bash
for f in scripts/*.cjs; do node --check "$f"; done
```

### 3.2 涉及脚本、服务层或 Markdown 渲染

按第 1.3 节设置 `TYPESCRIPT_PATH` 后运行两个回归脚本，确认 65 项全部通过：

```bash
TYPESCRIPT_PATH="$PWD/node_modules/typescript" node scripts/test-assistant.cjs
TYPESCRIPT_PATH="$PWD/node_modules/typescript" node scripts/test-markdown.cjs
```

### 3.3 涉及 ArkTS、页面或工程配置

至少完成 Debug 构建，或对改动文件执行 CodeLinter；涉及页面/交互的改动应在模拟器或真机实际启动验证相关流程：

```bash
hvigorw assembleHap --mode module -p product=default -p buildMode=debug
codelinter -c code-linter.json5 -p default .
```

人工回归范围与 Bug 复现要求见维护者本地的 `TESTING.md`（该文件被 `.gitignore` 排除，公开仓库不提供；可向维护者索取或参考历史资料）。设备侧 Hypium 单测目前需在 DevEco Studio 手工执行。

### 3.4 涉及 AI、模型或原生运行库

重新执行第 1.2 节的准备脚本，确认模型文件 SHA-256 与 `scripts/prepare-xiaoan-model.py` 固定值一致，并运行第 3.2 节回归。修改原生代码时还需确认 `libMNN.so` / `libxiaoan.so` 能随 Debug 构建打包。

### 3.5 涉及文档

确认新增的相对链接指向的文件真实存在于仓库，且未被 `.gitignore` 排除；不要链接本地文档或已删除的 `docs/` 路径。

PR 描述使用 `.github/PULL_REQUEST_TEMPLATE.md`，必须填写**实际执行过**的命令与结果摘要；未执行的验证不得勾选或声称通过。

## 4. 不得提交的内容

以下内容已被 `.gitignore` 排除，禁止用 `git add -f` 强行提交：

- `signing/`：签名私钥、证书、AGC Profile 及含口令/本机路径的签名配置。
- 模型与运行库二进制：`entry/src/main/resources/rawfile/xiaoan/`、`entry/libs/`、`.regression/` 中的下载与构建缓存。
- 构建产物与本地发布包：`**/build/`、`release/`、`dist/*.app`、`dist/*.hap`、`.hvigor/`、`.arkui-x/build/` 等。
- `local.properties`、`node_modules/`、`oh_modules/`、IDE 配置与系统杂物。
- 真实账号口令、API Key、AGC 测试账号明文、未脱敏日志或截图。

提交前建议检查：

```bash
git status --short
git diff --check
git diff --cached --stat
```

## 5. Issue 与 PR

- **Bug**：使用 `.github/ISSUE_TEMPLATE/bug_report.yml`，提供 DevEco Studio / SDK / API 版本、设备或模拟器、Debug/Release、复现步骤、期望与实际结果；日志务必脱敏。
- **功能建议**：使用 `.github/ISSUE_TEMPLATE/feature_request.yml`，说明使用场景、期望方案、备选方案与影响模块。
- **PR**：关联 Issue（在模板中写 `Closes #<编号>`），按模板填写变更类型、影响面、验证命令与结果；涉及 `versionCode`、模型、第三方组件或许可证时逐项注明。
- **发布**：按 [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) 执行，发布 PR 附 `验证报告.json` 与 `SHA256校验值.txt`。

## 6. 评审与合并

- 至少一名维护者评审后再合并；自己发起的 PR 不要自行合并（除非维护者明确要求）。
- 合并前应确认 CI 的 `lint (config + scripts)` 与 `regression (Node, no device)` 通过（分支保护配置见 [README 的「持续集成」](README.md#持续集成)）。
- ArkTS CodeLinter 与 HAP 构建属于自托管、手动触发的门禁；发布前仍需在真实环境中执行。
