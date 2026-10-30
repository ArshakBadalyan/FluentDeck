import 'package:flutter/material.dart';
import 'package:riovox/localization/app_localizations.dart';
import 'package:riovox/ui_elements/modern_page_widgets.dart';

class SoftwarePage extends StatelessWidget {
  const SoftwarePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.instance.t('profile.about-us.software-licenses'),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder:
            (_, __) => Divider(
              height: 24,
              thickness: 0.6,
              color: AppPageColors.subtleBorderOf(context),
            ),
        itemBuilder: (context, index) {
          return Text(
            _items[index],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          );
        },
      ),
    );
  }
}

const List<String> _items = [
  'OneSignal',
  'Microsoft Clarity',
  'Strapi',
  'Flutter',
  'Google Places API',
  'Moment.js',
  'better-sqlite3',
  'i18n',
  'PostgreSQL client',
];
