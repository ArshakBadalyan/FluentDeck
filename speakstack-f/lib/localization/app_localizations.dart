import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../config/app_language.dart';

class AppLocalizations extends ChangeNotifier {
  AppLocalizations._();

  static final AppLocalizations instance = AppLocalizations._();

  static const String _defaultLanguage = 'de';

  final Map<String, dynamic> _deMap = {};
  final Map<String, dynamic> _enMap = {};
  final Map<String, dynamic> _activeMap = {};

  String _activeLanguage = _defaultLanguage;
  bool _isLoaded = false;

  String get language => _activeLanguage;
  Locale get locale => Locale(_activeLanguage);
  bool get isLoaded => _isLoaded;
  bool get isEnglish => _activeLanguage == 'en';
  bool get isGerman => _activeLanguage == 'de';

  Future<void> load() async {
    final deLoaded = await _safeLoadLocale('de');
    final enLoaded = await _safeLoadLocale('en');

    _deMap
      ..clear()
      ..addAll(deLoaded);
    _enMap
      ..clear()
      ..addAll(enLoaded);

    final initialLanguage = await AppLanguage.resolveCurrent();
    _applyLanguage(initialLanguage);

    _isLoaded = true;
  }

  Future<void> setLanguage(String language) async {
    await AppLanguage.setOverride(language);
    _applyLanguage(language);
    notifyListeners();
  }

  void _applyLanguage(String language) {
    _activeLanguage = AppLanguage.supportedLanguages.contains(language)
        ? language
        : _defaultLanguage;
    final source = _activeLanguage == 'en' ? _enMap : _deMap;
    _activeMap
      ..clear()
      ..addAll(source);
  }

  String t(String key, {Map<String, dynamic>? vars, String? fallback}) {
    final fromActive = _lookupString(_activeMap, key);
    final fromDefault = _lookupString(_deMap, key);
    final raw = fromActive ?? fromDefault ?? fallback ?? key;
    return _interpolate(raw, vars);
  }

  dynamic value(String key) {
    final fromActive = _lookupAny(_activeMap, key);
    if (fromActive != null) return fromActive;
    return _lookupAny(_deMap, key);
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
