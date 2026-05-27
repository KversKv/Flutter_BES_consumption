import 'package:shared_preferences/shared_preferences.dart';

class AdminSessionStore {
  AdminSessionStore._();

  static final AdminSessionStore instance = AdminSessionStore._();
  static const _unlockedKey = 'admin_session_unlocked_v1';

  Future<bool> isUnlocked() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_unlockedKey) ?? false;
  }

  Future<void> unlock() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_unlockedKey, true);
  }

  Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_unlockedKey);
  }
}
