import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/supabase_service.dart';

/// Pure helpers for session validity and classifying auth-related failures.
///
/// Used by splash, landing, lifecycle refresh, and tests.
class SessionLifecycle {
  SessionLifecycle._();

  /// How soon before access-token expiry we proactively refresh.
  static const refreshSkew = Duration(minutes: 5);

  static bool get hasSession => SupabaseService.currentSession != null;

  static bool isExpiringSoon(
    Session? session, {
    DateTime? now,
    Duration skew = refreshSkew,
  }) {
    if (session == null) return false;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    final expiry =
        DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);
    final clock = now?.toUtc() ?? DateTime.now().toUtc();
    return !expiry.isAfter(clock.add(skew));
  }

  static bool isExpired(
    Session? session, {
    DateTime? now,
  }) {
    if (session == null) return true;
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    final expiry =
        DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000, isUtc: true);
    final clock = now?.toUtc() ?? DateTime.now().toUtc();
    return !expiry.isAfter(clock);
  }

  /// JWT / RLS auth failures that mean the local session is not usable.
  static bool isAuthFailure(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('jwt') ||
        msg.contains('invalid claim') ||
        msg.contains('not authenticated') ||
        msg.contains('unauthorized') ||
        msg.contains('session not found') ||
        msg.contains('refresh_token') ||
        msg.contains('invalid refresh') ||
        msg.contains('token is expired') ||
        msg.contains('pgrst301') ||
        // Common HTTP auth surfaces
        msg.contains('401') ||
        msg.contains('403');
  }

  /// PostgREST "no rows" when using `.single()` — profile row missing.
  static bool isMissingProfileError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('pgrst116') ||
        msg.contains('0 rows') ||
        msg.contains('contains 0 rows') ||
        msg.contains('multiple (or no) rows');
  }

  /// Transient transport failures — keep local session, do not force logout.
  static bool isNetworkFailure(Object error) {
    final msg = error.toString().toLowerCase();
    if (isAuthFailure(error)) return false;
    return msg.contains('socketexception') ||
        msg.contains('clientexception') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection refused') ||
        msg.contains('connection reset') ||
        msg.contains('network is unreachable') ||
        msg.contains('timed out') ||
        msg.contains('timeout') ||
        msg.contains('failed to fetch');
  }

  /// Refresh when near expiry. Returns false if no usable session remains.
  static Future<bool> ensureFreshSession() async {
    final session = SupabaseService.currentSession;
    if (session == null) return false;

    if (!isExpiringSoon(session) && !isExpired(session)) {
      return true;
    }

    try {
      final res = await SupabaseService.client.auth.refreshSession();
      return res.session != null || SupabaseService.currentSession != null;
    } catch (e) {
      if (isAuthFailure(e) || isExpired(SupabaseService.currentSession)) {
        try {
          await SupabaseService.client.auth.signOut();
        } catch (_) {}
        return false;
      }
      // Network blip: keep existing session if access token not hard-expired.
      return !isExpired(SupabaseService.currentSession);
    }
  }
}
