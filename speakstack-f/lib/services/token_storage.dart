import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _keyToken = 'token';
  static const _keyUserId = 'user_id';
  static const _isAdmin = 'is_admin';
  static const _accountType = 'account_type';
  static const _hideScreenExplanation = 'hide_screen_explanation';
  static const _teacherApproved = 'teacher_approved';

  static Future<void> saveIsAdmin(bool isAdmin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAdmin, isAdmin);
  }

  static Future<bool?> getIsAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAdmin);
  }

  static Future<void> saveAccountType(String accountType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountType, accountType);
  }

  static Future<String?> getAccountType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accountType);
  }

  static Future<bool> getIsTeacher() async {
    final type = await getAccountType();
    return type == 'teacher';
  }

  static Future<void> saveTeacherApproved(bool approved) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_teacherApproved, approved);
  }

  /// `true` when approved; `null` when not a teacher or unknown (legacy session).
  static Future<bool?> getTeacherApproved() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_teacherApproved)) return null;
    return prefs.getBool(_teacherApproved);
  }

  static Future<bool> getIsApprovedTeacher() async {
    if (!await getIsTeacher()) return false;
    return await getTeacherApproved() == true;
  }

  static Future<void> saveHideScreenExplanation(bool hide) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hideScreenExplanation, hide);
  }

  static Future<bool?> getHideScreenExplanation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hideScreenExplanation);
  }


  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }


  static Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
  }

  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyUserId);
  }


  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUserId);
    await prefs.remove(_isAdmin);
    await prefs.remove(_accountType);
    await prefs.remove(_hideScreenExplanation);
    await prefs.remove(_teacherApproved);
  }
}
