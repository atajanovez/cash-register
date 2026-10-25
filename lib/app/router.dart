import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/app_logo.dart';
import '../core/widgets/common.dart';
import '../features/account/account_page.dart';
import '../features/auth/application/auth_controller.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/signup_page.dart';
import '../features/members/presentation/members_page.dart';
import '../features/registers/presentation/register_detail_page.dart';
import '../features/registers/presentation/registers_screen.dart';
import 'app_shell.dart';

abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const home = registers;
  static const registers = '/registers';
  static const members = '/members';
  static const account = '/account';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Re-run redirects whenever auth state changes, without rebuilding the router.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      if (auth.isLoading && !auth.hasValue) return Routes.splash;

      final signedIn = auth.value != null;
      final onAuthPage = location == Routes.login || location == Routes.signup;

      if (!signedIn) return onAuthPage ? null : Routes.login;
      if (onAuthPage || location == Routes.splash || location == '/') {
        return Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _SplashPage()),
      GoRoute(
        path: Routes.login,
        pageBuilder: (_, state) => _fade(state, const LoginPage()),
      ),
      GoRoute(
        path: Routes.signup,
        pageBuilder: (_, state) => _fade(state, const SignupPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              // Wide screens show list and detail side by side in one widget
              // (so the list keeps its scroll and search while switching);
              // phones stack the detail page on top of the list.
              ShellRoute(
                builder: (context, state, child) => isWide(context)
                    ? RegistersScreen(selectedId: state.pathParameters['id'])
                    : child,
                routes: [
                  GoRoute(
                    path: Routes.registers,
                    builder: (_, _) => const RegistersScreen(),
                    routes: [
                      GoRoute(
                        path: ':id',
                        builder: (_, state) => RegisterDetailPage(
                          registerId: state.pathParameters['id']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.members,
                builder: (_, _) => const MembersPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.account,
                builder: (_, _) => const AccountPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

/// Login and signup share a layout, so a cross-fade reads better than a slide.
CustomTransitionPage<void> _fade(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );

class _SplashPage extends StatelessWidget {
  const _SplashPage();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: AppLogo(size: 88)));
}
