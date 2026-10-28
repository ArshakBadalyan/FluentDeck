import 'package:flutter/material.dart';

import '../ui_elements/modern_page_widgets.dart';
import 'speaking_item_icons.dart';

/// A deck's icon and tile tint, the same on every screen: corrections from
/// speaking get the coral mic, saved words the teal bookmark, other decks an
/// icon and tint picked from their name.
IconData deckIcon(String name) {
  final n = name.toLowerCase();
  if (n.contains('speaking') || n.contains('correction')) return Icons.mic_rounded;
  if (n.contains('saved')) return Icons.bookmark_border_rounded;
  return resolveSpeakingListIcon(title: name, iconKey: '');
}

AppTint deckTint(String name) {
  final n = name.toLowerCase();
  if (n.contains('speaking') || n.contains('correction')) return AppTint.voice;
  if (n.contains('saved')) return AppTint.teal;
  return speakingIconTint(name);
}

/// Rounded tinted square holding [deckIcon].
class DeckIconTile extends StatelessWidget {
  const DeckIconTile({super.key, required this.name, this.size = 40, this.iconSize = 18});

  final String name;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tint = deckTint(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppPageColors.tintOf(context, tint).bg,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(deckIcon(name), size: iconSize, color: AppPageColors.tintIconOf(context, tint)),
    );
  }
}
