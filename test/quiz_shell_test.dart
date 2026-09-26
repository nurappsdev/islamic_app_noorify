import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:islami_app_noorify/features/quiz/presentation/screens/quiz_shell.dart';
import 'package:islami_app_noorify/features/quiz/presentation/widgets/quiz_bottom_nav.dart';
import 'package:islami_app_noorify/shared/bloc/language/language_bloc.dart';

/// A tab with a counter, to show a tab keeps its state while hidden.
class _CounterTab extends StatefulWidget {
  const _CounterTab(this.name);

  final String name;

  @override
  State<_CounterTab> createState() => _CounterTabState();
}

class _CounterTabState extends State<_CounterTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () => setState(() => _count++),
      child: Text('${widget.name} $_count'),
    ),
  );
}

void main() {
  var built = <String>[];

  Future<void> pumpShell(WidgetTester tester, {int initialTab = 0}) async {
    built = [];
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    WidgetBuilder tab(String name) => (_) {
      built.add(name);
      return _CounterTab(name);
    };
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => BlocProvider(
          create: (_) => LanguageBloc(),
          child: MaterialApp(
            home: Scaffold(
              body: QuizShell(
                initialTab: initialTab,
                tabs: [
                  tab('home'),
                  tab('learn'),
                  tab('planner'),
                  tab('dashboard'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('switching tabs keeps the same bar and no route transition', (
    tester,
  ) async {
    await pumpShell(tester);
    final bar = tester.element(find.byType(QuizBottomNav));

    await tester.tap(find.byTooltip('Learn'));
    await tester.pump();

    expect(find.text('learn 0'), findsOneWidget);
    expect(find.text('home 0'), findsNothing);
    // The very same bar element: it was not rebuilt from scratch.
    expect(tester.element(find.byType(QuizBottomNav)), same(bar));
    // Nothing was pushed, so there is no page transition to animate.
    expect(tester.hasRunningAnimations, isFalse);
  });

  testWidgets('a tab keeps its state and is built only once', (tester) async {
    await pumpShell(tester);
    await tester.tap(find.text('home 0'));
    await tester.pump();
    expect(find.text('home 1'), findsOneWidget);

    await tester.tap(find.byTooltip('Dashboard'));
    await tester.pump();
    await tester.tap(find.byTooltip('Home'));
    await tester.pump();

    expect(find.text('home 1'), findsOneWidget);
    expect(built, ['home', 'dashboard']);
  });

  testWidgets('opens on the requested tab, building only that one', (
    tester,
  ) async {
    await pumpShell(tester, initialTab: 2);
    expect(find.text('planner 0'), findsOneWidget);
    expect(built, ['planner']);
  });
}
