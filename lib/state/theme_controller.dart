import 'package:flutter/material.dart';

/// 主题切换控制器。
///
/// 状态：
/// - ThemeMode.system：跟随系统
/// - ThemeMode.dark  ：强制深色
/// - ThemeMode.light ：强制浅色
///
/// 不做本地持久化——每次启动默认回到 `ThemeMode.system`。
class ThemeController extends ChangeNotifier {
  ThemeMode _mode;

  ThemeController({ThemeMode initial = ThemeMode.system}) : _mode = initial;

  ThemeMode get mode => _mode;

  void setMode(ThemeMode mode) {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
  }

  /// 三态循环：system -> dark -> light -> system
  void cycle() {
    switch (_mode) {
      case ThemeMode.system:
        _mode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _mode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _mode = ThemeMode.system;
        break;
    }
    notifyListeners();
  }
}
