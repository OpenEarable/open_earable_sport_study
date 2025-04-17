import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../models/auto_connect_device.dart';
import 'settings_controller.dart';

class ConnectedDeviceController extends ChangeNotifier {
  final SettingsController settingsController;

  List<dynamic> discoveredDevices = [];
  Set<dynamic> connectingDevices = {};
  Set<dynamic> connectedDevices = {};

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
    // Expecting: {type: 'deviceStatus', data: {...}}
    if (data is Map && data['type'] == 'deviceStatus') {
      final status = data['data'] as Map;
      discoveredDevices = status['discoveredDevices'] ?? [];
      connectingDevices = Set.from(status['connectingDevices'] ?? []);
      connectedDevices = Set.from(status['connectedDevices'] ?? []);
      notifyListeners();
    }
  }

  Future<void> startScanning() async {
    await FlutterForegroundTask.sendDataToTask({'type': 'startScanning'});
  }

  Future<void> connectToDevice(dynamic device) async {
    await FlutterForegroundTask.sendDataToTask({
      'type': 'connectDevice',
      'params': device,
    });
  }
}

  void _onSettingsChanged() {
    _wearableManager.setAutoConnect(
      _settingsController.autoConnectDevices
              ?.map((device) => device.id)
              .toList() ??
          [],
    );
  }

  /// Persist the list of connected devices for auto-connect functionality.
  void persistConnectedDevicesForAutoConnect() {
    _settingsController.setAutoConnectDevices(
      connectedDevices
          .map(
            (device) => AutoConnectDevice(
              id: device.deviceId,
              name: device.name,
            ),
          )
          .toList(),
    );
  }

  /// Start scanning and update the list of discovered devices.
  void startScanning() {
    discoveredDevices.clear();

    _scanSubscription?.cancel();
    _wearableManager.startScan(excludeUnsupported: true);
    _scanSubscription = _wearableManager.scanStream.listen((incomingDevice) {
      if (incomingDevice.name.isNotEmpty &&
          !discoveredDevices.any((device) => device.id == incomingDevice.id)) {
        discoveredDevices.add(incomingDevice);
        notifyListeners();
      }
    });

    notifyListeners();
  }

  /// Connect to a device.
  Future<void> connectToDevice(DiscoveredDevice device) async {
    if (connectedDevices.firstWhereOrNull((d) => d.deviceId == device.id) !=
        null) {
      return;
    }

    await _wearableManager.connectToDevice(device);
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    _scanSubscription?.cancel();
    _heartRateResetTimer?.cancel();
    _heartRateStreamController.close();
    super.dispose();
  }
}

class _HeartRateEntry {
  final int heartRate;
  final DateTime timestamp;

  _HeartRateEntry(this.heartRate, this.timestamp);
}
