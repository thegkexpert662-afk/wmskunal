import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  AuthSession({required this.accessToken, required this.user, required this.deviceStatus, required this.deviceEnrollmentRequired});
  final String accessToken;
  final Map<String, dynamic> user;
  final String deviceStatus;
  final bool deviceEnrollmentRequired;
  String get role => (user['role'] ?? '').toString();
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  static const String _apiBaseUrl = String.fromEnvironment('WMS_API_BASE_URL', defaultValue: 'http://localhost:4000/api');
  static const String _deviceCredentialKey = 'wms_device_credential_id';
  AuthSession? _session;
  AuthSession? get session => _session;

  Future<String?> _storedDeviceCredential() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceCredentialKey);
  }

  Future<String> _getOrCreateDeviceCredential() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceCredentialKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final suffix = List<int>.generate(24, (_) => random.nextInt(256)).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final credential = 'browser-$suffix';
    await prefs.setString(_deviceCredentialKey, credential);
    return credential;
  }

  Future<AuthSession> login({required String username, required String password}) async {
    final credentialId = await _storedDeviceCredential();
    final response = await _postLogin(username: username, password: password, deviceCredentialId: credentialId);
    if (response.statusCode == 200) return _saveSession(response);
    final body = _decodeBody(response);
    if (body['error']?['code']?.toString() == 'DEVICE_ENROLLMENT_REQUIRED') {
      await _registerWithEnrollmentToken(body['enrollmentToken']?.toString());
      throw AuthException('DEVICE_PENDING', 'This browser has been registered and is waiting for Master Admin approval. After approval, login again.');
    }
    throw _exceptionFromResponse(response);
  }

  Future<void> _registerWithEnrollmentToken(String? enrollmentToken) async {
    if (enrollmentToken == null || enrollmentToken.isEmpty) throw AuthException('INVALID_ENROLLMENT_TOKEN', 'Device enrollment could not be started.');
    final credentialId = await _getOrCreateDeviceCredential();
    final response = await http.post(
      Uri.parse('$_apiBaseUrl/devices/register'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $enrollmentToken'},
      body: jsonEncode({'deviceName': 'WMS Web Browser', 'deviceType': 'Flutter Web Browser', 'credentialId': credentialId}),
    );
    if (response.statusCode == 201 || response.statusCode == 409) return;
    throw _exceptionFromResponse(response);
  }
  Future<void> enrollCurrentBrowser({required String username, required String password}) async {
    final response = await _postLogin(username: username, password: password);
    if (response.statusCode != 200) throw _exceptionFromResponse(response);
    final body = _decodeBody(response);
    final token = body['accessToken']?.toString();
    if (token == null || token.isEmpty) throw AuthException('INVALID_RESPONSE', 'Login response is missing an access token.');
    final credentialId = await _getOrCreateDeviceCredential();
    final registerResponse = await http.post(
      Uri.parse('$_apiBaseUrl/devices/register'),
      headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer $token'},
      body: jsonEncode({'deviceName': 'WMS Web Browser', 'deviceType': 'Flutter Web Browser', 'credentialId': credentialId}),
    );
    if (registerResponse.statusCode == 201) throw AuthException('DEVICE_PENDING', 'This browser has been registered and is waiting for Master Admin approval.');
    final registerBody = _decodeBody(registerResponse);
    if (registerBody['error']?['code']?.toString() == 'DEVICE_ALREADY_REGISTERED') throw AuthException('DEVICE_PENDING', 'This browser is already registered. Please wait for Master Admin approval.');
    throw _exceptionFromResponse(registerResponse);
  }

  Future<http.Response> _postLogin({required String username, required String password, String? deviceCredentialId}) {
    return http.post(Uri.parse('$_apiBaseUrl/auth/login'), headers: const {'Content-Type': 'application/json'}, body: jsonEncode({'username': username, 'password': password, if (deviceCredentialId != null) 'deviceCredentialId': deviceCredentialId}));
  }

  AuthSession _saveSession(http.Response response) {
    final body = _decodeBody(response);
    final session = AuthSession(accessToken: body['accessToken'].toString(), user: Map<String, dynamic>.from(body['user'] as Map), deviceStatus: body['deviceStatus']?.toString() ?? 'unknown', deviceEnrollmentRequired: body['deviceEnrollmentRequired'] == true);
    _session = session;
    return session;
  }

  Future<List<Map<String, dynamic>>> getDevices() async {
    final token = _session?.accessToken;
    if (token == null || token.isEmpty) {
      throw AuthException('SESSION_REQUIRED', 'Please login again.');
    }
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/devices'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) throw _exceptionFromResponse(response);
    final body = _decodeBody(response);
    final data = body['devices'];
    if (data is! List) return <Map<String, dynamic>>[];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> updateDeviceStatus({
    required String deviceId,
    required String status,
  }) async {
    final token = _session?.accessToken;
    if (token == null || token.isEmpty) {
      throw AuthException('SESSION_REQUIRED', 'Please login again.');
    }
    final response = await http.patch(
      Uri.parse('$_apiBaseUrl/devices/$deviceId/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    if (response.statusCode != 200) throw _exceptionFromResponse(response);
    final body = _decodeBody(response);
    return Map<String, dynamic>.from(body['device'] as Map);
  }

  Future<void> logout() async { _session = null; }

  Map<String, dynamic> _decodeBody(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
    } catch (_) { return <String, dynamic>{}; }
  }

  AuthException _exceptionFromResponse(http.Response response) {
    final body = _decodeBody(response);
    final error = body['error'];
    if (error is Map) return AuthException(error['code']?.toString() ?? 'LOGIN_FAILED', error['message']?.toString() ?? 'Login failed.');
    return AuthException('LOGIN_FAILED', 'Unable to connect to the WMS server. Please try again.');
  }
}

class AuthException implements Exception {
  AuthException(this.code, this.message);
  final String code;
  final String message;
  @override String toString() => message;
}