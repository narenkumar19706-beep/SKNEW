import '../core/api/api_client.dart';
import '../core/constants/app_constants.dart';
import 'location_queue_service.dart';

class LocationSyncService {
  LocationSyncService({
    ApiClient? apiClient,
    LocationQueueService? queueService,
  })  : _queueService = queueService ?? LocationQueueService(),
        _apiClient = apiClient ??
            ApiClient(
              baseUrl: AppConstants.baseUrl,
            );

  final LocationQueueService _queueService;
  final ApiClient _apiClient;

  Future<void> sendLocation({
    String? sosId,
    required double latitude,
    required double longitude,
    double? accuracy,
    DateTime? capturedAt,
  }) async {
    try {
      await _apiClient.postJson(
        '/location/update',
        body: {
          if (sosId != null) 'sosId': sosId,
          'latitude': latitude,
          'longitude': longitude,
          if (accuracy != null) 'accuracy': accuracy,
          if (capturedAt != null) 'capturedAt': capturedAt.toIso8601String(),
        },
      );
    } catch (error) {
      await _queueService.enqueue(
        LocationQueueItem(
          sosId: sosId,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          capturedAt: capturedAt ?? DateTime.now(),
        ),
      );
    }
  }

  Future<int> flushQueue({int batchSize = 25}) async {
    final items = await _queueService.fetchBatch(limit: batchSize);
    if (items.isEmpty) {
      return 0;
    }

    final sentIds = <int>[];
    for (final item in items) {
      try {
        await _apiClient.postJson(
          '/location/update',
          body: {
            if (item.sosId != null) 'sosId': item.sosId,
            'latitude': item.latitude,
            'longitude': item.longitude,
            if (item.accuracy != null) 'accuracy': item.accuracy,
            'capturedAt': item.capturedAt.toIso8601String(),
          },
        );
        if (item.id != null) {
          sentIds.add(item.id!);
        }
      } catch (error) {
        break;
      }
    }

    await _queueService.deleteBatch(sentIds);
    return sentIds.length;
  }
}
