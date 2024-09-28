import 'dart:async';

int coinsCollected = 0; // Coins counter

Map<String,dynamic> selectedRoute = {};

String? idToken = "";


class TimerManager {
  static final TimerManager _instance = TimerManager._internal();
  factory TimerManager() => _instance;

  Timer? _timer;
  int _seconds = 0;

  TimerManager._internal();

  void startTimer() {
    if (_timer == null || !_timer!.isActive) {
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        _seconds++;
      });
    }
  }

  void stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  int get currentTime => _seconds;

  void reset() {
    _seconds = 0;
  }
}
