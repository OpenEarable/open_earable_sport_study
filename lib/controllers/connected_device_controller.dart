import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';

import '../models/auto_connect_device.dart';
import '../services/background_service.dart';
import 'settings_controller.dart';

class ConnectedDeviceController extends ChangeNotifier {
  late final SettingsController _settingsController;
  final BackgroundServiceManager _backgroundService = BackgroundServiceManager.instance;

  // Device state
  List<Map<String, dynamic>> _discoveredDevices = [];
  Set<String> _connectingDeviceIds = {};
  Set<Map<String, dynamic>> _connectedDevices = {};

  // Stream subscriptions
  StreamSubscription? _devicesSubscription;
  StreamSubscription? _heartRateSubscription;

  // For the heart rate stream
  final StreamController<int?> _heartRateStreamController =
      StreamController<int?>.broadcast();

  // Getters for UI
  List<Map<String, dynamic>> get discoveredDevices => _discoveredDevices;
  Set<Map<String, dynamic>> get connectedDevices => _connectedDevices;
  bool get hasConnectingDevices => _connectingDeviceIds.isNotEmpty;
  Stream<int?> get heartRateStream => _heartRateStreamController.stream;

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
    
    _initBackgroundService();
  }
  
  Future<void> _initBackgroundService() async {
    // Initialize and request permissions for the background service
    await _backgroundService.initialize();
    await _backgroundService.requestPermissions();
    
    // Subscribe to device state changes from the background service
    _devicesSubscription = _backgroundService.connectedDevicesStream.listen(_handleDevicesUpdate);
    
    // Subscribe to heart rate updates from the background service
    _heartRateSubscription = _backgroundService.heartRateStream.listen((heartRate) {
      _heartRateStreamController.add(heartRate);
    });
    
    // Start the background service if not already running
    if (await _backgroundService.isServiceRunning() == false) {
      await _backgroundService.startService();
    }
    
    // Initialize scanning
    startScanning();
  }
  
  void _handleDevicesUpdate(List<Map<String, dynamic>> devices) {
    _connectedDevices.clear();
    _connectedDevices.addAll(devices.toSet());
    
    // Update connecting devices set
    _connectingDeviceIds.removeWhere((id) => 
      _connectedDevices.any((device) => device['id'] == id));
    
    notifyListeners();
    
    // Auto-connect functionality
    if (_settingsController.autoConnectDevices != null && !_isLocked) {
      persistConnectedDevicesForAutoConnect();
    }
  }

  void _onSettingsChanged() {
    // Send auto-connect devices to background service
    if (_settingsController.autoConnectDevices != null) {
      final deviceIds = _settingsController.autoConnectDevices
          ?.map((device) => device.id)
          .toList() ?? [];
          
      // This will be handled by the background service
      _backgroundService.sendCommand('setAutoConnectDevices', {
        'deviceIds': deviceIds,
      });
    }
  }

  /// Persist the list of connected devices for auto-connect functionality.
  void persistConnectedDevicesForAutoConnect() {
    _settingsController.setAutoConnectDevices(
      _connectedDevices
          .map(
            (device) => AutoConnectDevice(
              id: device['id'] as String,
              name: device['name'] as String,
            ),
          )
          .toList(),
    );
  }

  /// Start scanning and update the list of discovered devices.
  void startScanning() {
    _discoveredDevices.clear();
    _backgroundService.startScanning();
    notifyListeners();
  }

  /// Connect to a device.
  Future<void> connectToDevice(Map<String, dynamic> device) async {
    if (_connectedDevices.any((d) => d['id'] == device['id'])) {
      return;
    }
    
    // Add to connecting devices set
    _connectingDeviceIds.add(device['id'] as String);
    notifyListeners();
    
    // Send command to background service
    _backgroundService.connectToDevice(
      device['id'] as String,
      device['name'] as String,
    );
  }

  @override
  void dispose() {
    _settingsController.removeListener(_onSettingsChanged);
    _devicesSubscription?.cancel();
    _heartRateSubscription?.cancel();
    _heartRateStreamController.close();
    super.dispose();
  }
}


