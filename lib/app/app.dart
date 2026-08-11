import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di/injector.dart';
import 'router/app_router.dart';
import 'router/auth_notifier.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

class SalesHubApp extends StatefulWidget {
  const SalesHubApp({super.key});

  @override
  State<SalesHubApp> createState() => _SalesHubAppState();
}

class _SalesHubAppState extends State<SalesHubApp> with WidgetsBindingObserver {
  final ThemeController _theme = sl<ThemeController>();

  @override
  void initState() {
    super.initState();
    // Needed for didChangePlatformBrightness: under ThemeMode.system the OS
    // flipping to dark has to rebuild us, and nothing else would.
    WidgetsBinding.instance.addObserver(this);
    _theme.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _theme.removeListener(_onThemeChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
    _rebuildEverything();
  }

  @override
  void didChangePlatformBrightness() {
    if (_theme.mode == ThemeMode.system) {
      setState(() {});
      _rebuildEverything();
    }
  }

  /// Marks every element in the tree dirty so one theme flip repaints the
  /// whole app at once.
  ///
  /// Normally a `setState` here would be enough, but `AppColors` is read
  /// statically rather than through an `InheritedWidget`, so no widget
  /// *depends* on the theme and nothing downstream gets invalidated. On top of
  /// that, `const` widgets are canonicalised — `const DashboardPage()` is
  /// literally the same instance every build, and `Element.updateChild`
  /// returns early when the new widget is identical to the old one. With ~1500
  /// const widgets in the app (including all 14 routed pages), a rebuild from
  /// the root stopped at the first one on every branch. That's why a toggle
  /// only took effect on pages you navigated to afterwards: those were built
  /// fresh, while the page you were looking at was skipped.
  ///
  /// Walking the tree and marking each element dirty bypasses that check.
  /// It's a rebuild, not a teardown — `State` objects, scroll offsets, blocs
  /// and in-progress form input all survive; only `build` re-runs.
  void _rebuildEverything() {
    void visit(Element element) {
      if (!element.mounted) return;
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    // Safe from here: this runs from a tap handler, never mid-build. The root
    // rebuilds before its descendants (dirty elements are built shallowest
    // first), so applyBrightness in build() lands before anything reads it.
    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    final platformBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final brightness = switch (_theme.mode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => platformBrightness,
    };

    // Point the token set at the brightness MaterialApp is about to render.
    // This runs synchronously, before any descendant builds, so the palette and
    // the ThemeData below can never disagree within a frame.
    AppColors.applyBrightness(brightness);

    return BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            // The user rides along so the router can gate routes on the
            // login response's permission codes.
            sl<AuthNotifier>().setAuthenticated(true, user: state.user);
          } else if (state is AuthUnauthenticated || state is AuthError) {
            sl<AuthNotifier>().setAuthenticated(false);
          }
        },
        child: MaterialApp.router(
          title: 'SalesHub — Sales Prospecting & CRM',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _theme.mode,
          // MaterialApp cross-fades ThemeData over ~200ms, but AppColors flips
          // instantly — mid-animation the two would disagree. Zero duration
          // keeps the whole UI switching on one frame instead.
          themeAnimationDuration: Duration.zero,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
