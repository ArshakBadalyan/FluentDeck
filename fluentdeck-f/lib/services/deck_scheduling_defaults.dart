import '../models/app_feature_config_model.dart';
import '../models/flashcard_model.dart';
import '../services/app_feature_config_service.dart';

/// App-wide default deck scheduling (Again/Hard/Good/Easy intervals).
/// Loaded from Strapi `app-feature-config-public` at startup.
abstract final class DeckSchedulingDefaults {
  static AppFeatureConfigModel get _config =>
      AppFeatureConfigService.instance.config;

  static List<int> get learningStepsMinutes {
    final steps = _config.defaultLearningStepsMinutes;
    return steps.isNotEmpty ? steps : const [2, 8, 10];
  }

  static double get easyIntervalDays => _config.defaultEasyIntervalDays;

  static DeckOptionsModel get deckOptions => DeckOptionsModel(
    learningStepsMinutes: learningStepsMinutes,
    easyIntervalDays: easyIntervalDays,
  );
}
