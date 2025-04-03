import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

import '../models/auto_connect_device.dart';
import 'settings_controller.dart';

class ConnectedDeviceController extends ChangeNotifier {
  final WearableManager _wearableManager = WearableManager();
  StreamSubscription? _scanSubscription;

  // Device state
  List<DiscoveredDevice> discoveredDevices = [];
  Set<DiscoveredDevice> connectingDevices = {};
  Set<Wearable> connectedDevices = {};

  late final SettingsController _settingsController;

  // Lock state for auto-reconnect functionality
  bool _isLocked = false;

  bool get isLocked => _isLocked;

  void setLock(bool value) {
    _isLocked = value;
    notifyListeners();
  }

  ConnectedDeviceController({required SettingsController settingsController}) {
    _settingsController = settingsController;

    _settingsController.addListener(_onSettingsChanged);

    // Listen for new connected devices
    _wearableManager.connectStream.listen((wearable) {
      wearable.addDisconnectListener(() {
        if (connectedDevices
            .any((device) => device.deviceId == wearable.deviceId)) {
          connectedDevices
              .removeWhere((device) => device.deviceId == wearable.deviceId);
          notifyListeners();
        }
      });

      // Enable every sensor
      if (wearable is SensorManager) {
        for (Sensor sensor in (wearable as SensorManager).sensors) {
          for (SensorConfiguration config in sensor.relatedConfigurations) {
            if (config is SensorFrequencyConfiguration) {
              config.setMaximumFrequency();
            }
          }
        }
      }

      connectingDevices.removeWhere((d) => d.id == wearable.deviceId);
      connectedDevices.add(wearable);
      notifyListeners();
    });

    // Listen for new connecting devices
    _wearableManager.connectingStream.listen((device) {
      connectingDevices.add(device);
      notifyListeners();
    });

    startScanning();
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
    super.dispose();
  }
}
