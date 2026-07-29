import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'di/injector.dart';
import 'router/app_router.dart';
import 'router/auth_notifier.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/presentation/bloc/auth_bloc.dart';

class SalesHubApp extends StatelessWidget {
  const SalesHubApp({super.key});

  @override
  Widget build(BuildContext context) {
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
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
