# 发布检查清单

适用于校安通（HarmonyOS）Release 出包与 AGC 更新/首发。本清单按 `scripts/package-harmony-release.py` 的**实际校验项与产物**反向整理：脚本自动校验项集中在 C 节，其余为人工门禁。

> 当前工程版本：`1.0.0 / 1000100`；AGC 已发布基线：`0.2.5 / 1000009`（见 [RELEASE_STATUS.md](RELEASE_STATUS.md)）。每次发布前以 `AppScope/app.json5` 与 AGC 实际值为准。
>
> 出包命令（在仓库根执行）：`python scripts/package-harmony-release.py`。脚本不接受命令行签名口令；默认输出到 `release/校安通-v{version}-{code}/`，可用 `--output-dir` 指定一个**新的空目录**。

## A. 前置门禁（脚本不检查，人工确认）

- [ ] 已从最新 `main` 创建 release 分支；发布 PR 正文引用本清单并附 `验证报告.json` 与 `SHA256校验值.txt`
- [ ] `AppScope/app.json5` 的 `versionName` / `versionCode` 已按本次发布更新，且 `versionCode` 大于 AGC 已发布版本（当前基线 `1000009`）
- [ ] [README.md](README.md)、[RELEASE_STATUS.md](RELEASE_STATUS.md) 的版本、发布状态与已知限制已同步
- [ ] `node --check scripts/*.cjs` 全部通过
- [ ] Node 回归 65 项通过：`node scripts/test-assistant.cjs` 与 `node scripts/test-markdown.cjs`（设置 `TYPESCRIPT_PATH`，见 [CONTRIBUTING.md](CONTRIBUTING.md) 第 1.3 节）
- [ ] CodeLinter 无 error：`codelinter -c code-linter.json5 -p default .`
- [ ] Debug 构建成功，并在模拟器或真机验证本次改动涉及的页面与流程
- [ ] 干净克隆已执行 `scripts/build-xiaoan-runtime.ps1` 与 `python scripts/prepare-xiaoan-model.py --bundle`
- [ ] 设备侧 Hypium 单测已按维护者本地 `TESTING.md` 执行并记录结论（该文件被 `.gitignore` 排除，公开仓库不提供）
- [ ] 工作区干净：`git status --short` 无签名材料、模型/运行库二进制、构建产物或本机配置

## B. 发布输入材料（脚本会检查）

- [ ] `signing/active-harmony-release.json` 存在；其中 `directory` 指向 `signing/` 内的发布目录（脚本会拒绝越界路径），`certificateSha256` 与 AGC 发布证书 SHA-256 一致
- [ ] 该目录下 `release-signing.json` 的 `material.storeFile`、`material.certpath`、`material.profile` 均指向真实存在的文件
- [ ] `storePassword` / `keyPassword` 仅保存在本机加密配置中；不进入命令行、README、Issue/PR 或日志（脚本会把日志中的口令替换为 `[REDACTED]`）
- [ ] `signing/` 未出现在 `git status`，也未被 `git add -f` 提交
- [ ] `build-profile.json5` 未提交任何签名配置；脚本会临时注入并在构建后恢复，`验证报告.json` 的 `buildProfileRestored` 应为 `true`
- [ ] `DEVECO_SDK_HOME` 或 `local.properties` 中的 `hwsdk.dir` 指向包含以下工具的 SDK / IDE：`tools/node/node.exe`、`jbr/bin/java.exe`、`tools/hvigor/bin/hvigorw.js`、`default/openharmony/toolchains/lib/hap-sign-tool.jar`
- [ ] 输出目录为新目录或空目录（脚本拒绝非空目录，避免覆盖历史发布包）

## C. 脚本自动校验项对照

下表与 `scripts/package-harmony-release.py` 当前实现逐项对应，便于确认没有遗漏：

| # | 脚本校验项 / 产物 | 对应人工确认 |
| :---: | :--- | :--- |
| 1 | 读取 `AppScope/app.json5` 的 `versionName` / `versionCode`，用于产物命名与包内比对 | A 第 2 项 |
| 2 | 检查 `node`、`java`、`hvigorw.js`、`hap-sign-tool.jar` 存在 | B 第 6 项 |
| 3 | 读取 `signing/active-harmony-release.json`，签名目录必须位于 `signing/` 内 | B 第 1 项 |
| 4 | 检查 `release-signing.json` 的 `storeFile` / `certpath` / `profile` 文件存在，并读取口令字段 | B 第 2、3 项 |
| 5 | 输出目录必须为空 | B 第 7 项 |
| 6 | 临时注入签名配置构建 Release，构建后恢复 `build-profile.json5`（`buildProfileRestored`） | B 第 5 项 |
| 7 | 构建日志必须包含 `BUILD SUCCESSFUL`，否则中止 | E 第 1 项 |
| 8 | 只接受本次构建生成的签名 APP / HAP；早于构建开始的产物会被拒绝 | E 第 2 项 |
| 9 | 用 `hap-sign-tool` 对 APP 与 HAP 执行 `verify-app`，必须输出 `verify-app success` | D 第 1 项 |
| 10 | 签名证书链的 SHA-256 必须与 `active.certificateSha256` 一致 | D 第 1 项 |
| 11 | 包内 Profile 的 SHA-256 必须与 `release-signing.json` 的 `profile` 一致 | D 第 1 项 |
| 12 | APP 的 `pack.info` 中 `bundleName` 与 `versionCode` 必须与工程一致 | D 第 3 项 |
| 13 | APP 内必须恰好嵌入一个 HAP | D 第 2 项 |
| 14 | HAP 的 `module.json` 必须为 `debug: false`、`buildMode: release`，`bundleName` / `versionCode` 与工程一致 | D 第 3、4 项 |
| 15 | HAP 内必须存在 `libs/arm64-v8a/libxiaoan.so` 与 `libs/arm64-v8a/libMNN.so` | D 第 5 项 |
| 16 | `resources/rawfile/xiaoan/*` 的文件大小与 SHA-256 必须匹配 `manifest.json`，且必须为 `ZIP_STORED`（可按 raw 文件描述符读取） | D 第 5 项 |
| 17 | 生成 `验证报告.json`（版本、证书、产物哈希、模型文件、`embeddedModelVerified`、`releaseDebugFlag: false`、`buildProfileRestored`） | E 第 4 项 |
| 18 | 生成 `SHA256校验值.txt`（大写 SHA-256 + 两个空格 + 文件名） | E 第 5 项 |
| 19 | 将签名 APP / HAP、`pack.info` 复制到输出目录 | E 第 3 项 |
| 20 | 构建日志写入 `.regression/build-agc-release.log`、验签日志写入 `.regression/verify-agc-*.log`，口令替换为 `[REDACTED]` | F 第 4 项 |

