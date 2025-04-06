import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/task_handler.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

import '../models/auto_connect_device.dart';
import 'settings_controller.dart';

class ConnectedDeviceController extends ChangeNotifier implements TaskHandler {
  late final SettingsController _settingsController;

  // Wearable management
  final WearableManager _wearableManager = WearableManager();
  StreamSubscription? _scanSubscription;

  // Device state
  List<DiscoveredDevice> discoveredDevices = [];
  Set<DiscoveredDevice> connectingDevices = {};
  Set<Wearable> connectedDevices = {};

  final List<void Function(Wearable)> _onConnectCallbacks = [];

  // For the heart rate stream
  final Map<String, _HeartRateEntry> _heartRateMap = {};
  Timer? _heartRateResetTimer;
  final StreamController<int?> _heartRateStreamController =
      StreamController<int?>.broadcast();

  Stream<int?> get heartRateStream => _heartRateStreamController.stream;

  // Lock state for auto-reconnect functionality
  bool _isLocked = false;

  bool get isLocked => _isLocked;

  void setLock(bool value) {
    _isLocked = value;
    notifyListeners();
  }

  /// Register a callback to be called when a device connects.
  void registerOnConnectCallback(void Function(Wearable) callback) {
    _onConnectCallbacks.add(callback);
  }

  void _updateHeartRate(String wearableId, int? heartRate) {
    final now = DateTime.now();
    if (heartRate == null) {
      _heartRateMap.remove(wearableId);
    } else {
      _heartRateMap[wearableId] = _HeartRateEntry(heartRate, now);
    }

    // Remove entries older than 2 seconds
    final threshold = DateTime.now().subtract(const Duration(seconds: 2));
    _heartRateMap
        .removeWhere((id, entry) => entry.timestamp.isBefore(threshold));

    if (_heartRateMap.isEmpty) {
      _heartRateStreamController.add(null);
    } else {
      final maxEntry = _heartRateMap.entries
          .reduce((a, b) => a.value.heartRate >= b.value.heartRate ? a : b);
      _heartRateStreamController.add(maxEntry.value.heartRate);
    }

    // Reset the 3-second timer that sends null if no new heart rate is received
    _heartRateResetTimer?.cancel();
    _heartRateResetTimer = Timer(const Duration(seconds: 3), () {
      _heartRateStreamController.add(null);
    });
  }

  ConnectedDeviceController({required SettingsController settingsController}) {
    _settingsController = settingsController;

    _settingsController.addListener(_onSettingsChanged);


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

  @override
  Future<void> onDestroy(DateTime timestamp) {
    // TODO: implement onDestroy
    throw UnimplementedError();
  }

  @override
  void onNotificationButtonPressed(String id) {
    // TODO: implement onNotificationButtonPressed
  }

  @override
  void onNotificationDismissed() {
    // TODO: implement onNotificationDismissed
  }

  @override
  void onNotificationPressed() {
    // TODO: implement onNotificationPressed
  }

  @override
  void onReceiveData(Object data) {
    // TODO: implement onReceiveData
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // TODO: implement onRepeatEvent
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print("=====> onStart");

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

          // Listen for heart rate updates
          if (sensor is HeartRateSensor) {
            StreamSubscription hrs = sensor.sensorStream.listen((heartRate) {
              print("Heart rate: ${heartRate.heartRateBpm} | ${DateTime.now().toIso8601String()}");
              _updateHeartRate(wearable.deviceId, heartRate.heartRateBpm);
            });
            wearable.addDisconnectListener(() {
              hrs.cancel();
            });
          }
        }
      }

      connectingDevices.removeWhere((d) => d.id == wearable.deviceId);
      connectedDevices.add(wearable);
      notifyListeners();

      for (final callback in _onConnectCallbacks) {
        callback(wearable);
      }
    });

    // Listen for new connecting devices
    _wearableManager.connectingStream.listen((device) {
      connectingDevices.add(device);
      notifyListeners();
    });

    startScanning();
  }
}

class _HeartRateEntry {
  final int heartRate;
  final DateTime timestamp;

  _HeartRateEntry(this.heartRate, this.timestamp);
}
