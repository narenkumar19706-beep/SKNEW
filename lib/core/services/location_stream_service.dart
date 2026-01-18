import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../services/location_sync_service.dart';

class LocationStreamService {
  LocationStreamService({LocationSyncService? locationSyncService})
      : _locationSyncService = locationSyncService ?? LocationSyncService();

  final LocationSyncService _locationSyncService;
  StreamSubscription<Position>? _subscription;
  DateTime? _lastSentAt;

  Future<void> start({String? sosId}) async {
    await _subscription?.cancel();
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    ).listen((position) async {
      final now = DateTime.now();
      if (_lastSentAt == null || now.difference(_lastSentAt!).inSeconds >= 5) {
        _lastSentAt = now;
        await _locationSyncService.sendLocation(
          sosId: sosId,
          latitude: position.latitude,
          longitude: position.longitude,
          accuracy: position.accuracy,
          capturedAt: now,
        );
      }
    });
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
