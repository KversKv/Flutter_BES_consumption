# Coding Conventions

## 命名
- 文件：`snake_case.dart`
- 类 / enum：`UpperCamelCase`
- 变量 / 方法：`lowerCamelCase`；私有前缀 `_`
- 常量：`lowerCamelCase`，优先 `const` / `static const`

## 字符串与注释
- 字符串：优先单引号 `'...'`
- 注释：就近原则，与所在文件语言保持一致（当前以中文为主）
- **不新增无意义注释**；未经要求不改动既有注释

## i18n（硬规则）
- 任何用户可见文本必须走 `AppLocalizations.of(context).xxx`
- 新增文案必须同时在 `lib/l10n/app_localizations.dart` 补 `en` 与 `zh`
- 语言开关：`lib/main.dart` 中 `const bool useChinese`；修改此开关不得破坏任一语言完整性

## 状态管理
- 每业务域一个 `ChangeNotifier`；顶层 `MultiProvider` 注入
- 页面：只读用 `context.watch<T>()` / `Consumer<T>`；事件用 `context.read<T>()`
- 禁止在 `build()` 内直接调用触发 `notifyListeners()` 的方法

## 架构约束
- `models` 不 import `package:flutter/*`（`material.dart` 除外禁用）
- `services` 为纯函数/无状态类，不持有 UI/Context
- `state` 不直接持有 `BuildContext`
- `widgets` 不含业务副作用，数据全部通过参数传入

## Lint
- 依据 `analysis_options.yaml`：已关闭 `prefer_const_constructors`、`prefer_final_fields`、`use_key_in_widget_constructors`、`avoid_print` 等；**不得反向开启**
- 提交前必须 `flutter analyze` 通过

## 文件大小
- 单 Dart 文件超过 ~400 行优先考虑拆分；但**拆分前须评估收益**，不为拆而拆

## 依赖新增
- 写入 `pubspec.yaml` + 在 `docs/ai/task-log.md` 记录引入理由

## 禁区
- 禁止将工程名拼回 `bes_comsuption`
- 禁止在 `pages` / `widgets` 里硬编码中英文 UI 字符串
- 禁止跨层反向依赖（见 tech-context.md）
