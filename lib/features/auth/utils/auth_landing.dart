import '../../../core/router/app_router.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/users_repository.dart';

/// Pure landing decision from a loaded profile.
///
/// Current product rules (Phase 1–2):
/// - null profile → Home (legacy / first-login race)
/// - fetch failure → Home (same as catch-all today; Phase 3 may tighten)
/// - not approved → Approval
/// - approved → Home
///
/// Do not change the null/error → Home policy without an explicit Phase 3 decision.
String resolveLandingRoute({
  UserModel? profile,
  bool profileFetchFailed = false,
}) {
  if (profileFetchFailed) return AppRoutes.home;
  if (profile == null) return AppRoutes.home;
  if (!profile.isApproved) return AppRoutes.approvalStatus;
  return AppRoutes.home;
}

/// Where to send a signed-in user after splash / login / register.
Future<String> landingRouteAfterAuth({
  UsersRepository? usersRepository,
  AuthRepository? authRepository,
}) async {
  final users = usersRepository ?? UsersRepository();
  final auth = authRepository ?? AuthRepository();
  try {
    final profile = await users.getOwnProfile();
    if (profile == null) return resolveLandingRoute(profile: null);

    if (profile.status.startsWith('email_change_approved:')) {
      final newEmail =
          profile.status.replaceFirst('email_change_approved:', '');
      try {
        await auth.updateEmail(newEmail);
        await users.processApprovedEmailChange();
      } catch (_) {}
    }

    return resolveLandingRoute(profile: profile);
  } catch (_) {
    return resolveLandingRoute(profileFetchFailed: true);
  }
}
