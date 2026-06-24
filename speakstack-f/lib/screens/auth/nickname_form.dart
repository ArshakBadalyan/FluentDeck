import 'package:flutter/material.dart';
import 'package:speakstack/localization/app_localizations.dart';
import 'package:speakstack/english_main_screen.dart';
import '../../routing/app_route_names.dart';
import '../../routing/app_page_routes.dart';
import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../ui_elements/auth_input_decoration.dart';
import '../../ui_elements/auth_secondary_link.dart';
import '../../ui_elements/primary_button.dart';
import 'auth_screen.dart';

class NicknameForm extends StatefulWidget {
  final void Function(AuthMode) onSwitch;

  const NicknameForm({super.key, required this.onSwitch});

  @override
  State<NicknameForm> createState() => _NicknameFormState();
}

class _NicknameFormState extends State<NicknameForm> {
  final _nicknameController = TextEditingController();
  bool _loading = false;
  bool _submitLocked = false;

  bool get _isValid => _nicknameController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nicknameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitLocked || _loading) return;
    _submitLocked = true;
    setState(() => _loading = true);

    try {
      final res = await AuthService.registerByNickname({
        'username': _nicknameController.text.trim(),
      });

      if (!mounted) return;

      if (res['status'] == 'success') {
        AudioService().play('formSubmit');
        Navigator.pushReplacement(
          context,
          appMaterialPageRoute(
            name: AppRouteNames.main,
            builder: (_) => const EnglishMainScreen(initialMainIndex: 0),
          ),
        );
        return;
      }

      setState(() {
        _loading = false;
        _submitLocked = false;
      });

      final apiMessage = res['error'] is Map
          ? res['error']['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            (apiMessage != null && apiMessage.isNotEmpty)
                ? apiMessage
                : context.tr('login-register.sign-up'),
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _submitLocked = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('login-register.sign-up'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _nicknameController,
          decoration: authInput(context.tr('login-register.only-nickname')),
        ),
        const SizedBox(height: 48),
        PrimaryButton(
          text:
              _loading
                  ? '${context.tr('over.loading')}...'
                  : context.tr('login-register.sign-up'),
          enabled: _isValid && !_loading,
          onPressed: _submit,
        ),
        const Spacer(),
        AuthInlineSwitchLink(
          leadingText: context.tr('login-register.already-have-account'),
          linkLabel: context.tr('login-register.sign-in'),
          enabled: !_loading,
          onLinkPressed: () => widget.onSwitch(AuthMode.login),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
