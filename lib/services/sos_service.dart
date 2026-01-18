import '../core/api/api_client.dart';
import '../core/constants/app_constants.dart';
import '../models/sos_alert.dart';
import 'location_sync_service.dart';

/// Abstract SOS service interface for handling alert operations
abstract class SOSService {
  /// Send SOS alert to backend
  Future<bool> sendSOSAlert(SOSAlert alert);

  /// Update existing SOS alert (for modifications)
  Future<bool> updateSOSAlert(String alertId, String? newMessage);

  /// Stop/cancel active SOS alert
  Future<bool> stopSOSAlert(String alertId);

  /// Get status of sent alert
  Future<Map<String, dynamic>?> getAlertStatus(String alertId);
}

/// HTTP-based implementation for communicating with backend
class HTTPSOSService implements SOSService {
  HTTPSOSService({
    ApiClient? apiClient,
    LocationSyncService? locationSyncService,
  })  : _apiClient = apiClient ?? ApiClient(baseUrl: AppConstants.baseUrl),
        _locationSyncService = locationSyncService ?? LocationSyncService();

  final ApiClient _apiClient;
  final LocationSyncService _locationSyncService;
  String? activeSosId;

  @override
  Future<bool> sendSOSAlert(SOSAlert alert) async {
    if (alert.latitude == null || alert.longitude == null) {
      return false;
    }

    try {
      final response = await _apiClient.postJson(
        '/sos/trigger',
        body: {
          'latitude': alert.latitude,
          'longitude': alert.longitude,
          if (alert.message != null) 'message': alert.message,
          'capturedAt': alert.timestamp.toIso8601String(),
        },
      );
      final sos = response['sos'] as Map<String, dynamic>?;
      activeSosId = sos?['id'] as String?;
      return true;
    } catch (error) {
      return false;
    }
  }

  @override
  Future<bool> updateSOSAlert(String alertId, String? newMessage) async {
    if (newMessage == null || newMessage.isEmpty) {
      return false;
    }

    try {
      await _apiClient.postJson(
        '/sos/update',
        body: {
          'sosId': alertId,
          'message': newMessage,
        },
      );
      return true;
    } catch (error) {
      return false;
    }
  }

  @override
  Future<bool> stopSOSAlert(String alertId) async {
    try {
      await _apiClient.postJson(
        '/sos/resolve',
        body: {
          'sosId': alertId,
        },
      );
      if (activeSosId == alertId) {
        activeSosId = null;
      }
      return true;
    } catch (error) {
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> getAlertStatus(String alertId) async {
    try {
      return await _apiClient.getJson('/location/live/$alertId');
    } catch (error) {
      return null;
    }
  }

  Future<void> sendLocationUpdate({
    String? sosId,
    required double latitude,
    required double longitude,
    double? accuracy,
    DateTime? capturedAt,
  }) async {
    await _locationSyncService.sendLocation(
      sosId: sosId ?? activeSosId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      capturedAt: capturedAt,
    );
  }

  Future<int> flushQueuedLocations({int batchSize = 25}) async {
    return _locationSyncService.flushQueue(batchSize: batchSize);
  }
}