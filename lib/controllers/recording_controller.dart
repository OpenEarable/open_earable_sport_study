import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'connected_device_controller.dart';
import 'settings_controller.dart';

class RecordingController extends ChangeNotifier {
  final ConnectedDeviceController deviceController;
  final SettingsController settingsController;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  bool get isRecording => _isRecording;

  Duration get recordingDuration => _recordingDuration;

  LastRecording? _lastRecording;

  LastRecording? get lastRecording => _lastRecording;

  RecordingController({
    required this.deviceController,
    required this.settingsController,
  }) {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object? data) {
    // Expecting: {type: 'recordingStatus', data: {...}}
    if (data is Map && data['type'] == 'recordingStatus') {
      final status = data['data'] as Map;
      _isRecording = status['isRecording'] ?? false;
      _recordingDuration = Duration(seconds: status['duration'] ?? 0);
      if (status['lastRecording'] != null) {
        final lr = status['lastRecording'] as Map;
        _lastRecording = LastRecording(
          participantId: lr['participantId'] ?? '',
          duration: Duration(seconds: lr['duration'] ?? 0),
          startHeartRate: lr['startHeartRate'],
          exerciseHeartRate: lr['exerciseHeartRate'],
        );
      }
      notifyListeners();
    }
  }

  // All sensor and recording logic has been moved to the background service.

  Future<void> start() async {
    // Send command to background service
    FlutterForegroundTask.sendDataToTask({
      'type': 'startRecording',
      'params': {
        // Add any parameters needed, e.g. participantId
        'participantId': settingsController.participantId,
      }
    });
  }

  Future<void> stop() async {
    FlutterForegroundTask.sendDataToTask({'type': 'stopRecording'});
  }
}

class LastRecording {
  final String participantId;
  final Duration duration;
  final int? startHeartRate;
  final int? exerciseHeartRate;

  LastRecording({
    required this.participantId,
    required this.duration,
    this.startHeartRate,
    this.exerciseHeartRate,
  });
}
