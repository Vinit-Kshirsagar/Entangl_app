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
    test('auth failure forces login', () {
      expect(
        resolveLandingRoute(failure: LandingFailure.auth),
        AppRoutes.login,
      );
    });

    test('network failure keeps session path at home', () {
      expect(
        resolveLandingRoute(failure: LandingFailure.network),
        AppRoutes.home,
      );
    });

    test('missing profile goes to approval (incomplete account)', () {
      expect(
        resolveLandingRoute(failure: LandingFailure.missingProfile),
        AppRoutes.approvalStatus,
      );
      expect(
        resolveLandingRoute(profile: null),
        AppRoutes.approvalStatus,
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

  group('AppRoutes public locations', () {
    test('classifies public vs protected', () {
      expect(AppRoutes.isPublicAuthLocation(AppRoutes.login), isTrue);
      expect(AppRoutes.isPublicAuthLocation(AppRoutes.home), isFalse);
      expect(AppRoutes.isAuthFunnelLocation(AppRoutes.approvalStatus), isTrue);
    });
  });
}
