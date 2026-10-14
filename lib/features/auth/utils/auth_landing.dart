import '../../../core/router/app_router.dart';
import '../../../core/utils/session_lifecycle.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/users_repository.dart';
import '../../../data/services/supabase_service.dart';

/// Why landing could not use a normal approved profile.
enum LandingFailure {
  /// Session missing or JWT unusable — must re-authenticate.
  auth,

  /// Transport error while profile was loading — keep session.
  network,

  /// Auth uid exists but no `profiles` row (after retry).
  missingProfile,
}

/// Pure landing decision (testable, no I/O).
///
/// Phase 3 policy:
/// - [LandingFailure.auth] → Login
/// - [LandingFailure.network] → Home (do not fake-logout offline users)
/// - [LandingFailure.missingProfile] → Approval (incomplete account)
/// - profile not approved → Approval
/// - profile approved → Home
String resolveLandingRoute({
  UserModel? profile,
  LandingFailure? failure,
}) {
  switch (failure) {
    case LandingFailure.auth:
      return AppRoutes.login;
    case LandingFailure.network:
      return AppRoutes.home;
    case LandingFailure.missingProfile:
      return AppRoutes.approvalStatus;
    case null:
      break;
  }

  if (profile == null) {
    // No profile object without an explicit failure → treat as incomplete.
    return AppRoutes.approvalStatus;
  }
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

  final sessionOk = await SessionLifecycle.ensureFreshSession();
  if (!sessionOk || SupabaseService.currentSession == null) {
    return resolveLandingRoute(failure: LandingFailure.auth);
  }

  try {
    final profile = await _loadProfileWithRetry(users);

    if (profile.status.startsWith('email_change_approved:')) {
      final newEmail =
          profile.status.replaceFirst('email_change_approved:', '');
      try {
        await auth.updateEmail(newEmail);
        await users.processApprovedEmailChange();
      } catch (_) {}
    }

    return resolveLandingRoute(profile: profile);
  } catch (e) {
    if (SessionLifecycle.isAuthFailure(e)) {
      try {
        await auth.signOut();
      } catch (_) {}
      return resolveLandingRoute(failure: LandingFailure.auth);
    }
    if (SessionLifecycle.isMissingProfileError(e)) {
      return resolveLandingRoute(failure: LandingFailure.missingProfile);
    }
    if (SessionLifecycle.isNetworkFailure(e)) {
      return resolveLandingRoute(failure: LandingFailure.network);
    }
    // Unknown: prefer home over bounce-loop while session still exists.
    return resolveLandingRoute(failure: LandingFailure.network);
  }
}

Future<UserModel> _loadProfileWithRetry(UsersRepository users) async {
  try {
    final profile = await users.getOwnProfile();
    if (profile != null) return profile;
    // uid null mid-flight
    throw StateError('No profile for current user');
  } catch (e) {
    if (!SessionLifecycle.isMissingProfileError(e) &&
        e is! StateError) {
      rethrow;
    }
    // Profile trigger race after first OAuth/sign-up.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final retry = await users.getOwnProfile();
    if (retry != null) return retry;
    throw Exception('PGRST116 no profile row');
  }
}
