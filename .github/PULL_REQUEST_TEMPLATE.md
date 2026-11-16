## 关联 Issue

<!-- 使用“Closes #编号”关联；无关联写“无”。 -->

Closes #

## 变更类型

- [ ] 修复 Bug（fix）
- [ ] 新功能（feat）
- [ ] 文档（docs）
- [ ] CI / 构建 / 脚本（ci）
- [ ] 测试（test）
- [ ] 重构或性能优化（不改变外部行为）
- [ ] 其它：

## 变更说明

<!-- 说明动机、实现思路与关键取舍；保持最小改动，避免无关重排。 -->

## 影响面

- [ ] 页面 / UI 交互
- [ ] 服务 / 业务逻辑
- [ ] 数据模型 / 持久化 / 状态机
- [ ] 权限或导航契约
- [ ] 小安 AI / 模型 / 原生运行库
- [ ] 构建、签名或发布流程
- [ ] 第三方组件 / 许可证
- [ ] 仅文档

跨模块影响、兼容性、迁移或回滚说明：

## 验证命令与结果

> 只勾选**实际执行并通过**的项；未执行请注明原因。命令与环境见 [CONTRIBUTING.md](https://github.com/CDUESTC-OpenAtom-Open-Source-Club/Campus-Safety-Connect/blob/main/CONTRIBUTING.md)。

| 验证项 | 命令 | 结果（实际输出摘要） |
| :--- | :--- | :--- |
| Node 脚本语法 | `node --check scripts/*.cjs` | |
| 小安服务回归 | `node scripts/test-assistant.cjs` | |
| Markdown 回归 | `node scripts/test-markdown.cjs` | |
| Debug 构建 | `hvigorw assembleHap --mode module -p product=default -p buildMode=debug` | |
| CodeLinter | `codelinter -c code-linter.json5 -p default .` | |
| 设备 / 模拟器验证 | 设备与页面路径： | |

Node 回归需先安装 TypeScript 5.9.3 并设置 `TYPESCRIPT_PATH`：

```bash
npm install --no-save --no-package-lock typescript@5.9.3
TYPESCRIPT_PATH="$PWD/node_modules/typescript" node scripts/test-assistant.cjs
TYPESCRIPT_PATH="$PWD/node_modules/typescript" node scripts/test-markdown.cjs
```

## 版本、模型与第三方组件

- [ ] 未改动 `versionName` / `versionCode`
- [ ] 改动了版本号：旧值 `____ / ____` → 新值 `____ / ____`，且 `versionCode` 高于 AGC 已发布版本
- [ ] 未改动模型或原生运行库
- [ ] 改动了模型 / `libMNN.so` / `libxiaoan.so`：已重新执行准备脚本并校验模型 SHA-256
- [ ] 未新增或更新第三方组件
- [ ] 新增 / 更新第三方组件：已补充 `third_party/xiaoan/` 下的许可文本与 NOTICE
- [ ] 涉及发布配置或签名材料（`signing/` 不得提交）

## 检查清单

- [ ] 改动范围最小，未包含无关重构、格式化或文件重排
- [ ] 未提交 `signing/`、模型/运行库二进制、构建产物、`local.properties` 或 `.regression/`
- [ ] 新增文件为 UTF-8，行尾与仓库现有文件一致
- [ ] `git diff --check` 无空白错误
- [ ] 新增文档链接指向的文件真实存在，且未被 `.gitignore` 排除
- [ ] 若改动页面，已附模拟器/真机截图或录屏说明
- [ ] Git 作者为 `Lycorius03`，未添加 AI co-author 或无关贡献者
- [ ] 已阅读 [CONTRIBUTING.md](https://github.com/CDUESTC-OpenAtom-Open-Source-Club/Campus-Safety-Connect/blob/main/CONTRIBUTING.md)；涉及发布时已按 [RELEASE_CHECKLIST.md](https://github.com/CDUESTC-OpenAtom-Open-Source-Club/Campus-Safety-Connect/blob/main/RELEASE_CHECKLIST.md) 核对

## 发布影响

<!-- 若改动将进入版本发布，说明是否影响 AGC 商店包、隐私政策或商店素材；无影响写“无”。 -->
