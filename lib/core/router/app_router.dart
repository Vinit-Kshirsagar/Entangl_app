import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/services/supabase_service.dart';
import '../../features/admin/screens/admin_requests_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/approval_status_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/feed/screens/home_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/post/screens/create_post_screen.dart';
import '../../features/post/screens/post_detail_screen.dart';
import '../../features/profile/screens/edit_profile_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/settings/screens/privacy_settings_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import 'go_router_refresh.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const forgotPassword = '/forgot-password';
  static const approvalStatus = '/approval-status';
  static const home = '/home';
  static const createPost = '/create-post';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const otherProfile = '/profile/:userId';
  static const editProfile = '/profile/edit';
  static const settings = '/settings';
  static const privacy = '/settings/privacy';
  static const adminRequests = '/admin/requests';
  static const postDetail = '/post/:postId';

  /// Build `/post/{id}` with optional comment deep-link query params.
  static String postLocation(
    String postId, {
    String? commentId,
    bool openComments = false,
  }) {
    final params = <String, String>{};
    if (commentId != null && commentId.isNotEmpty) {
      params['commentId'] = commentId;
    }
    if (openComments) params['openComments'] = '1';
    if (params.isEmpty) return '/post/$postId';
    final q = params.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return '/post/$postId?$q';
  }

  /// Pages allowed without a session.
  static bool isPublicAuthLocation(String loc) =>
      loc == login ||
      loc == register ||
      loc == splash ||
      loc == forgotPassword;

  /// Pages that require a session but are part of the auth funnel.
  static bool isAuthFunnelLocation(String loc) =>
      isPublicAuthLocation(loc) || loc == approvalStatus;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = GoRouterRefreshStream(
    ref.watch(authRepositoryProvider).authStateChanges,
  );
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final hasSession = SupabaseService.currentSession != null;
      final loc = state.matchedLocation;

      // Logged out: only public auth pages.
      if (!hasSession && !AppRoutes.isPublicAuthLocation(loc)) {
        return AppRoutes.login;
      }

      // Logged in on bare auth entry pages → leave splash/login/register
      // only when they navigate themselves after landingRouteAfterAuth.
      // Do NOT auto-bounce /login → /home (approval must be decided in UI).

      // Approval screen requires a session (handled above). Stay allowed.
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.approvalStatus,
        builder: (_, __) => const ApprovalStatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.createPost,
        builder: (_, __) => const CreatePostScreen(),
      ),
      GoRoute(
        path: AppRoutes.postDetail,
        builder: (_, state) {
          final postId = state.pathParameters['postId'] ?? '';
          final commentId = state.uri.queryParameters['commentId'];
          final openComments =
              state.uri.queryParameters['openComments'] == '1';
          return PostDetailScreen(
            postId: postId,
            commentId: commentId,
            openComments: openComments,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (_, state) => OtherProfileScreen(
          userId: state.pathParameters['userId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'privacy',
            builder: (_, __) => const PrivacySettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.adminRequests,
        builder: (_, __) => const AdminRequestsScreen(),
      ),
    ],
  );
});
