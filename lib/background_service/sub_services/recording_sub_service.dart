import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class RecordingSubService {
  bool _isRecording = false;

  Timer? _timer;
  int _duration = 0;
  int? _heartRate;

  void start(dynamic params) {
    if (_isRecording) return;
    _isRecording = true;
    _startTime = DateTime.now();
    _duration = 0;
    _heartRate = 75; // Simulated initial heart rate
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _duration++;
      // Simulate heart rate update
      _heartRate = 75 + (_duration % 10);
      _sendRecordingStatus();
    });
    _sendRecordingStatus();
  }

  void stop() {
    if (!_isRecording) return;
    _isRecording = false;
    _timer?.cancel();
    _sendRecordingStatus();
  }

  void _sendRecordingStatus() {
    FlutterForegroundTask.sendDataToMain({
      'type': 'recordingStatus',
      'data': {
        'isRecording': _isRecording,
        'duration': _duration,
        'heartRate': _heartRate,
      },
    });
  }
}
