import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_task_board/features/auth/presentation/auth_providers.dart';
import 'package:flutter_task_board/features/auth/presentation/login_screen.dart';
import 'package:flutter_task_board/features/auth/presentation/signup_screen.dart';
import 'package:flutter_task_board/features/board/presentation/board_list_screen.dart';
import 'package:flutter_task_board/features/task/presentation/task_board_screen.dart';
import 'package:flutter_task_board/features/settings/presentation/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/signup';

      // Still checking auth → do nothing
      if (authState.isLoading) return null;

      // Not logged in → force login
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      // Logged in → never allow auth screens
      if (isLoggedIn && isAuthRoute) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const BoardListScreen(),
        routes: [
          GoRoute(
            path: 'board/:boardId',
            builder: (context, state) {
              final boardId = state.pathParameters['boardId']!;
              final title = state.uri.queryParameters['title'] ?? 'Board';
              return TaskBoardScreen(boardId: boardId, boardTitle: title);
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
    ],
  );
});
