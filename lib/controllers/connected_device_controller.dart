import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'settings_controller.dart';

class ConnectedDeviceController extends ChangeNotifier {
  final SettingsController settingsController;

  List<Map<String, dynamic>> discoveredDevices = [];
  Set<Map<String, dynamic>> connectingDevices = {};
  Set<Map<String, dynamic>> connectedDevices = {};

  // For heart rate updates (for UI compatibility)
  final StreamController<int?> _heartRateStreamController = StreamController<int?>.broadcast();
  Stream<int?> get heartRateStream => _heartRateStreamController.stream;

  bool _isLocked = false;
  bool get isLocked => _isLocked;

  ConnectedDeviceController({required this.settingsController}) {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void setLock(bool value) {
    _isLocked = value;
    notifyListeners();
  }

  void _onReceiveTaskData(Object? data) {
    if (data is Map && data['type'] == 'deviceStatus') {
      final status = data['data'] as Map;
      discoveredDevices = List<Map<String, dynamic>>.from(status['discoveredDevices'] ?? []);
      connectingDevices = Set<Map<String, dynamic>>.from(status['connectingDevices'] ?? []);
      connectedDevices = Set<Map<String, dynamic>>.from(status['connectedDevices'] ?? []);
      if (status.containsKey('heartRate')) {
        _heartRateStreamController.add(status['heartRate']);
      }
      notifyListeners();
    }
  }

  void startScanning() {
    FlutterForegroundTask.sendDataToTask({'type': 'startScanning'});
  }

  void connectToDevice(Map<String, dynamic> device) {
    FlutterForegroundTask.sendDataToTask({'type': 'connectDevice', 'params': device});
  }

  // Stub for UI compatibility
  void persistConnectedDevicesForAutoConnect() {}
}
