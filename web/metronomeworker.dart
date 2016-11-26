import "dart:async";

class MetronomeWorker {
  Timer _timer;
  int _interval = 100;

  StreamController<int> _onTickController = new StreamController<int>();
  Stream<int> get onTick => _onTickController?.stream;

  void start() {
    _timer = new Timer.periodic(
        new Duration(milliseconds: _interval), (_) => _onTickController.add(0));
  }

  void stop() {
    if (_timer != null) {
      _timer.cancel();
      _timer = null;
    }
  }

  void changeInterval(int newInterval) {
    _interval = newInterval;
    if (_timer?.isActive ?? false) {
      stop();
      start();
    }
  }
}
