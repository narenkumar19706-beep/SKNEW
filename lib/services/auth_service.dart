import '../core/api/api_client.dart';
import '../core/constants/app_constants.dart';
import '../core/storage/secure_storage.dart';

class AuthSession {
  final String token;
  final String deviceId;
  final String expiresIn;

  const AuthSession({
    required this.token,
    required this.deviceId,
    required this.expiresIn,
  });
}

class DeviceAuthService {
  DeviceAuthService({
    ApiClient? apiClient,
    SecureStorage? storage,
  })  : _storage = storage ?? SecureStorage(),
        _apiClient = apiClient ??
            ApiClient(
              baseUrl: AppConstants.baseUrl,
              storage: storage ?? SecureStorage(),
            );

  final SecureStorage _storage;
  final ApiClient _apiClient;

  Future<AuthSession> registerDevice({
    String? name,
    String? phone,
    String? fcmToken,
  }) async {
    final response = await _apiClient.postJson(
      '/device/register',
      authenticated: false,
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (fcmToken != null) 'fcmToken': fcmToken,
      },
    );

    final token = response['token'] as String?;
    final device = response['device'] as Map<String, dynamic>?;
    final deviceId = device?['id'] as String?;
    final expiresIn = response['expiresIn']?.toString() ?? '';

    if (token == null || deviceId == null) {
      throw ApiException(
        statusCode: 500,
        message: 'Invalid registration response',
        data: response,
      );
    }

    await _storage.setToken(token);
    await _storage.setDeviceId(deviceId);

    return AuthSession(
      token: token,
      deviceId: deviceId,
      expiresIn: expiresIn,
    );
  }

  Future<Map<String, dynamic>> getProfile() async {
    final response = await _apiClient.getJson('/device/profile');
    return response['device'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? fcmToken,
  }) async {
    final response = await _apiClient.putJson(
      '/device/profile',
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (fcmToken != null) 'fcmToken': fcmToken,
      },
    );

    return response['device'] as Map<String, dynamic>? ?? {};
  }

  Future<String?> getToken() async => _storage.getToken();

  Future<String?> getDeviceId() async => _storage.getDeviceId();

  Future<void> clearSession() async => _storage.clear();
}