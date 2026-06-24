import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static final UserSession _instance = UserSession._();
  UserSession._();
  static UserSession get instance => _instance;

  Future<bool> get isAdmin async {
    return (await SharedPreferences.getInstance()).getBool('is_admin') ?? false;
  }

  Future<bool> get isTeacher async {
    final type =
        (await SharedPreferences.getInstance()).getString('account_type');
    return type == 'teacher';
  }

  Future<bool> get hideScreenExplanation async {
    return (await SharedPreferences.getInstance())
            .getBool('hide_screen_explanation') ??
        false;
  }

  void invalidate() {}
}