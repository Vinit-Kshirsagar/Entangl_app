import 'package:entangl_app/core/router/app_router.dart';
import 'package:entangl_app/data/models/user_model.dart';
import 'package:entangl_app/features/auth/utils/auth_landing.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user(String status) => UserModel(
      id: 'u1',
      username: 'u',
      fullName: 'U',
      createdAt: '2026-01-01T00:00:00Z',
      status: status,
    );

void main() {
  group('resolveLandingRoute', () {
    test('null profile goes home (legacy)', () {
      expect(resolveLandingRoute(profile: null), AppRoutes.home);
    });

    test('fetch failure goes home (current policy)', () {
      expect(
        resolveLandingRoute(profileFetchFailed: true),
        AppRoutes.home,
      );
    });

    test('pending stays on approval', () {
      expect(
        resolveLandingRoute(profile: _user('pending')),
        AppRoutes.approvalStatus,
      );
    });

    test('rejected stays on approval', () {
      expect(
        resolveLandingRoute(profile: _user('rejected')),
        AppRoutes.approvalStatus,
      );
    });

    test('approved goes home', () {
      expect(
        resolveLandingRoute(profile: _user('approved')),
        AppRoutes.home,
      );
    });

    test('email-change statuses that isApproved allows go home', () {
      expect(
        resolveLandingRoute(
          profile: _user('email_change_pending:new@x.com'),
        ),
        AppRoutes.home,
      );
      expect(
        resolveLandingRoute(profile: _user('approved_email_changed')),
        AppRoutes.home,
      );
    });
  });
}
