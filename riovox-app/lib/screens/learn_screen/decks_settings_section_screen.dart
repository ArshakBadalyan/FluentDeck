import 'package:riovox/ui_elements/app_dialog.dart';
import 'package:riovox/ui_elements/app_toast.dart';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:riovox/app_colors.dart';
import 'package:riovox/screens/learn_screen/decks_help_screen.dart';
import 'package:riovox/screens/learn_screen/decks_settings_section.dart';
import 'package:riovox/screens/learn_screen/note_types_screen.dart';
import 'package:riovox/screens/learn_screen/shared_decks_screen.dart';
import 'package:riovox/screens/learn_screen/widgets/decks_settings_widgets.dart';
import 'package:riovox/services/deck_backup_service.dart';
import 'package:riovox/services/deck_notification_service.dart';
import 'package:riovox/services/flashcard_export_service.dart';
import 'package:riovox/services/flashcard_import_service.dart';
import 'package:riovox/services/flashcard_sync_service.dart';
import 'package:riovox/services/flashcard_sync_store.dart';
import 'package:riovox/services/review_settings_store.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

/// Detail screen for one Decks settings section.
class DecksSettingsSectionScreen extends StatefulWidget {
  const DecksSettingsSectionScreen({
    super.key,
    required this.section,
    required this.settings,
    required this.onSave,
    required this.lastBackupLabel,
    required this.syncLog,
    required this.syncing,
    required this.onSyncNow,
    required this.onBackupNow,
    required this.onReload,
  });

  final DecksSettingsSection section;
  final ReviewSettings settings;
  final Future<void> Function(ReviewSettings) onSave;
  final String lastBackupLabel;
  final FlashcardSyncLog syncLog;
  final bool syncing;
  final Future<void> Function() onSyncNow;
  final Future<void> Function() onBackupNow;
  final Future<void> Function() onReload;

  @override
  State<DecksSettingsSectionScreen> createState() => _DecksSettingsSectionScreenState();
}

