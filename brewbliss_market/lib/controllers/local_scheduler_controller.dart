import 'dart:async';

typedef LocalTaskCallback = void Function();

class LocalSchedulerController {
  LocalSchedulerController._();

  static Future<LocalSchedulerController> init() async {
    return LocalSchedulerController._();
  }

  final Map<String, _ScheduledTask> _tasks = <String, _ScheduledTask>{};
  bool _paused = false;

  void registerTask({
    required String id,
    required Duration interval,
    required LocalTaskCallback callback,
  }) {
    cancelTask(id);
    final timer = Timer.periodic(interval, (_) {
      if (_paused) return;
      callback();
    });
    _tasks[id] = _ScheduledTask(timer: timer, interval: interval, callback: callback);
  }

  void cancelTask(String id) {
    final task = _tasks.remove(id);
    task?.timer.cancel();
  }

  void pause() {
    if (_paused) return;
    _paused = true;
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
  }

  void reschedule(String id, Duration interval) {
    final task = _tasks[id];
    if (task == null) {
      return;
    }
    registerTask(id: id, interval: interval, callback: task.callback);
  }

  void dispose() {
    for (final task in _tasks.values) {
      task.timer.cancel();
    }
    _tasks.clear();
  }
}

class _ScheduledTask {
  _ScheduledTask({
    required this.timer,
    required this.interval,
    required this.callback,
  });

  final Timer timer;
  final Duration interval;
  final LocalTaskCallback callback;
}
