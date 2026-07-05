import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/screens/learn_screen/decks_help_screen.dart';
import 'package:fluentdeck/screens/learn_screen/decks_settings_section.dart';
import 'package:fluentdeck/screens/learn_screen/note_types_screen.dart';
import 'package:fluentdeck/screens/learn_screen/shared_decks_screen.dart';
import 'package:fluentdeck/screens/learn_screen/widgets/decks_settings_widgets.dart';
import 'package:fluentdeck/services/deck_notification_service.dart';
import 'package:fluentdeck/services/flashcard_export_service.dart';
import 'package:fluentdeck/services/flashcard_import_service.dart';
import 'package:fluentdeck/services/flashcard_sync_store.dart';
import 'package:fluentdeck/services/review_settings_store.dart';
import 'package:fluentdeck/ui_elements/frosted_bottom_sheet.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';

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

class _DecksSettingsSectionScreenState extends State<DecksSettingsSectionScreen> {
  late ReviewSettings _settings;
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    if (widget.section == DecksSettingsSection.about) {
      _loadVersion();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant DecksSettingsSectionScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _settings = widget.settings;
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

  String _timeLabel(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
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

  static String _hourLabel(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour $period';
  }

  Future<void> _pickNextDayStart() async {
    final picked = await showFrostedBottomSheet<int>(
      context: context,
      builder: (ctx) {
        var selected = _settings.nextDayStartHour;
        final controller = FixedExtentScrollController(initialItem: selected);
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const Text(
                      'Start of next day',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cards due before this time still count as "today". Affects daily limits and stats — deck limits are set per deck.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.35),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _hourLabel(selected),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        IgnorePointer(
                          child: Container(
                            height: 44,
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: AppColors.primaryPurple.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.primaryPurple.withValues(alpha: 0.25),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 200,
                          child: CupertinoPicker(
                            scrollController: controller,
                            itemExtent: 44,
                            diameterRatio: 1.1,
                            selectionOverlay: const SizedBox.shrink(),
                            onSelectedItemChanged: (index) {
                              HapticFeedback.selectionClick();
                              setLocal(() => selected = index);
                            },
                            children: List.generate(24, (hour) {
                              final isSelected = hour == selected;
                              return Center(
                                child: Text(
                                  _hourLabel(hour),
                                  style: TextStyle(
                                    fontSize: isSelected ? 20 : 17,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? Colors.black87 : Colors.grey.shade500,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.pop(ctx, selected),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryPurple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked == null) return;
    await _save(_settings.copyWith(nextDayStartHour: picked));
  }

  Future<void> _pickGesture(
    String title,
    ReviewGestureAction current,
    void Function(ReviewGestureAction) onSelected,
  ) async {
    final picked = await showModalBottomSheet<ReviewGestureAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                  ...ReviewGestureAction.values.map(
                    (action) => ListTile(
                      title: Text(reviewGestureActionLabel(action)),
                      trailing: decksSettingsCheckIcon(current == action),
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'New card position',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                ...NewCardPosition.values.map(
                  (pos) => ListTile(
                    title: Text(newCardPositionLabel(pos)),
                    trailing: decksSettingsCheckIcon(_settings.newCardPosition == pos),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _exportJsonManual() async {
    try {
      await FlashcardExportService.instance.exportJsonFile();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _resetSettings() async {
    final ok = await showDialog<bool>(
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
        ScaffoldMessenger.of(context).showSnackBar(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review settings imported')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _gestureTile(
    String label,
    ReviewGestureAction action,
    ValueChanged<ReviewGestureAction> onChanged,
  ) {
    return decksSettingsPickerTile(
      title: label,
      valueLabel: reviewGestureActionLabel(action),
      onTap: () => _pickGesture(label, action, onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(widget.section.title),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: _sectionChildren(),
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
      decksSettingsPickerTile(
        title: 'Start of next day',
        subtitle: Text('Day rolls over at ${_hourLabel(_settings.nextDayStartHour)}'),
        valueLabel: 'Change',
        onTap: _pickNextDayStart,
      ),
      decksSettingsNote(
        'Affects daily limits and “today” statistics. Deck limits are set per deck.',
      ),
      const SizedBox(height: 12),
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
            ScaffoldMessenger.of(context).showSnackBar(
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
    ];
  }

  List<Widget> _newStudyScreen() {
    return [
      decksSettingsPickerTile(
        title: 'New card position',
        subtitle: const Text('Order of new cards vs reviews in a session'),
        valueLabel: newCardPositionLabel(_settings.newCardPosition),
        onTap: _pickNewCardPosition,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Learn ahead limit'),
        subtitle: Slider(
          value: _settings.learnAheadMinutes.toDouble(),
          min: 0,
          max: 60,
          divisions: 12,
          label: '${_settings.learnAheadMinutes} min',
          onChanged: (v) => _save(_settings.copyWith(learnAheadMinutes: v.round())),
        ),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show remaining due counts'),
        subtitle: const Text('Display new/learning/review counts during study'),
        value: _settings.showDueCountInStudy,
        activeThumbColor: AppColors.primaryPurple,
        onChanged: (v) => _save(_settings.copyWith(showDueCountInStudy: v)),
      ),
      decksSettingsNote(
        'Learn ahead may show cards due slightly early when supported by the scheduler.',
      ),
    ];
  }

  List<Widget> _reviewing() {
    return [
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
      const SizedBox(height: 8),
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.orangeHard.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.trending_down_rounded,
              size: 16,
              color: AppColors.orangeHard,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Rating buttons',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      AppToggleRow(
        title: 'Show Hard button',
        subtitle: 'Adds a fourth rating between Again and Good',
        value: _settings.showHardButton,
        onChanged: (v) => _save(_settings.copyWith(showHardButton: v)),
      ),
      const SizedBox(height: 6),
      decksSettingsLabelField('Again button label', _settings.labelAgain, (v) {
        _save(_settings.copyWith(labelAgain: v));
      }),
      if (_settings.showHardButton)
        decksSettingsLabelField('Hard button label', _settings.labelHard, (v) {
          _save(_settings.copyWith(labelHard: v));
        }),
      decksSettingsLabelField('Good button label', _settings.labelGood, (v) {
        _save(_settings.copyWith(labelGood: v));
      }),
      decksSettingsLabelField('Easy button label', _settings.labelEasy, (v) {
        _save(_settings.copyWith(labelEasy: v));
      }),
      const SizedBox(height: 16),
      decksSettingsSectionHeader('Leeches'),
      AppToggleRow(
        title: 'Leech auto-suspend',
        subtitle: 'Notify when a card is auto-suspended',
        value: _settings.leechAutoSuspend,
        onChanged: (v) => _save(_settings.copyWith(leechAutoSuspend: v)),
      ),
      const SizedBox(height: 4),
      Text('Leech threshold', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
      Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primaryPurple,
                thumbColor: AppColors.primaryPurple,
                overlayColor: AppColors.primaryPurple.withValues(alpha: 0.15),
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
              color: AppColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${_settings.leechThreshold}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryPurple),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      decksSettingsSectionHeader('Daily reminder'),
      if (kIsWeb)
        decksSettingsNote('Daily reminders are available on Android and iOS only.'),
      AppToggleRow(
        title: 'Daily review reminder',
        subtitle:
            _settings.reviewReminderEnabled
                ? 'At ${_timeLabel(_settings.reviewReminderHour, _settings.reviewReminderMinute)}'
                : 'Off',
        value: _settings.reviewReminderEnabled,
        enabled: !kIsWeb,
        onChanged:
            kIsWeb
                ? null
                : (v) => _save(_settings.copyWith(reviewReminderEnabled: v)),
      ),
      if (_settings.reviewReminderEnabled && !kIsWeb) ...[
        const SizedBox(height: 8),
        decksSettingsPickerTile(
          title: 'Reminder time',
          valueLabel: _timeLabel(_settings.reviewReminderHour, _settings.reviewReminderMinute),
          onTap: _pickReminderTime,
        ),
      ],
    ];
  }

  List<Widget> _sync() {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Last sync'),
        subtitle: Text(widget.syncLog.lastSuccessLabel),
      ),
      if (widget.syncLog.lastError != null)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Last sync error'),
          subtitle: Text(
            widget.syncLog.lastError!,
            style: TextStyle(color: Colors.red.shade700, fontSize: 13),
          ),
        ),
      if (widget.syncLog.lastApplied > 0 || widget.syncLog.lastSkipped > 0)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Last upload'),
          subtitle: Text(
            '${widget.syncLog.lastApplied} applied, ${widget.syncLog.lastSkipped} skipped (server wins on conflict)',
          ),
        ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Sync now'),
        subtitle: const Text('Upload pending reviews and pull latest decks'),
        trailing:
            widget.syncing
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : const Icon(Icons.sync),
        onTap: widget.syncing ? null : widget.onSyncNow,
      ),
      decksSettingsNote('Syncs to your account on our server.'),
    ];
  }

  List<Widget> _notifications() {
    return [
      if (kIsWeb)
        decksSettingsNote('Daily reminders are available on Android and iOS only.'),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Daily review reminder'),
        subtitle: Text(
          _settings.reviewReminderEnabled
              ? 'At ${_timeLabel(_settings.reviewReminderHour, _settings.reviewReminderMinute)}'
              : 'Off',
        ),
        value: _settings.reviewReminderEnabled,
        activeThumbColor: AppColors.primaryPurple,
        onChanged:
            kIsWeb
                ? null
                : (v) => _save(_settings.copyWith(reviewReminderEnabled: v)),
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
    ];
  }

  List<Widget> _appearance() {
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Dark mode (Decks)'),
        subtitle: const Text('Dark theme for the Decks section only'),
        value: _settings.darkMode,
        activeThumbColor: AppColors.primaryPurple,
        onChanged: (v) => _save(_settings.copyWith(darkMode: v)),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Keep screen on'),
        subtitle: const Text('Prevent sleep during review sessions'),
        value: _settings.keepScreenOn,
        activeThumbColor: AppColors.primaryPurple,
        onChanged: (v) => _save(_settings.copyWith(keepScreenOn: v)),
      ),
    ];
  }

  List<Widget> _controls() {
    return [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Enable review gestures'),
        subtitle: const Text('Swipe and double-tap on the card area'),
        value: _settings.gesturesEnabled,
        activeThumbColor: AppColors.primaryPurple,
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
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Automatic backup'),
        subtitle: Text(
          kIsWeb
              ? 'On web, auto-backup stores JSON locally in browser'
              : 'Saves JSON to device every ${_settings.autoBackupIntervalDays} days',
        ),
        value: _settings.autoBackupEnabled,
        activeThumbColor: AppColors.primaryPurple,
        onChanged: (v) => _save(_settings.copyWith(autoBackupEnabled: v)),
      ),
      if (_settings.autoBackupEnabled)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Backup interval'),
          trailing: DropdownButton<int>(
            value: _settings.autoBackupIntervalDays,
            items: const [
              DropdownMenuItem(value: 1, child: Text('Daily')),
              DropdownMenuItem(value: 3, child: Text('Every 3 days')),
              DropdownMenuItem(value: 7, child: Text('Weekly')),
              DropdownMenuItem(value: 14, child: Text('Every 2 weeks')),
              DropdownMenuItem(value: 30, child: Text('Monthly')),
            ],
            onChanged:
                (v) =>
                    v == null ? null : _save(_settings.copyWith(autoBackupIntervalDays: v)),
          ),
        ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Last backup'),
        subtitle: Text(widget.lastBackupLabel),
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Back up now'),
        subtitle: const Text('Export full collection JSON'),
        trailing: const Icon(Icons.backup_outlined),
        onTap: widget.onBackupNow,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Restore from backup'),
        subtitle: const Text('Import a JSON backup file'),
        trailing: const Icon(Icons.restore_outlined),
        onTap: _restoreBackup,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Export JSON'),
        subtitle: const Text('Manual export to file or share'),
        trailing: const Icon(Icons.download_outlined),
        onTap: _exportJsonManual,
      ),
    ];
  }

  List<Widget> _advanced() {
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Export review settings'),
        trailing: const Icon(Icons.upload_outlined),
        onTap: _exportSettings,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Import review settings'),
        trailing: const Icon(Icons.download_outlined),
        onTap: _importSettings,
      ),
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Reset review settings'),
        trailing: const Icon(Icons.restart_alt),
        onTap: _resetSettings,
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
        'Flashcards use spaced repetition with cloud sync to your account.',
      ),
    ];
  }
}
