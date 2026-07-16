import 'package:flutter/material.dart';

/// Matches purple auth CTAs on forgot / reset password screens (`ElevatedButton` there).
const Color _kAuthFlowPurple = Color(0xFF7E2BFF);

/// Purple text link below the primary CTA on auth sub-flows (forgot / reset password).
class AuthSecondaryLink extends StatelessWidget {
  const AuthSecondaryLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: const TextStyle(
            color: _kAuthFlowPurple,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Footer line: plain [leadingText], gap, then purple tappable [linkLabel] (login ↔ register).
class AuthInlineSwitchLink extends StatelessWidget {
  const AuthInlineSwitchLink({
    super.key,
    required this.leadingText,
    required this.linkLabel,
    required this.onLinkPressed,
    this.enabled = true,
  });

  final String leadingText;
  final String linkLabel;
  final VoidCallback onLinkPressed;
  final bool enabled;

  static const double _gap = 8;

  @override
  Widget build(BuildContext context) {
    final baseStyle = DefaultTextStyle.of(context).style;
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 0,
        runSpacing: 6,
        children: [
          Text(
            leadingText,
            style: baseStyle.copyWith(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: _gap),
            child: TextButton(
              onPressed: enabled ? onLinkPressed : null,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: _kAuthFlowPurple,
              ),
              child: Text(
                linkLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
