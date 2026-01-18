class ForegroundService {
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> start() async {
    _isRunning = true;
  }

  Future<void> stop() async {
    _isRunning = false;
  }
}
