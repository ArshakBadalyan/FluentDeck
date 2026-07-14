import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app_colors.dart';
import '../../models/speaking_preferences.dart';
import '../../services/conversation_service.dart';
import '../../services/speaking_preferences_service.dart';
import '../../ui_elements/frosted_bottom_sheet.dart';
import '../../ui_elements/modern_page_widgets.dart';

/// Quick toggles for the active conversation (same prefs as Profile → Settings).
Future<void> showConversationChatSettingsSheet(BuildContext context) {
  return showFrostedBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _ConversationChatSettingsSheet(),
  );
}

class _ConversationChatSettingsSheet extends StatefulWidget {
  const _ConversationChatSettingsSheet();

  @override
  State<_ConversationChatSettingsSheet> createState() =>
      _ConversationChatSettingsSheetState();
}

class _ConversationChatSettingsSheetState
    extends State<_ConversationChatSettingsSheet> {
  SpeakingPreferences _prefs = const SpeakingPreferences();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SpeakingPreferencesService.instance.load(
      forceRefresh: true,
    );
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _loading = false;
    });
    // #region agent log
    unawaited(
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7337/ingest/ea2fc602-e0ad-43b0-b0a8-176383aba938',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'fcee54',
            },
            body: jsonEncode({
              'sessionId': 'fcee54',
              'runId': 'chat-settings',
              'hypothesisId': 'S1',
              'location': 'conversation_chat_settings_sheet.dart:_load',
              'message': 'Chat settings sheet opened',
              'data': {
                'soundOn': prefs.soundOn,
                'autoPlayVoice': prefs.autoPlayVoice,
                'autoStartRecording': prefs.autoStartRecording,
                'autoConversation': prefs.autoConversation,
                'typeMessagesEnabled': prefs.typeMessagesEnabled,
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .catchError((_) => http.Response('', 500)),
    );
    // #endregion
  }

  Future<void> _save(SpeakingPreferences next) async {
    setState(() {
      _prefs = next;
      _saving = true;
    });
    final result = await SpeakingPreferencesService.instance.saveWithDetails(
      next,
    );
    if (!mounted) return;
    setState(() => _saving = false);

    if (!result.ok) {
      final restored = await SpeakingPreferencesService.instance.load(
        forceRefresh: true,
      );
      if (!mounted) return;
      setState(() => _prefs = restored);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Could not update settings'),
        ),
      );
      return;
    }

    await ConversationService.instance.refreshSpeakingSettings();
    // #region agent log
    unawaited(
      http
          .post(
            Uri.parse(
              'http://127.0.0.1:7337/ingest/ea2fc602-e0ad-43b0-b0a8-176383aba938',
            ),
            headers: {
              'Content-Type': 'application/json',
              'X-Debug-Session-Id': 'fcee54',
            },
            body: jsonEncode({
              'sessionId': 'fcee54',
              'runId': 'chat-settings',
              'hypothesisId': 'S2',
              'location': 'conversation_chat_settings_sheet.dart:_save',
              'message': 'Chat settings saved',
              'data': {
                'soundOn': next.soundOn,
                'autoPlayVoice': next.autoPlayVoice,
                'autoStartRecording': next.autoStartRecording,
                'autoConversation': next.autoConversation,
                'typeMessagesEnabled': next.typeMessagesEnabled,
                'serviceSound': ConversationService.instance.soundOnEnabled,
                'serviceAutoStart':
                    ConversationService.instance.autoStartRecordingEnabled,
                'serviceType': ConversationService.instance.typeMessagesEnabled,
              },
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            }),
          )
          .catchError((_) => http.Response('', 500)),
    );
    // #endregion
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Chat settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Rubik',
                    ),
                  ),
                ),
                if (_saving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Applies to this conversation and saves to your account.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppToggleRow(
                        title: 'AI voice',
                        subtitle:
                            'Speak tutor replies out loud. Turn off to read only.',
                        value: _prefs.soundOn && _prefs.autoPlayVoice,
                        enabled: !_saving,
                        onChanged: (value) {
                          _save(
                            _prefs.copyWith(
                              soundOn: value,
                              autoPlayVoice: value,
                              autoConversation:
                                  value ? _prefs.autoConversation : false,
                            ),
                          );
                        },
                      ),
                      AppToggleRow(
                        title: 'Auto-start recording',
                        subtitle:
                            'Open the mic after the tutor finishes speaking.',
                        value: _prefs.autoStartRecording,
                        enabled: !_saving,
                        onChanged: (value) {
                          _save(
                            _prefs.copyWith(autoStartRecording: value),
                          );
                        },
                      ),
                      AppToggleRow(
                        title: 'Hands-free auto record',
                        subtitle:
                            'Keep voice on and reopen the mic after every reply.',
                        value: _prefs.autoConversation,
                        enabled: !_saving,
                        onChanged: (value) {
                          _save(
                            _prefs.copyWith(
                              autoConversation: value,
                              autoPlayVoice:
                                  value ? true : _prefs.autoPlayVoice,
                              soundOn: value ? true : _prefs.soundOn,
                            ),
                          );
                        },
                      ),
                      AppToggleRow(
                        title: 'Type messages',
                        subtitle:
                            'Show a text field to type instead of only using the mic.',
                        value: _prefs.typeMessagesEnabled,
                        enabled: !_saving,
                        onChanged: (value) {
                          _save(
                            _prefs.copyWith(typeMessagesEnabled: value),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Done',
                          style: TextStyle(
                            color: AppColors.primaryPurple,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
