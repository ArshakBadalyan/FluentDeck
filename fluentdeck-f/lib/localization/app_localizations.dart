import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../config/app_language.dart';

class AppLocalizations extends ChangeNotifier {
  AppLocalizations._();

  static final AppLocalizations instance = AppLocalizations._();

  /// Convenience accessor matching Flutter l10n conventions; returns [instance].
  static AppLocalizations of(BuildContext context) => instance;

  static const String _defaultLanguage = 'en';

  /// English is the source and the fallback for any key a translation lacks.
  final Map<String, dynamic> _enMap = {};
  final Map<String, dynamic> _activeMap = {};

  String _activeLanguage = _defaultLanguage;
  bool _isLoaded = false;
  Set<String> _available = {_defaultLanguage};

  String get language => _activeLanguage;
  Locale get locale => Locale(_activeLanguage);
  bool get isLoaded => _isLoaded;
  bool get isEnglish => _activeLanguage == 'en';
  bool get isGerman => _activeLanguage == 'de';

  /// Languages that ship a locale file, in picker order.
  List<AppLanguageOption> get availableOptions => [
    for (final o in AppLanguage.options)
      if (_available.contains(o.code)) o,
  ];

  Future<void> load() async {
    _available = await _shippedLanguages();
    _enMap
      ..clear()
      ..addAll(await _safeLoadLocale(_defaultLanguage));
    await _applyLanguage(
      await AppLanguage.resolveCurrent(available: _available),
    );
    _isLoaded = true;
  }

  Future<void> setLanguage(String language) async {
    await AppLanguage.setOverride(language);
    await _applyLanguage(language);
    notifyListeners();
  }

  /// Only the active language is parsed; switching loads the new one.
  Future<void> _applyLanguage(String language) async {
    _activeLanguage = _available.contains(language) ? language : _defaultLanguage;
    final source =
        _activeLanguage == _defaultLanguage
            ? _enMap
            : await _safeLoadLocale(_activeLanguage);
    _activeMap
      ..clear()
      ..addAll(source);
  }

  /// Locale files bundled with the app (pubspec lists `assets/locales/`).
  Future<Set<String>> _shippedLanguages() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final codes = {
        for (final path in manifest.listAssets())
          if (path.startsWith('assets/locales/') && path.endsWith('.json'))
            path.substring('assets/locales/'.length, path.length - '.json'.length),
      };
      return {_defaultLanguage, ...codes.intersection(AppLanguage.supportedLanguages)};
    } catch (_) {
      return {_defaultLanguage};
    }
  }

  String t(String key, {Map<String, dynamic>? vars, String? fallback}) {
    final fromActive = _lookupString(_activeMap, key);
    final fromDefault = _lookupString(_enMap, key);
    final raw = fromActive ?? fromDefault ?? fallback ?? key;
    return _interpolate(raw, vars);
  }

  dynamic value(String key) {
    final fromActive = _lookupAny(_activeMap, key);
    if (fromActive != null) return fromActive;
    return _lookupAny(_enMap, key);
  }

  Future<Map<String, dynamic>> _safeLoadLocale(String language) async {
    try {
      final raw = await rootBundle.loadString('assets/locales/$language.json');
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }

  String? _lookupString(Map<String, dynamic> map, String keyPath) {
    final value = _lookupAny(map, keyPath);
    return value is String ? value : null;
  }

  dynamic _lookupAny(Map<String, dynamic> map, String keyPath) {
    dynamic current = map;
    final parts = keyPath.split('.');

    for (final part in parts) {
      // Prefer object/map lookup first so numeric keys like "10"
      // work for paths such as practice.mode-scores.10.
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
        continue;
      }

      final index = int.tryParse(part);
      if (index != null) {
        if (current is List && index >= 0 && index < current.length) {
          current = current[index];
          continue;
        }
        return null;
      }
      return null;
    }

    return current;
  }

  String _interpolate(String text, Map<String, dynamic>? vars) {
    if (vars == null || vars.isEmpty) {
      return text;
    }

    var output = text;
    vars.forEach((key, value) {
      output = output.replaceAll('{$key}', value?.toString() ?? '');
    });
    return output;
  }
}

extension AppLocalizationContext on BuildContext {
  String tr(String key, {Map<String, dynamic>? vars, String? fallback}) {
    return AppLocalizations.instance.t(key, vars: vars, fallback: fallback);
  }

  /// Resolves [messageKey] from a service error map (thrown API errors) before falling back to [message].
  String trServiceError(
    Map<String, dynamic> res, {
    String fallbackKey = 'errors.unexpected',
  }) {
    final rawKey = res['messageKey'];
    if (rawKey is String && rawKey.isNotEmpty) {
      return tr(rawKey);
    }
    final rawMsg = res['message'];
    if (rawMsg is String && rawMsg.trim().isNotEmpty) {
      return rawMsg.trim();
    }
    return tr(fallbackKey);
  }
}