## D. 人工复核（脚本自动校验之后）

- [ ] 签名验证通过，且证书与 Profile 均来自当前 AGC 发布身份
- [ ] APP 内嵌 HAP 与独立 HAP 的版本、包名、模型校验一致
- [ ] 包名 `com.example.hongmengzhian`、API 20、设备类型与 AGC 已上架应用一致
- [ ] HAP 为 Release 构建（`debug: false`），不是未签名包或 Debug 包
- [ ] 包内含 `libxiaoan.so` 与 `libMNN.so`，且模型文件完整、可读取

## E. 出包与产物复核

- [ ] 已执行 `python scripts/package-harmony-release.py`（或 `--output-dir` 指定新目录）并看到 `Release APP/HAP signatures, certificate, Profile, version and bundled model verified.`
- [ ] 只使用本次构建产物，没有复用旧 APP/HAP 或手工改名覆盖
- [ ] 输出目录包含以下文件（`{version}` / `{code}` 取自 `AppScope/app.json5`）：

```text
校安通-v{version}-{code}-release-signed.app
校安通-v{version}-{code}-release-signed.hap
pack.info
验证报告.json
SHA256校验值.txt
```

- [ ] `验证报告.json` 中：`releaseDebugFlag` 为 `false`、`buildProfileRestored` 为 `true`、`embeddedModelVerified` 为 `true`，`model.files` 为 Qwen3-0.6B MNN 的三份文件及哈希
- [ ] `验证报告.json` 的 `artifacts` 字节数与 SHA-256 与输出目录中的 `.app` / `.hap` 一致
- [ ] 用独立命令（PowerShell `Get-FileHash -Algorithm SHA256` 或 `sha256sum`）重算 `.app` / `.hap`，结果与 `SHA256校验值.txt` 一致
- [ ] `git status --short` 确认 `build-profile.json5` 已恢复、无签名配置或发布产物被提交

## F. 第三方许可、模型与日志

- [ ] [third_party/xiaoan/NOTICE.md](third_party/xiaoan/NOTICE.md) 与同目录 `LICENSE-*.txt` 完整（Qwen、MNN、RapidJSON、half、FlatBuffers、TensorFlow、Skia），版本与本次包一致
- [ ] 模型固定版本 `34dfccda1187ded6e07ea06426da576b0b793c6b`、MNN 固定提交 `6b1db4c2eacf8193e6b7a1841acb6e31a1938e82` 与 NOTICE、准备脚本一致
- [ ] 本次若新增/更新第三方组件，已补充许可文本与 NOTICE，并在 PR 中说明
- [ ] 分享 `.regression/build-agc-release.log` 或 `.regression/verify-agc-*.log` 前已复查无口令、无本机敏感路径
- [ ] App 内随包附带许可文本；新增数据或权限已同步隐私政策

## G. 商店与 AGC

- [ ] 按 [dist/store-assets/上架填写清单.md](dist/store-assets/上架填写清单.md) 核对商店表单：签名包、图标、截图、隐私政策 URL、APP 备案号与测试账号（测试账号仅通过 AGC 字段私密提供，不写入仓库）
- [ ] 商店截图使用本轮 Release 实际界面，无调试红条、Toast、加载中状态；素材位于 `dist/store-screenshots/`
- [ ] 发布说明不宣传尚未上线的 AI 能力（已上架 `0.2.5` 不含 AI；`1.0.0` 按实际构建与审核结果描述）
- [ ] AGC 已填写测试账号可正常登录并访问主要功能
- [ ] `versionCode` 高于 AGC 已发布版本，避免覆盖安装失败

## H. 发布后

- [ ] 更新 [RELEASE_STATUS.md](RELEASE_STATUS.md)：版本、日期、AGC 审核/发布状态与验证结论
- [ ] 打 tag；如创建 GitHub Release，附件与 AGC 包一致，并附 `SHA256校验值.txt`
- [ ] 归档本轮 `验证报告.json`、`.regression` 日志与截图路径，便于回溯
- [ ] 发布后抽检：安装新版、核心事件/任务流程、账号切换、服务卡片；若启用 AI，验证模型入口与本地推理

## I. 执行记录

每次发布复制一行填写，便于追溯「谁在何时核对了哪些项」：

| 日期 | 执行人 | 分支 / commit | versionName / versionCode | 验证报告路径 | AGC 状态 |
| :--- | :--- | :--- | :--- | :--- | :--- |
| | | | | | |

## 未覆盖项

- 脚本不执行 CodeLinter、Node 回归、Hypium 或商店素材核对，这些是 A 节的人工门禁。
- 脚本不自动上传 AGC、不提交审核，也不代表审核通过或已发布。
- 签名私钥、口令、AGC 测试账号不得进入仓库、PR 或公开日志。
