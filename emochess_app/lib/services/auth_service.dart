import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class AuthService {
  static const Duration _timeout = Duration(seconds: 12);

  final String? _baseUrlOverride;
  final TokenStorage _tokenStorage;
  final http.Client _client;

  Future<bool>? _refreshInFlight;

  String get _effectiveBaseUrl {
    final raw = (_baseUrlOverride ?? AppConfig.apiBaseUrl);
    return raw.replaceAll(RegExp(r'/+$'), '');
  }

  AuthService({
    String? baseUrl,
    TokenStorage? tokenStorage,
    http.Client? client,
  })  : _baseUrlOverride = (baseUrl?.trim().isEmpty ?? true) ? null : baseUrl!.trim(),
        _tokenStorage = tokenStorage ?? SecureTokenStorage(),
        _client = client ?? http.Client();

  /// 儲存 Token 和用戶資訊
  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _tokenStorage.saveTokens(
      TokenPair(accessToken: accessToken, refreshToken: refreshToken),
    );
  }

  /// 儲存用戶資訊
  Future<void> _saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  /// 取得儲存的用戶資訊
  Future<Map<String, dynamic>?> getSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return null;
    return jsonDecode(userJson) as Map<String, dynamic>;
  }

  /// 取得 Access Token
  Future<String?> getAccessToken() async {
    return _tokenStorage.readAccessToken();
  }

  /// 檢查是否已登入
  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  /// 註冊
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _client
          .post(
        Uri.parse('$_effectiveBaseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'displayName': displayName,
        }),
      )
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return AuthResult.error(key: 'authEndpointNotFoundRegister');
      }

      final data = _tryDecodeMap(response.body);

      if (response.statusCode == 201) {
        final access = (data?['accessToken'] as String?)?.trim() ?? '';
        final refresh = (data?['refreshToken'] as String?)?.trim() ?? '';
        if (access.isEmpty || refresh.isEmpty) {
          return AuthResult.error(key: 'authBadTokenResponse');
        }
        await _saveTokens(
          access,
          refresh,
        );
        final user = (data?['user'] as Map?)?.cast<String, dynamic>();
        if (user != null) {
          await _saveUser(user);
          return AuthResult.success(user);
        }
        return AuthResult.error(key: 'authBadUserResponse');
      }

      return _errorFromServer(data, fallbackKey: 'authRegisterFailed');
    } catch (e) {
      return AuthResult.error(key: 'networkError');
    }
  }

  /// 登入
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client
          .post(
        Uri.parse('$_effectiveBaseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      )
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return AuthResult.error(key: 'authEndpointNotFoundLogin');
      }

      final data = _tryDecodeMap(response.body);

      if (response.statusCode == 200) {
        final access = (data?['accessToken'] as String?)?.trim() ?? '';
        final refresh = (data?['refreshToken'] as String?)?.trim() ?? '';
        if (access.isEmpty || refresh.isEmpty) {
          return AuthResult.error(key: 'authBadTokenResponse');
        }
        await _saveTokens(
          access,
          refresh,
        );
        final user = (data?['user'] as Map?)?.cast<String, dynamic>();
        if (user != null) {
          await _saveUser(user);
          return AuthResult.success(user);
        }
        return AuthResult.error(key: 'authBadUserResponse');
      }

      return _errorFromServer(data, fallbackKey: 'authLoginFailed');
    } catch (e) {
      return AuthResult.error(key: 'networkError');
    }
  }

  /// 取得個人資料（含 XP/等級/戰績）
  Future<Map<String, dynamic>?> getProfile() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;

      final first = await _client
          .get(
            Uri.parse('$_effectiveBaseUrl/stats/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(_timeout);

      final firstData = _tryDecodeMap(first.body);
      if (first.statusCode == 200) {
        final profile = (firstData?['profile'] as Map?)?.cast<String, dynamic>();
        if (profile == null) return null;
        await _saveUser(profile);
        return profile;
      }

      if (first.statusCode != 401) return null;

      final refreshed = await refreshToken();
      if (!refreshed) return null;

      final newToken = await getAccessToken();
      if (newToken == null) return null;

      final second = await _client
          .get(
            Uri.parse('$_effectiveBaseUrl/stats/profile'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
            },
          )
          .timeout(_timeout);

      if (second.statusCode != 200) return null;
      final secondData = _tryDecodeMap(second.body);
      final profile = (secondData?['profile'] as Map?)?.cast<String, dynamic>();
      if (profile == null) return null;
      await _saveUser(profile);
      return profile;
    } catch (e) {
      return null;
    }
  }

  /// 刷新 Token
  Future<bool> refreshToken() async {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshTokenInternal();
    _refreshInFlight = future;
    future.whenComplete(() {
      if (identical(_refreshInFlight, future)) {
        _refreshInFlight = null;
      }
    });
    return future;
  }

  Future<bool> _refreshTokenInternal() async {
    try {
      final tokens = await _tokenStorage.readTokens();
      final refresh = tokens?.refreshToken;
      if (refresh == null || refresh.isEmpty) return false;

      final response = await _client
          .post(
            Uri.parse('$_effectiveBaseUrl/auth/refresh'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refresh}),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) return false;
      final data = _tryDecodeMap(response.body);
      final access = (data?['accessToken'] as String?)?.trim() ?? '';
      final newRefresh = (data?['refreshToken'] as String?)?.trim() ?? '';
      if (access.isEmpty || newRefresh.isEmpty) return false;

      await _saveTokens(access, newRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 登出
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await _tokenStorage.clear();
  }
}

Map<String, dynamic>? _tryDecodeMap(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (_) {}
  return null;
}

String? _extractErrorMessage(Map<String, dynamic>? data) {
  final error = data?['error'];
  if (error is String && error.trim().isNotEmpty) return error.trim();
  final message = data?['message'];
  if (message is String && message.trim().isNotEmpty) return message.trim();
  final details = data?['details'];
  if (details is List && details.isNotEmpty) {
    final first = details.first;
    if (first is Map) {
      final msg = first['message'];
      if (msg is String && msg.trim().isNotEmpty) return msg.trim();
    }
  }
  return null;
}

/// 認證結果
class AuthResult {
  final bool isSuccess;
  final Map<String, dynamic>? user;
  final String? errorKey;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorKey,
    this.errorMessage,
  });

  factory AuthResult.success(Map<String, dynamic> user) =>
      AuthResult._(isSuccess: true, user: user);

  factory AuthResult.error({required String key, String? message}) => AuthResult._(
        isSuccess: false,
        errorKey: key,
        errorMessage: message,
      );
}

AuthResult _errorFromServer(
  Map<String, dynamic>? data, {
  required String fallbackKey,
}) {
  final serverMessage = _extractErrorMessage(data);
  final mappedKey = _mapAuthErrorKey(serverMessage);
  return AuthResult.error(key: mappedKey ?? fallbackKey);
}

String? _mapAuthErrorKey(String? serverMessage) {
  final msg = serverMessage?.trim();
  if (msg == null || msg.isEmpty) return null;
  if (msg.contains('請求參數驗證失敗')) return 'authInvalidRequest';
  if (msg.contains('此 Email 已被註冊')) return 'authEmailExists';
  if (msg.contains('Email 或密碼不正確')) return 'authInvalidCredentials';
  return null;
}
