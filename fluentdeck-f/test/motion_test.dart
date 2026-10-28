import 'package:animations/animations.dart';
import 'package:fluentdeck/app_colors.dart';
import 'package:fluentdeck/app_theme.dart';
import 'package:fluentdeck/config/brand_config.dart';
import 'package:fluentdeck/services/daily_goal_tracker.dart';
import 'package:fluentdeck/services/speaking_preferences_service.dart';
import 'package:fluentdeck/models/speaking_preferences.dart';
import 'package:fluentdeck/ui_elements/app_dialog.dart';
import 'package:fluentdeck/ui_elements/app_motion.dart';
import 'package:fluentdeck/ui_elements/modern_page_widgets.dart';
import 'package:fluentdeck/ui_elements/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

double _scaleOf(WidgetTester tester, Finder within) => tester
    .widget<AnimatedScale>(
      find.descendant(of: within, matching: find.byType(AnimatedScale)).first,
    )
    .scale;

Future<BuildContext> _context(WidgetTester tester, {bool reduceMotion = false}) async {
  late BuildContext ctx;
  await tester.pumpWidget(
    _app(
      Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
      reduceMotion: reduceMotion,
    ),
  );
  return ctx;
}

void main() {
  phase2to4Tests();
  remainingPhaseTests();
  goalRingTests();
  group('Material 2 theme', () {
    test('light and dark themes are Material 2 with brand toggles', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        expect(theme.useMaterial3, isFalse);
        expect(theme.splashFactory, InkRipple.splashFactory);
        // In M2, switches/checkboxes/FAB use the secondary color.
        expect(theme.colorScheme.secondary, theme.colorScheme.primary);
      }
      expect(AppTheme.light.colorScheme.primary, AppColors.brandPrimary);
      expect(AppTheme.dark.colorScheme.primary, AppColors.brandPrimaryOnDark);
    });

    test('chips are brand-tinted and keep the Rubik font (not M2 grey / system font)', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final chips = theme.chipTheme;
        expect(chips.labelStyle!.fontFamily, BrandConfig.fontFamily);
        expect(chips.secondaryLabelStyle!.fontFamily, BrandConfig.fontFamily);
        expect(chips.checkmarkColor, theme.colorScheme.primary);
      }
    });

    test('FilledButton gets the rounded shape and M2 pressed elevation', () {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        final style = theme.filledButtonTheme.style!;
        final shape = style.shape!.resolve({}) as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.circular(14));
        expect(style.elevation!.resolve({}), 2);
        expect(style.elevation!.resolve({WidgetState.pressed}), 8);
        expect(style.elevation!.resolve({WidgetState.disabled}), 0);
        // Brand colors are kept by the merge.
        expect(style.backgroundColor!.resolve({}), theme.colorScheme.primary);
      }
    });
  });

  group('AppPressScale', () {
    testWidgets('shrinks while pressed, and the tap still reaches the child', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          AppPressScale(
            child: ElevatedButton(onPressed: () => taps++, child: const Text('Go')),
          ),
        ),
      );
      final press = find.byType(AppPressScale);
      expect(_scaleOf(tester, press), 1);

      final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
      await tester.pump();
      expect(_scaleOf(tester, press), 0.97);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_scaleOf(tester, press), 1);
      expect(taps, 1);
    });

    testWidgets('moving the finger (scrolling) releases the press', (tester) async {
      await tester.pumpWidget(
        _app(AppPressScale(child: Container(width: 200, height: 80, color: Colors.teal))),
      );
      final press = find.byType(AppPressScale);
      final gesture = await tester.startGesture(tester.getCenter(press));
      await tester.pump();
      expect(_scaleOf(tester, press), 0.97);
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(_scaleOf(tester, press), 1);
      await gesture.up();
    });

    testWidgets('no shrink when disabled or with reduced motion', (tester) async {
      for (final reduce in [false, true]) {
        await tester.pumpWidget(
          _app(
            AppPressScale(
              enabled: reduce,
              child: Container(width: 200, height: 80, color: Colors.teal),
            ),
            reduceMotion: reduce,
          ),
        );
        final press = find.byType(AppPressScale);
        final gesture = await tester.startGesture(tester.getCenter(press));
        await tester.pump();
        expect(_scaleOf(tester, press), 1);
        await gesture.up();
      }
    });

    testWidgets('turning enabled off keeps the child\'s state', (tester) async {
      Widget build(bool enabled) => _app(
        AppPressScale(enabled: enabled, child: const _Counter()),
      );
      await tester.pumpWidget(build(true));
      await tester.tap(find.text('0'));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      await tester.pumpWidget(build(false));
      expect(find.text('1'), findsOneWidget);
    });
  });

  group('showAppDialog', () {
    testWidgets('fades and scales in, and returns the result', (tester) async {
      final ctx = await _context(tester);
      final result = showAppDialog<String>(
        context: ctx,
        builder: (c) => AlertDialog(
          content: const Text('Delete deck?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, 'yes'), child: const Text('Yes')),
          ],
        ),
      );
      await tester.pump();
      expect(find.byType(FadeScaleTransition), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Delete deck?'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(await result, 'yes');
      expect(find.text('Delete deck?'), findsNothing);
    });

    testWidgets('barrierDismissible: false keeps it open on outside tap', (tester) async {
      final ctx = await _context(tester);
      showAppDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(content: Text('Stay')),
      );
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Stay'), findsOneWidget);
    });

    testWidgets('reduced motion uses a plain dialog', (tester) async {
      final ctx = await _context(tester, reduceMotion: true);
      showAppDialog<void>(context: ctx, builder: (_) => const AlertDialog(content: Text('Hi')));
      await tester.pumpAndSettle();
      expect(find.text('Hi'), findsOneWidget);
      expect(find.byType(FadeScaleTransition), findsNothing);
    });
  });

  group('shared widgets', () {
    testWidgets('PrimaryButton presses in and cross-fades to the spinner', (tester) async {
      Widget button(bool loading) => _app(
        PrimaryButton(text: 'Save', onPressed: () {}, enabled: true, isLoading: loading),
      );
      await tester.pumpWidget(button(false));
      expect(find.byType(AppPressScale), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      await tester.pumpWidget(button(true));
      await tester.pump(const Duration(milliseconds: 60));
      // Mid-transition both are on screen.
      expect(find.text('Save'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The spinner never settles, so wait out the cross-fade instead.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Save'), findsNothing);
    });

    testWidgets('settings tiles press in; section cards fade in', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: [
              AppNavRow(title: 'Backups', onTap: () {}),
              const AppSectionCard(title: 'Reviewing', child: Text('body')),
            ],
          ),
        ),
      );
      expect(
        find.ancestor(of: find.text('Backups'), matching: find.byType(AppPressScale)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: find.text('Reviewing'), matching: find.byType(AppFadeIn)),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.text('body'), findsOneWidget);
    });
  });
}


