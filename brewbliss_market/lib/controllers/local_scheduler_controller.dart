import 'dart:async';

import 'package:flutter/foundation.dart';

class ScheduledTask {
  ScheduledTask({
    required this.id,
    required this.label,
    required this.target,
    required this.onComplete,
  });

  final String id;
  final String label;
  final DateTime target;
  final VoidCallback onComplete;
}

class LocalSchedulerController extends ChangeNotifier {
  LocalSchedulerController() {
    _countdownsNotifier = ValueNotifier<Map<String, Duration>>({});
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  late final ValueNotifier<Map<String, Duration>> _countdownsNotifier;
  final Map<String, ScheduledTask> _tasks = {};
  Timer? _timer;
  bool _paused = false;

  ValueListenable<Map<String, Duration>> get countdownsListenable => _countdownsNotifier;
  bool get paused => _paused;

  void schedule(String id, String label, Duration duration, VoidCallback onComplete) {
    final task = ScheduledTask(
      id: id,
      label: label,
      target: DateTime.now().add(duration),
      onComplete: onComplete,
    );
    _tasks[id] = task;
    _updateCountdown(id);
  }

  void cancel(String id) {
    _tasks.remove(id);
    final map = {..._countdownsNotifier.value}..remove(id);
    _countdownsNotifier.value = map;
  }

  void pause() {
    _paused = true;
  }

  void resume() {
    _paused = false;
  }

  void _tick() {
    if (_paused) return;
    final now = DateTime.now();
    final map = <String, Duration>{};
    final completed = <String>[];
    for (final entry in _tasks.entries) {
      final remaining = entry.value.target.difference(now);
      if (remaining.isNegative) {
        completed.add(entry.key);
        continue;
      }
      map[entry.key] = remaining;
    }
    _countdownsNotifier.value = map;
    for (final id in completed) {
      final task = _tasks.remove(id);
      task?.onComplete();
    }
  }

  void _updateCountdown(String id) {
    final task = _tasks[id];
    if (task == null) return;
    final remaining = task.target.difference(DateTime.now());
    final map = {..._countdownsNotifier.value}..[id] = remaining;
    _countdownsNotifier.value = map;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _countdownsNotifier.dispose();
    super.dispose();
  }
}
