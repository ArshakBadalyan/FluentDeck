import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riovox/config/toast_config.dart';
import 'package:riovox/ui_elements/app_toast.dart';

void main() {
  testWidgets('toast renders above a bottom sheet', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const SizedBox(height: 2000),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    AppToast.showSnackBar(
      null,
      const SnackBar(content: Text('Enter the Front (word or phrase) first')),
    );
    await tester.pump(ToastConfig.animationDuration);

    expect(find.text('Enter the Front (word or phrase) first'), findsOneWidget);
    expect(find.byIcon(ToastConfig.styles[ToastType.warning]!.icon), findsOneWidget);
    // Hit-testable, i.e. painted on top of the full-height sheet.
    expect(
      tester.hitTestOnBinding(
        tester.getCenter(find.text('Enter the Front (word or phrase) first')),
      ).path.any((e) => e.target is RenderParagraph),
      isTrue,
    );

    await tester.pump(const Duration(seconds: 8));
    await tester.pumpAndSettle();
    expect(find.text('Enter the Front (word or phrase) first'), findsNothing);
  });

  testWidgets('error text gets the error style', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => AppToastHost(child: child!),
        home: const Scaffold(),
      ),
    );
    AppToast.showSnackBar(null, const SnackBar(content: Text('Could not translate. Try again.')));
    await tester.pump(ToastConfig.animationDuration);
    expect(find.byIcon(ToastConfig.styles[ToastType.error]!.icon), findsOneWidget);
    AppToast.dismissAll();
    await tester.pumpAndSettle();
  });
}
