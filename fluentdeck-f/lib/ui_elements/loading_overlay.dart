import 'package:flutter/material.dart';

/// Centered loading animation for cold start. Use with a [Scaffold] whose
/// [Scaffold.backgroundColor] is solid white so the screen does not show the
/// default window color around the indicator.
class LaunchLoadingIndicator extends StatelessWidget {
  const LaunchLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) => const _LoadingGif();
}

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const Center(
          child: _LoadingGif(),
        ),
      ],
    );
  }
}

class _LoadingGif extends StatelessWidget {
  const _LoadingGif();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/gifs/loading.gif',
      width: 90,
      height: 90,
      fit: BoxFit.contain,
      key: const ValueKey('loading_gif'),
    );
  }
}
