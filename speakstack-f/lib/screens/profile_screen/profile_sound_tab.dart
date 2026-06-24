import 'package:flutter/material.dart';
import 'package:untitled2/localization/app_localizations.dart';

import '../../services/audio_service.dart';
import '../../services/auth_service.dart';
import '../../ui_elements/loading_overlay.dart';
import '../../ui_elements/modern_page_widgets.dart';

class ProfileSoundTab extends StatefulWidget {
  const ProfileSoundTab({super.key});

  @override
  State<ProfileSoundTab> createState() => _ProfileSoundTabState();
}

class _ProfileSoundTabState extends State<ProfileSoundTab>
    with AutomaticKeepAliveClientMixin {
  bool soundEnabled = false;
  double soundVolume = 50;

  bool isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadUserSound();
  }

  Future<void> _loadUserSound() async {
    final res = await AuthService.getUser();

    if (!mounted) return;

    if (res['status'] == 'success') {
      final user = res['user'];

      soundEnabled = user['sound'] ?? false;
      soundVolume = soundEnabled ? (user['volume_sound'] ?? 50).toDouble() : 0;
    }

    setState(() => isLoading = false);
  }

  Future<void> _toggleSound(bool value) async {
    setState(() {
      soundEnabled = value;
      if (!value) {
        soundVolume = 0;
      } else if (soundVolume == 0) {
        soundVolume = 50;
      }
    });

    AudioService().updateSettings(
      enabled: soundEnabled,
      volumePercent: soundVolume,
    );

    if (soundEnabled) {
      AudioService().play('correct');
    }

    await AuthService.updateUser({
      'sound': soundEnabled,
      'volume_sound': soundVolume.toInt(),
    });
  }

  Future<void> _updateVolume(double value) async {
    setState(() {
      AudioService().updateSettings(enabled: true, volumePercent: value);
      soundVolume = value;

      if (value == 0) {
        soundEnabled = false;
      } else if (!soundEnabled) {
        soundEnabled = true;
      }
    });
    if (value > 0) {
      AudioService().play('correct');
    }
    await AuthService.updateUser({
      'sound': soundEnabled,
      'volume_sound': soundVolume.toInt(),
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (isLoading) {
      return const AppPageBackground(child: Center(child: LoadingOverlay()));
    }

    return AppPageBackground(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: AppSectionCard(
          title: context.tr('profile.sound.sound'),
          icon: Icons.volume_up_outlined,
          subtitle: 'Control app sounds and feedback volume',
          child: Column(
            children: [
              AppToggleRow(
                title: context.tr('profile.sound.sound'),
                value: soundEnabled,
                onChanged: _toggleSound,
              ),
              const SizedBox(height: 16),
              AppSliderRow(
                title: context.tr('profile.sound.sound-volume'),
                value: soundVolume,
                min: 0,
                max: 100,
                divisions: 100,
                label: '${soundVolume.round()}%',
                onChanged: (value) {
                  setState(() {
                    soundVolume = value;
                    if (value == 0) {
                      soundEnabled = false;
                    } else if (!soundEnabled) {
                      soundEnabled = true;
                    }
                  });
                },
                onChangeEnd: _updateVolume,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
