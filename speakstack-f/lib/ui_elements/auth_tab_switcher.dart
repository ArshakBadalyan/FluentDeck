import 'package:flutter/material.dart';
import 'package:speakstack/app_colors.dart';
import 'package:speakstack/localization/app_localizations.dart';
import '../screens/auth/auth_screen.dart';

class AuthTabSwitcher extends StatelessWidget {
  final AuthMode current;
  final ValueChanged<AuthMode> onChanged;

  const AuthTabSwitcher({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget tab(String text, AuthMode mode) {
      final selected = current == mode;

      return GestureDetector(
        onTap: () => onChanged(mode),
        child: Column(
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.black : Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            if (selected)
              Container(
                width: 100,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.primaryPurple,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        tab(
          AppLocalizations.instance.t('login-register.registration'),
          AuthMode.register,
        ),
        const SizedBox(width: 24),
        tab(
          AppLocalizations.instance.t('login-register.only-nickname'),
          AuthMode.nickname,
        ),
      ],
    );
  }
}
