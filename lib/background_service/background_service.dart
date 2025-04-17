import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'sub_services/recording_sub_service.dart';
import 'sub_services/connected_device_sub_service.dart';

@pragma('vm:entry-point')
void backgroundServiceCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundServiceTaskHandler());
}

class BackgroundServiceTaskHandler extends TaskHandler {
  late RecordingSubService _recordingService;
  late ConnectedDeviceSubService _deviceService;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _recordingService = RecordingSubService();
    _deviceService = ConnectedDeviceSubService();
    // Optionally, start scanning immediately
    //_deviceService.startScanning();
  }

  @override
  void onReceiveData(Object? data) {
    if (data is Map) {
      switch (data['type']) {
        case 'startRecording':
          _recordingService.start(data['params']);
          break;
        case 'stopRecording':
          _recordingService.stop();
          break;
        case 'connectDevice':
          _deviceService.connect(data['params']);
          break;
        case 'startScanning':
          _deviceService.startScanning();
          break;
        // ... more commands as needed
      }
    }
  }

  void sendUpdateToUI(String type, dynamic data) {
    FlutterForegroundTask.sendDataToMain({'type': type, 'data': data});
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Clean up any resources or subscriptions
    // (Assumes sub-services handle their own cleanup if needed)
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodically send device status to UI
    _deviceService.sendDeviceStatusUpdate();
    // RecordingSubService already sends periodic updates via timer
  }
}
