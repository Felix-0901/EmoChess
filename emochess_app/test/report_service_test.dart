import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:emochess_app/services/auth_service.dart';
import 'package:emochess_app/services/report_service.dart';
import 'package:emochess_app/storage/token_storage.dart';

class _FakeTokenStorage implements TokenStorage {
  final String? accessToken;
  final String? refreshToken;

  _FakeTokenStorage({this.accessToken, this.refreshToken});

  @override
  Future<TokenPair?> readTokens() async {
    final access = accessToken;
    final refresh = refreshToken;
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      return null;
    }
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<String?> readAccessToken() async {
    final access = accessToken;
    if (access == null || access.isEmpty) return null;
    return access;
  }

  @override
  Future<void> saveTokens(TokenPair tokens) async {}

  @override
  Future<void> clear() async {}
}

void main() {
  test('generateGameReport throws ReportServiceException when server returns error', () async {
    final tokenStorage = _FakeTokenStorage(accessToken: 'token', refreshToken: 'refresh');
    final client = MockClient((req) async {
      return http.Response(
        '{"error":"AI 報告生成失敗"}',
        502,
        headers: {'content-type': 'application/json'},
      );
    });
    final authService = AuthService(
      baseUrl: 'http://localhost:3000/api',
      tokenStorage: tokenStorage,
      client: client,
    );
    final service = ReportService(
      apiBaseUrl: 'http://localhost:3000/api',
      tokenStorage: tokenStorage,
      client: client,
      authService: authService,
    );

    await expectLater(
      () => service.generateGameReport(gameId: 'g1', language: 'zh'),
      throwsA(
        isA<ReportServiceException>().having((e) => e.message, 'message', 'AI 報告生成失敗'),
      ),
    );
  });

  test('generateGameReport returns reportJson on success', () async {
    final tokenStorage = _FakeTokenStorage(accessToken: 'token', refreshToken: 'refresh');
    final client = MockClient((req) async {
      return http.Response(
        '{"report":{"reportJson":{"analysis_report":"ok","emotion_overview":"e","recommendations":"r","disclaimer":"d"}}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final authService = AuthService(
      baseUrl: 'http://localhost:3000/api',
      tokenStorage: tokenStorage,
      client: client,
    );
    final service = ReportService(
      apiBaseUrl: 'http://localhost:3000/api',
      tokenStorage: tokenStorage,
      client: client,
      authService: authService,
    );

    final report = await service.generateGameReport(gameId: 'g1', language: 'zh');
    expect(report, isNotNull);
    expect(report!['analysis_report'], 'ok');
  });
}
