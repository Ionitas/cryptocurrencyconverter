import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../analytics/logging_system.dart';

/// Priority levels for background tasks
enum TaskPriority {
  high, // Execute immediately
  normal, // Execute in order
  low, // Execute when idle
}

/// Background task definition
class BackgroundTask {
  final String id;
  final String name;
  final TaskPriority priority;
  final Future<void> Function() execute;
  final DateTime createdAt;

  BackgroundTask({
    required this.id,
    required this.name,
    required this.priority,
    required this.execute,
  }) : createdAt = DateTime.now();
}

/// Background Task Manager
/// Manages and schedules background tasks with priority queuing
class BackgroundTaskManager {
  static BackgroundTaskManager? _instance;
  static BackgroundTaskManager get instance {
    _instance ??= BackgroundTaskManager._();
    return _instance!;
  }

  BackgroundTaskManager._();

  // Priority queues
  final Queue<BackgroundTask> _highPriorityQueue = Queue();
  final Queue<BackgroundTask> _normalPriorityQueue = Queue();
  final Queue<BackgroundTask> _lowPriorityQueue = Queue();

  // Currently running tasks
  final Set<String> _runningTasks = {};

  // Configuration
  static const int _maxConcurrentTasks = 3;
  static const Duration _taskTimeout = Duration(seconds: 30);
  static const Duration _lowPriorityDelay = Duration(milliseconds: 500);

  Timer? _processingTimer;
  bool _isProcessing = false;

  /// Add a task to the queue
  void enqueue(BackgroundTask task) {
    // Skip if task with same ID is already queued or running
    if (_runningTasks.contains(task.id) || _isTaskQueued(task.id)) {
      AppLogger.d('BackgroundTasks',
          'Task ${task.id} already queued/running, skipping');
      return;
    }

    switch (task.priority) {
      case TaskPriority.high:
        _highPriorityQueue.add(task);
        break;
      case TaskPriority.normal:
        _normalPriorityQueue.add(task);
        break;
      case TaskPriority.low:
        _lowPriorityQueue.add(task);
        break;
    }

    AppLogger.d(
        'BackgroundTasks', 'Enqueued: ${task.name} (${task.priority.name})');
    _startProcessing();
  }

  /// Add a simple task
  void addTask({
    required String id,
    required String name,
    TaskPriority priority = TaskPriority.normal,
    required Future<void> Function() execute,
  }) {
    enqueue(BackgroundTask(
      id: id,
      name: name,
      priority: priority,
      execute: execute,
    ));
  }

  bool _isTaskQueued(String id) {
    return _highPriorityQueue.any((t) => t.id == id) ||
        _normalPriorityQueue.any((t) => t.id == id) ||
        _lowPriorityQueue.any((t) => t.id == id);
  }

  void _startProcessing() {
    if (_isProcessing) return;
    _isProcessing = true;
    _processNextTask();
  }

  void _processNextTask() {
    // Check if we can run more tasks
    if (_runningTasks.length >= _maxConcurrentTasks) {
      return;
    }

    // Get next task by priority
    BackgroundTask? task;

    if (_highPriorityQueue.isNotEmpty) {
      task = _highPriorityQueue.removeFirst();
    } else if (_normalPriorityQueue.isNotEmpty) {
      task = _normalPriorityQueue.removeFirst();
    } else if (_lowPriorityQueue.isNotEmpty) {
      // Delay low priority tasks
      Future.delayed(_lowPriorityDelay, () {
        if (_lowPriorityQueue.isNotEmpty &&
            _runningTasks.length < _maxConcurrentTasks) {
          final lowTask = _lowPriorityQueue.removeFirst();
          _executeTask(lowTask);
        }
      });
      return;
    }

    if (task == null) {
      _isProcessing = false;
      return;
    }

    _executeTask(task);
  }

  Future<void> _executeTask(BackgroundTask task) async {
    _runningTasks.add(task.id);
    final timer = Stopwatch()..start();

    try {
      await task.execute().timeout(_taskTimeout);
      timer.stop();
      AppLogger.d('BackgroundTasks',
          '✓ ${task.name} completed in ${timer.elapsedMilliseconds}ms');
    } on TimeoutException {
      timer.stop();
      AppLogger.w('BackgroundTasks',
          '⚠ ${task.name} timed out after ${_taskTimeout.inSeconds}s');
    } catch (e) {
      timer.stop();
      AppLogger.e('BackgroundTasks',
          '✗ ${task.name} failed after ${timer.elapsedMilliseconds}ms',
          error: e);
    } finally {
      _runningTasks.remove(task.id);
      _processNextTask();
    }
  }

  /// Execute heavy computation in isolate
  static Future<T> computeInIsolate<T>(
    T Function(dynamic) computation,
    dynamic message,
  ) async {
    return await compute(computation, message);
  }

  /// Get queue status
  Map<String, int> get queueStatus => {
        'high': _highPriorityQueue.length,
        'normal': _normalPriorityQueue.length,
        'low': _lowPriorityQueue.length,
        'running': _runningTasks.length,
      };

  /// Cancel all pending tasks
  void cancelAll() {
    _highPriorityQueue.clear();
    _normalPriorityQueue.clear();
    _lowPriorityQueue.clear();
    _processingTimer?.cancel();
    _isProcessing = false;
    AppLogger.i('BackgroundTasks', 'All pending tasks cancelled');
  }

  /// Dispose resources
  void dispose() {
    cancelAll();
    _processingTimer?.cancel();
  }
}
