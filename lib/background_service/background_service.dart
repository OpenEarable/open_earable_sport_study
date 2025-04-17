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
  Future<void> onDestroy(DateTime timestamp) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }
}