class _DecksSettingsSectionScreenState extends State<DecksSettingsSectionScreen>
    with SingleTickerProviderStateMixin {
  late ReviewSettings _settings;
  String? _appVersion;
  late final AnimationController _syncIconController;

  // This screen is pushed on its own Navigator route with `widget.syncLog`
  // and `widget.syncing` as a one-time snapshot from the Decks settings list
  // screen underneath. That parent updates its own state when a sync
  // finishes, but — since this route is already pushed on top of it — that
  // never rebuilds this widget, so the snapshot above went stale: "Last
  // sync" only caught up once you left this screen and came back (which
  // re-pushes it with a fresh snapshot). Mirroring the sync service's own
  // state locally keeps "Sync now" tapped from here up to date immediately.
  late FlashcardSyncLog _syncLog;
  late bool _syncing;

  // Same one-time-snapshot problem as the sync log above: re-read the last
  // backup time from the backup service so "Back up now" (or an automatic
  // backup triggered from here) shows up without leaving the screen.
  late String _lastBackupLabel;
  bool _backingUp = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _syncLog = widget.syncLog;
    _syncing = widget.syncing;
    _lastBackupLabel = widget.lastBackupLabel;
    if (widget.section == DecksSettingsSection.backups) {
      _refreshLastBackup();
    }
    if (widget.section == DecksSettingsSection.about) {
      _loadVersion();
    }
    _syncIconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (_syncing) _syncIconController.repeat();
  }

  @override
  void dispose() {
    _syncIconController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DecksSettingsSectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
    }
    if (widget.syncing != oldWidget.syncing) {
      if (widget.syncing) {
        _syncIconController.repeat();
      } else {
        _syncIconController.stop();
      }
    }
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _appVersion = '${info.version}+${info.buildNumber}');
  }

  Future<void> _save(ReviewSettings settings) async {
    setState(() => _settings = settings);
    await widget.onSave(settings);
  }

  Future<void> _refreshLastBackup() async {
    final lastMs = await DeckBackupService.instance.getLastBackupMs();
    if (!mounted) return;
    setState(() {
      _lastBackupLabel = DeckBackupService.instance.formatLastBackup(lastMs);
    });
  }

  Future<void> _handleBackupNow() async {
    if (_backingUp) return;
    setState(() => _backingUp = true);
    try {
      await widget.onBackupNow();
    } finally {
      if (mounted) setState(() => _backingUp = false);
      await _refreshLastBackup();
    }
  }

  /// Saves an automatic-backup setting, then backs up right away if that
  /// makes one due (e.g. just turned on with no backup yet).
  Future<void> _saveAutoBackup(ReviewSettings settings) async {
    await _save(settings);
    if (await DeckBackupService.instance.runAutoBackupIfDue()) {
      await _refreshLastBackup();
    }
  }

  String _timeLabel(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Future<void> _setReminderEnabled(bool enabled) async {
    if (enabled &&
        !await DeckNotificationService.instance.requestPermission()) {
      if (!mounted) return;
      AppToast.showSnackBar(
        context,
        const SnackBar(
          content: Text(
            'Notifications are off for Riovox. Allow them in your device '
            'settings to get the daily reminder.',
          ),
        ),
      );
      return;
    }
    await _save(_settings.copyWith(reviewReminderEnabled: enabled));
  }

  Future<void> _sendTestReminder() async {
    final shown = await DeckNotificationService.instance.showTestReminder();
    if (!mounted) return;
    AppToast.showSnackBar(
      context,
      SnackBar(
        content: Text(
          shown
              ? 'Test reminder sent. Check your notifications.'
              : 'Notifications are off for Riovox. Allow them in your '
                  'device settings to get the daily reminder.',
        ),
      ),
    );
  }

  Widget _testReminderButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _sendTestReminder,
        icon: const Icon(Icons.notifications_active_outlined, size: 18),
        label: const Text('Send test reminder'),
        style: TextButton.styleFrom(foregroundColor: AppColors.brandPrimary),
      ),
    );
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _settings.reviewReminderHour,
        minute: _settings.reviewReminderMinute,
      ),
    );
    if (picked == null) return;
    await _save(
      _settings.copyWith(
        reviewReminderHour: picked.hour,
        reviewReminderMinute: picked.minute,
      ),
    );
  }

  Future<void> _pickGesture(
    String title,
    ReviewGestureAction current,
    void Function(ReviewGestureAction) onSelected,
  ) async {
    final picked = await showModalBottomSheet<ReviewGestureAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppPageColors.cardBgOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(ctx).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                  ...ReviewGestureAction.values.map(
                    (action) => ListTile(
                      title: Text(reviewGestureActionLabel(action)),
                      trailing: decksSettingsCheckIcon(ctx, current == action),
                      onTap: () => Navigator.pop(ctx, action),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
    );
    if (picked != null) onSelected(picked);
  }

  Future<void> _pickNewCardPosition() async {
    final picked = await showModalBottomSheet<NewCardPosition>(
      context: context,
      backgroundColor: AppPageColors.cardBgOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'New card position',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(ctx).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                ...NewCardPosition.values.map(
                  (pos) => ListTile(
                    title: Text(newCardPositionLabel(pos)),
                    trailing: decksSettingsCheckIcon(ctx, _settings.newCardPosition == pos),
                    onTap: () => Navigator.pop(ctx, pos),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
    );
    if (picked != null) {
      await _save(_settings.copyWith(newCardPosition: picked));
    }
  }

  Future<void> _restoreBackup() async {
    try {
      final result = await pickAndImportFlashcards(
        context,
        format: FlashcardImportFormat.json,
      );
      if (result != null && mounted) {
        await showImportResultSnackBar(context, result);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _exportJsonManual() async {
    try {
      await FlashcardExportService.instance.exportJsonFile();
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _resetSettings() async {
    final ok = await showAppDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Reset review settings?'),
            content: const Text('All Decks review preferences will return to defaults.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
            ],
          ),
    );
    if (ok != true) return;
    await ReviewSettingsStore.instance.resetToDefaults();
    await DeckNotificationService.instance.syncFromSettings();
    await widget.onReload();
  }

  Future<void> _exportSettings() async {
    final json = ReviewSettingsStore.instance.exportJson();
    await Share.share(json, subject: 'Decks review settings');
  }

  Future<void> _importSettings() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final bytes = result.files.first.bytes;
      if (bytes == null) throw Exception('Could not read file');
      final raw = utf8.decode(bytes);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('Invalid JSON');
      final map = Map<String, dynamic>.from(decoded);
      if (map.containsKey('cards') || map.containsKey('decks')) {
        if (!mounted) return;
        AppToast.showSnackBar(context, 
          const SnackBar(
            content: Text('That file is a flashcard backup. Use Restore from backup instead.'),
          ),
        );
        return;
      }
      await ReviewSettingsStore.instance.importFromJsonString(raw);
      await DeckNotificationService.instance.syncFromSettings();
      await widget.onReload();
      if (!mounted) return;
      AppToast.showSnackBar(context, 
        const SnackBar(content: Text('Review settings imported')),
      );
    } catch (e) {
      if (!mounted) return;
      AppToast.showSnackBar(context, SnackBar(content: Text(e.toString())));
    }
  }

  Widget _gestureTile(
    String label,
    ReviewGestureAction action,
    ValueChanged<ReviewGestureAction> onChanged,
  ) {
    return decksSettingsPickerTile(
      context: context,
      title: label,
      valueLabel: reviewGestureActionLabel(action),
      onTap: () => _pickGesture(label, action, onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPageColors.pageBgOf(context),
      appBar: AppBar(
        backgroundColor: AppPageColors.pageBgOf(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: Text(widget.section.title),
      ),
      body: AppPageBackground(
        // Material ancestor for the bare ListTiles in _sectionChildren() —
        // without it, the ColoredBox above sits between them and the
        // Scaffold's own Material, so their ink splashes can't paint.
        child: Material(
          type: MaterialType.transparency,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Text(
                widget.section.subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: AppPageColors.subtitleOf(context),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ..._sectionChildren(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _sectionChildren() {
    switch (widget.section) {
      case DecksSettingsSection.general:
        return _general();
      case DecksSettingsSection.newStudyScreen:
        return _newStudyScreen();
      case DecksSettingsSection.reviewing:
        return _reviewing();
      case DecksSettingsSection.sync:
        return _sync();
      case DecksSettingsSection.notifications:
        return _notifications();
      case DecksSettingsSection.appearance:
        return _appearance();
      case DecksSettingsSection.controls:
        return _controls();
      case DecksSettingsSection.accessibility:
        return _accessibility();
      case DecksSettingsSection.backups:
        return _backups();
      case DecksSettingsSection.advanced:
        return _advanced();
      case DecksSettingsSection.about:
        return _about();
    }
  }

  List<Widget> _general() {
    return [
      AppSettingsGroup(
        title: 'Library',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shared decks'),
              subtitle: const Text('Browse community decks or import a deck file'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final imported = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(builder: (_) => const SharedDecksScreen()),
                );
                if (imported == true && mounted) {
                  AppToast.showSnackBar(context,
                    const SnackBar(content: Text('Shared deck imported')),
                  );
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manage note types'),
              subtitle: const Text('Built-in and custom note templates'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const NoteTypesScreen()),
                );
              },
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _newStudyScreen() {
    return [
      AppSettingsGroup(
        title: 'New card order',
        subtitle: 'Where new cards appear relative to reviews.',
        child: decksSettingsPickerTile(
          context: context,
          title: 'New card position',
          subtitle: const Text('Order of new cards vs reviews in a session'),
          valueLabel: newCardPositionLabel(_settings.newCardPosition),
          onTap: _pickNewCardPosition,
        ),
      ),
      AppSettingsGroup(
        title: 'Session display',
        subtitle: 'What you see while studying.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSliderRow(
              title: 'Learn ahead limit',
              value: _settings.learnAheadMinutes.toDouble(),
              min: 0,
              max: 60,
              divisions: 12,
              label: '${_settings.learnAheadMinutes} min',
              onChanged: (v) => _save(_settings.copyWith(learnAheadMinutes: v.round())),
            ),
            AppToggleRow(
              title: 'Show remaining due counts',
              subtitle: 'Show “Card 3 of 12” in the review header',
              value: _settings.showDueCountInStudy,
              onChanged: (v) => _save(_settings.copyWith(showDueCountInStudy: v)),
            ),
          ],
        ),
      ),
      decksSettingsNote(
        context,
        'Learn ahead may show cards due slightly early when supported by the scheduler.',
      ),
    ];
  }

  List<Widget> _reviewing() {
    return [
      AppSettingsGroup(
        title: 'Answer behavior',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppToggleRow(
              title: 'Tap to reveal answer',
              value: _settings.tapToReveal,
              onChanged: (v) => _save(_settings.copyWith(tapToReveal: v)),
            ),
            AppToggleRow(
              title: 'Show interval previews',
              subtitle: 'Display “1m”, “4d”, etc. on rating buttons',
              value: _settings.showIntervalPreviews,
              onChanged: (v) => _save(_settings.copyWith(showIntervalPreviews: v)),
            ),
          ],
        ),
      ),
      AppSettingsGroup(
        title: 'Rating buttons',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppToggleRow(
              title: 'Show Hard button',
              subtitle: 'Adds a fourth rating between Again and Good',
              value: _settings.showHardButton,
              onChanged: (v) => _save(_settings.copyWith(showHardButton: v)),
            ),
            const SizedBox(height: 6),
            decksSettingsLabelField(context, 'Again button label', _settings.labelAgain, (v) {
              _save(_settings.copyWith(labelAgain: v));
            }),
            if (_settings.showHardButton)
              decksSettingsLabelField(context, 'Hard button label', _settings.labelHard, (v) {
                _save(_settings.copyWith(labelHard: v));
              }),
            decksSettingsLabelField(context, 'Good button label', _settings.labelGood, (v) {
              _save(_settings.copyWith(labelGood: v));
            }),
            decksSettingsLabelField(context, 'Easy button label', _settings.labelEasy, (v) {
              _save(_settings.copyWith(labelEasy: v));
            }),
          ],
        ),
      ),
      AppSettingsGroup(
        title: 'Leeches',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppToggleRow(
              title: 'Leech suspend message',
              subtitle: 'Tell me when a card is suspended as a leech',
              value: _settings.leechAutoSuspend,
              onChanged: (v) => _save(_settings.copyWith(leechAutoSuspend: v)),
            ),
            const SizedBox(height: 4),
            Text(
              'Leech badge after',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.brandPrimary,
                      thumbColor: AppColors.brandPrimary,
                      overlayColor: AppColors.brandPrimary.withValues(alpha: 0.15),
                    ),
                    child: Slider(
                      value: _settings.leechThreshold.toDouble(),
                      min: 4,
                      max: 20,
                      divisions: 16,
                      label: '${_settings.leechThreshold} lapses',
                      onChanged: (v) => _save(_settings.copyWith(leechThreshold: v.round())),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_settings.leechThreshold}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandPrimary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      decksSettingsNote(
        context,
        'Cards are suspended at each deck’s own leech threshold, set in the deck’s options. This slider only sets when the “Leech” badge shows in review.',
      ),
      AppSettingsGroup(
        title: 'Daily reminder',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kIsWeb)
              decksSettingsNote(context, 'Daily reminders are available on Android and iOS only.'),
            AppToggleRow(
              title: 'Daily review reminder',
              subtitle:
                  _settings.reviewReminderEnabled
                      ? 'At ${_timeLabel(_settings.reviewReminderHour, _settings.reviewReminderMinute)}'
                      : 'Off',
              value: _settings.reviewReminderEnabled,
              enabled: !kIsWeb,
              onChanged: kIsWeb ? null : _setReminderEnabled,
            ),
            if (_settings.reviewReminderEnabled && !kIsWeb) ...[
              const SizedBox(height: 8),
              decksSettingsPickerTile(
                context: context,
                title: 'Reminder time',
                valueLabel: _timeLabel(_settings.reviewReminderHour, _settings.reviewReminderMinute),
                onTap: _pickReminderTime,
              ),
              const SizedBox(height: 4),
              _testReminderButton(),
            ],
          ],
        ),
      ),
    ];
  }

  /// Runs the sync via the parent (which still owns the snackbar and keeps
  /// the Decks settings list screen's own state current for when this
  /// screen is popped), then re-reads the result from the sync service
  /// directly so this screen's own "Last sync" updates right away too.
  Future<void> _handleSyncNow() async {
    setState(() => _syncing = true);
    _syncIconController.repeat();
    try {
      await widget.onSyncNow();
    } finally {
      if (mounted) {
        setState(() {
          _syncing = FlashcardSyncService.instance.syncing;
          _syncLog = FlashcardSyncService.instance.log;
        });
        if (!_syncing) _syncIconController.stop();
      }
    }
  }

  List<Widget> _sync() {
    return [
      AppSettingsGroup(
        title: 'Sync status',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Last sync'),
              subtitle: Text(_syncLog.lastSuccessLabel),
            ),
            if (_syncLog.lastError != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Last sync error'),
                subtitle: Text(
                  _syncLog.lastError!,
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.red.shade300
                        : Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ),
            if (_syncLog.lastApplied > 0 || _syncLog.lastSkipped > 0)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Last upload'),
                subtitle: Text(
                  '${_syncLog.lastApplied} applied, ${_syncLog.lastSkipped} skipped (server wins on conflict)',
                ),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sync now'),
              subtitle: const Text('Upload pending reviews and pull latest decks'),
              // Only the icon triggers a sync — the row itself isn't tappable,
              // so this ListTile is display-only and gets no onTap/ripple.
              trailing: IconButton(
                onPressed: _syncing ? null : _handleSyncNow,
                tooltip: 'Sync now',
                icon: RotationTransition(
                  turns: _syncIconController,
                  child: Icon(
                    Icons.sync,
                    color: _syncing ? AppPageColors.accentOf(context) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      decksSettingsNote(context, 'Syncs to your account on our server.'),
    ];
  }

  List<Widget> _notifications() {
    return [
      if (kIsWeb)
        decksSettingsNote(context, 'Daily reminders are available on Android and iOS only.'),
      AppToggleRow(
        title: 'Daily review reminder',
        subtitle:
            _settings.reviewReminderEnabled
                ? 'At ${_timeLabel(_settings.reviewReminderHour, _settings.reviewReminderMinute)}'
                : 'Off',
        value: _settings.reviewReminderEnabled,
        enabled: !kIsWeb,
        onChanged: kIsWeb ? null : _setReminderEnabled,
      ),
      if (_settings.reviewReminderEnabled && !kIsWeb)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Reminder time'),
          trailing: TextButton(
            onPressed: _pickReminderTime,
            child: Text(
              _timeLabel(_settings.reviewReminderHour, _settings.reviewReminderMinute),
            ),
          ),
        ),
      if (_settings.reviewReminderEnabled && !kIsWeb) _testReminderButton(),
    ];
  }

  List<Widget> _appearance() {
    return [
      AppToggleRow(
        title: 'Keep screen on',
        subtitle: 'Prevent sleep during review sessions',
        value: _settings.keepScreenOn,
        onChanged: (v) => _save(_settings.copyWith(keepScreenOn: v)),
      ),
    ];
  }

  List<Widget> _controls() {
    return [
      AppToggleRow(
        title: 'Enable review gestures',
        subtitle: 'Swipe and double-tap on the card area',
        value: _settings.gesturesEnabled,
        onChanged: (v) => _save(_settings.copyWith(gesturesEnabled: v)),
      ),
      if (_settings.gesturesEnabled) ...[
        _gestureTile('Swipe left', _settings.gestures.swipeLeft, (a) {
          _save(_settings.copyWith(gestures: _settings.gestures.copyWith(swipeLeft: a)));
        }),
        _gestureTile('Swipe right', _settings.gestures.swipeRight, (a) {
          _save(_settings.copyWith(gestures: _settings.gestures.copyWith(swipeRight: a)));
        }),
        _gestureTile('Swipe up', _settings.gestures.swipeUp, (a) {
          _save(_settings.copyWith(gestures: _settings.gestures.copyWith(swipeUp: a)));
        }),
        _gestureTile('Swipe down', _settings.gestures.swipeDown, (a) {
          _save(_settings.copyWith(gestures: _settings.gestures.copyWith(swipeDown: a)));
        }),
        _gestureTile('Double tap', _settings.gestures.doubleTap, (a) {
          _save(_settings.copyWith(gestures: _settings.gestures.copyWith(doubleTap: a)));
        }),
      ],
      decksSettingsNote(
        context,
        'Defaults: swipe left = Again, swipe right = Good, swipe up = reveal.',
      ),
    ];
  }

  List<Widget> _accessibility() {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Card text size'),
        subtitle: Slider(
          value: _settings.cardTextScale,
          min: 0.8,
          max: 1.6,
          divisions: 8,
          label: '${(_settings.cardTextScale * 100).round()}%',
          onChanged: (v) => _save(_settings.copyWith(cardTextScale: v)),
        ),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Review button size'),
        subtitle: Slider(
          value: _settings.reviewButtonScale,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: '${(_settings.reviewButtonScale * 100).round()}%',
          onChanged: (v) => _save(_settings.copyWith(reviewButtonScale: v)),
        ),
      ),
    ];
  }

  List<Widget> _backups() {
    return [
      AppSettingsGroup(
        title: 'Automatic backup',
        subtitle:
            kIsWeb
                ? 'On web, auto-backup stores JSON in browser storage.'
                : 'Save a JSON snapshot of your collection on a schedule.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppToggleRow(
              title: 'Automatic backup',
              subtitle:
                  _settings.autoBackupEnabled
                      ? 'Every ${_settings.autoBackupIntervalDays} day${_settings.autoBackupIntervalDays == 1 ? '' : 's'}'
                      : 'Off',
              value: _settings.autoBackupEnabled,
              onChanged: (v) => _saveAutoBackup(_settings.copyWith(autoBackupEnabled: v)),
            ),
            if (_settings.autoBackupEnabled)
              decksSettingsPickerTile(
                context: context,
                title: 'Backup interval',
                valueLabel: switch (_settings.autoBackupIntervalDays) {
                  1 => 'Daily',
                  3 => 'Every 3 days',
                  7 => 'Weekly',
                  14 => 'Every 2 weeks',
                  30 => 'Monthly',
                  _ => '${_settings.autoBackupIntervalDays} days',
                },
                onTap: () async {
                  final picked = await showModalBottomSheet<int>(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) {
                      return Material(
                        color: AppPageColors.cardBgOf(ctx),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        child: SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const AppSheetHandle(),
                              const Padding(
                                padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Backup interval',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              for (final days in [1, 3, 7, 14, 30])
                                ListTile(
                                  title: Text(switch (days) {
                                    1 => 'Daily',
                                    3 => 'Every 3 days',
                                    7 => 'Weekly',
                                    14 => 'Every 2 weeks',
                                    30 => 'Monthly',
                                    _ => '$days days',
                                  }),
                                  trailing: decksSettingsCheckIcon(
                                    ctx,
                                    _settings.autoBackupIntervalDays == days,
                                  ),
                                  onTap: () => Navigator.pop(ctx, days),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                  if (picked != null) {
                    await _saveAutoBackup(_settings.copyWith(autoBackupIntervalDays: picked));
                  }
                },
              ),
          ],
        ),
      ),
      AppSettingsGroup(
        title: 'Status',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.brandPrimary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.brandPrimary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last backup',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _backingUp ? 'Backing up…' : _lastBackupLabel,
                      style: TextStyle(fontSize: 12, color: AppPageColors.subtitleOf(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      AppSettingsGroup(
        title: 'Actions',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            decksSettingsActionTile(
              context: context,
              icon: Icons.backup_outlined,
              title: 'Back up now',
              subtitle: _backingUp ? 'Backing up…' : 'Export full collection JSON',
              onTap: _handleBackupNow,
            ),
            decksSettingsActionTile(
              context: context,
              icon: Icons.restore_outlined,
              title: 'Restore from backup',
              subtitle: 'Import a JSON backup file',
              onTap: _restoreBackup,
            ),
            decksSettingsActionTile(
              context: context,
              icon: Icons.download_outlined,
              title: 'Export JSON',
              subtitle: 'Manual export to file or share',
              onTap: _exportJsonManual,
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _advanced() {
    return [
      AppSettingsGroup(
        title: 'Settings file',
        subtitle: 'Export or import your review preferences as JSON.',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            decksSettingsActionTile(
              context: context,
              icon: Icons.upload_outlined,
              title: 'Export review settings',
              subtitle: 'Share a JSON file of your preferences',
              onTap: _exportSettings,
            ),
            decksSettingsActionTile(
              context: context,
              icon: Icons.download_outlined,
              title: 'Import review settings',
              subtitle: 'Load preferences from a JSON file',
              onTap: _importSettings,
            ),
          ],
        ),
      ),
      AppSettingsGroup(
        title: 'Reset',
        subtitle: 'Restore all Decks review preferences to factory defaults.',
        child: decksSettingsActionTile(
          context: context,
          icon: Icons.restart_alt_rounded,
          title: 'Reset review settings',
          subtitle: 'Cannot be undone',
          destructive: true,
          onTap: _resetSettings,
        ),
      ),
    ];
  }

  List<Widget> _about() {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('App version'),
        subtitle: Text(_appVersion ?? 'Loading…'),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Deck help'),
        subtitle: const Text('Import, review gestures, and sync tips'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DecksHelpScreen()),
          );
        },
      ),
      decksSettingsNote(
        context,
        'Flashcards use spaced repetition with cloud sync to your account.',
      ),
    ];
  }
}