void phase2to4Tests() {
  group('fade in / stagger', () {
    testWidgets('AppFadeIn(animate: false) appears at rest, same structure', (tester) async {
      await tester.pumpWidget(_app(const AppFadeIn(animate: false, child: Text('old'))));
      final fade = tester.widget<FadeTransition>(
        find.ancestor(of: find.text('old'), matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, 1);
    });

    testWidgets('AppFadeIn with a delay leaves no timer behind', (tester) async {
      await tester.pumpWidget(
        _app(const AppFadeIn(delay: Duration(milliseconds: 500), child: Text('x'))),
      );
      // Disposing mid-delay must not leave a pending Timer (the test would fail).
      await tester.pumpWidget(_app(const SizedBox()));
    });

    testWidgets('only the first screenful staggers', (tester) async {
      await tester.pumpWidget(
        _app(
          Column(
            children: const [
              AppStaggeredFadeIn(index: 0, child: Text('first')),
              AppStaggeredFadeIn(index: 20, child: Text('far down')),
            ],
          ),
        ),
      );
      expect(
        find.ancestor(of: find.text('first'), matching: find.byType(AppFadeIn)),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: find.text('far down'), matching: find.byType(AppFadeIn)),
        findsNothing,
      );
      await tester.pumpAndSettle();
    });
  });

  group('fade through / pulse', () {
    testWidgets('AppFadeThroughSwitcher fades through to the new icon', (tester) async {
      Widget icon(bool recording) => _app(
        AppFadeThroughSwitcher(
          child: Icon(recording ? Icons.stop : Icons.mic, key: ValueKey(recording)),
        ),
      );
      await tester.pumpWidget(icon(false));
      await tester.pumpWidget(icon(true));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(FadeThroughTransition), findsNWidgets(2));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.stop), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsNothing);
    });

    testWidgets('AppPulse loops only while active, never with reduced motion', (tester) async {
      Widget pulse(bool active, {bool reduce = false}) => _app(
        AppPulse(active: active, color: Colors.red, child: const Icon(Icons.mic)),
        reduceMotion: reduce,
      );
      await tester.pumpWidget(pulse(true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(pulse(false));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpWidget(pulse(true, reduce: true));
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('count up / confetti / FAB container', () {
    testWidgets('AppCountUpText counts to the number and keeps the suffix', (tester) async {
      await tester.pumpWidget(_app(const AppCountUpText('1,240 XP')));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('1,240 XP'), findsNothing); // still counting
      await tester.pumpAndSettle();
      expect(find.text('1,240 XP'), findsOneWidget);

      await tester.pumpWidget(_app(const AppCountUpText('12 days')));
      await tester.pumpAndSettle();
      expect(find.text('12 days'), findsOneWidget);
    });

    testWidgets('AppCountUpText shows non-numbers as they are', (tester) async {
      await tester.pumpWidget(_app(const AppCountUpText('B2')));
      expect(find.text('B2'), findsOneWidget);
    });

    testWidgets('confetti plays once and stops; none with reduced motion', (tester) async {
      await tester.pumpWidget(
        _app(const AppConfettiBurst(colors: [Colors.teal], child: Text('Done'))),
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
      expect(find.text('Done'), findsOneWidget);

      await tester.pumpWidget(
        _app(
          const AppConfettiBurst(colors: [Colors.teal], child: Text('Calm')),
          reduceMotion: true,
        ),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('FAB grows into its page and hands back the result', (tester) async {
      Object? closedWith = 'not closed';
      await tester.pumpWidget(
        _app(
          AppFabContainer<bool>(
            fab: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
            openBuilder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ),
            onClosed: (saved) => closedWith = saved,
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(OpenContainer<bool>), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(closedWith, isTrue);
      expect(find.text('Save'), findsNothing);
    });
  });
}


void remainingPhaseTests() {
  group('loading, typing, charts, routes', () {
    testWidgets('AppLoadingSwitcher cross-fades skeleton into content', (tester) async {
      Widget screen(bool loading) => _app(
        AppLoadingSwitcher(
          loading: loading,
          child: Text(loading ? 'skeleton' : 'content'),
        ),
      );
      await tester.pumpWidget(screen(true));
      await tester.pumpWidget(screen(false));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('skeleton'), findsOneWidget); // fading out
      expect(find.text('content'), findsOneWidget); // fading in
      await tester.pumpAndSettle();
      expect(find.text('skeleton'), findsNothing);
    });

    testWidgets('AppTypingDots animates; static with reduced motion', (tester) async {
      await tester.pumpWidget(_app(const AppTypingDots(color: Colors.teal)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpWidget(
        _app(const AppTypingDots(color: Colors.teal), reduceMotion: true),
      );
      await tester.pump();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('AppChartReveal clips while revealing, then shows the chart plainly', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          const AppChartReveal(
            style: AppChartRevealStyle.up,
            child: SizedBox(width: 100, height: 100, child: Text('chart')),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(ClipRect), findsWidgets);
      final size = tester.getSize(find.byType(AppChartReveal));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(AppChartReveal)), size); // no layout jump
      expect(
        find.descendant(of: find.byType(AppChartReveal), matching: find.byType(ClipRect)),
        findsNothing,
      );
    });

    testWidgets('settings pages open on the Z axis (scaled shared axis)', (tester) async {
      late BuildContext ctx;
      await tester.pumpWidget(
        _app(Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        })),
      );
      Navigator.of(ctx).push(
        AppSharedAxisRoute<void>(
          transitionType: SharedAxisTransitionType.scaled,
          page: const Text('Settings'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final transition = tester.widget<SharedAxisTransition>(
        find.byType(SharedAxisTransition, skipOffstage: false).last,
      );
      expect(transition.transitionType, SharedAxisTransitionType.scaled);
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('empty hints fade in', (tester) async {
      await tester.pumpWidget(_app(const AppEmptyHint(text: 'No notes yet')));
      expect(
        find.ancestor(of: find.text('No notes yet'), matching: find.byType(AppFadeIn)),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
    });

    testWidgets('recording waveform repaints when a mic level arrives', (tester) async {
      final levels = ValueNotifier<List<double>>(const []);
      addTearDown(levels.dispose);
      await tester.pumpWidget(
        _app(AppRecordingWaveform(levels: levels, color: AppColors.redWrong)),
      );
      final painter = tester
          .widget<CustomPaint>(
            find.descendant(
              of: find.byType(AppRecordingWaveform),
              matching: find.byType(CustomPaint),
            ),
          )
          .painter!;
      var repaints = 0;
      painter.addListener(() => repaints++);
      levels.value = const [0.2, 0.9];
      expect(repaints, 1);
      // Its own repaint boundary: the loop doesn't repaint the chat around it.
      expect(
        find.descendant(
          of: find.byType(AppRecordingWaveform),
          matching: find.byType(RepaintBoundary),
        ),
        findsOneWidget,
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('daily goal celebration trigger', () {
    final service = DailyGoalTracker.instance;
    final prefs = SpeakingPreferencesService.instance;

    test('fires once when today\'s correct sentences cross the goal', () {
      prefs.updateLocal(
        const SpeakingPreferences(correctSentenceGoal: 3, correctSentencesToday: 1),
      );
      final start = service.dailyGoalReached.value;

      service.applySpeakingStats({'correctSentencesToday': 2});
      expect(service.dailyGoalReached.value, start);
      expect(prefs.current.correctSentencesToday, 2); // gauge kept in sync

      service.applySpeakingStats({'correctSentencesToday': 3});
      expect(service.dailyGoalReached.value, start + 1);

      // Already past the goal / same day again → no second celebration.
      service.applySpeakingStats({'correctSentencesToday': 4});
      prefs.updateLocal(
        const SpeakingPreferences(correctSentenceGoal: 3, correctSentencesToday: 0),
      );
      service.applySpeakingStats({'correctSentencesToday': 3});
      expect(service.dailyGoalReached.value, start + 1);
    });

    test('ignores missing or malformed stats', () {
      final start = service.dailyGoalReached.value;
      service.applySpeakingStats(null);
      service.applySpeakingStats({'other': 1});
      service.applySpeakingStats('junk');
      expect(service.dailyGoalReached.value, start);
    });
  });
}


void goalRingTests() {
  group('daily goal ring', () {
    double targetOf(WidgetTester tester) {
      final paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(DualArcProgressRing),
          matching: find.byType(CustomPaint),
        ),
      );
      return (paint.painter as dynamic).targetFraction as double;
    }

    Widget ring(double target, {bool reduce = false}) => _app(
      DualArcProgressRing(
        targetFraction: target,
        progressFraction: 0.1,
        targetColor: Colors.blue,
        progressColor: Colors.orange,
        animationCurve: Curves.linear,
      ),
      reduceMotion: reduce,
    );

    testWidgets('fills in from empty, then sweeps to a new goal (no jump)', (tester) async {
      await tester.pumpWidget(ring(0.4));
      expect(targetOf(tester), 0);
      await tester.pumpAndSettle();
      expect(targetOf(tester), closeTo(0.4, 1e-9));

      await tester.pumpWidget(ring(0.8));
      await tester.pump(const Duration(milliseconds: 210)); // half of 420 ms
      expect(targetOf(tester), closeTo(0.6, 0.02)); // mid-sweep
      await tester.pumpAndSettle();
      expect(targetOf(tester), closeTo(0.8, 1e-9));
    });

    testWidgets('reduced motion jumps straight to the value', (tester) async {
      await tester.pumpWidget(ring(0.4, reduce: true));
      await tester.pump();
      expect(targetOf(tester), closeTo(0.4, 1e-9));
      await tester.pumpWidget(ring(0.9, reduce: true));
      await tester.pump();
      expect(targetOf(tester), closeTo(0.9, 1e-9));
    });
  });
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int _n = 0;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: () => setState(() => _n++), child: Text('$_n'));
}
