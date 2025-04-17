import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:open_earable_sport_study/services/sub_services/connected_devices_service.dart';
import 'package:open_earable_sport_study/services/sub_services/recording_service.dart';
import 'package:open_earable_sport_study/services/sub_services/settings_service.dart';

// The callback function should always be a top-level function
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(OpenEarableBackgroundTaskHandler());
}

/// Main handler for the background service
class OpenEarableBackgroundTaskHandler extends TaskHandler {
  static const String cmdStartRecording = 'startRecording';
  static const String cmdStopRecording = 'stopRecording';
  static const String cmdScanDevices = 'scanDevices';
  static const String cmdConnectDevice = 'connectDevice';
  static const String cmdSetParticipantId = 'setParticipantId';
  
  // Sub-services
  late ConnectedDevicesService _connectedDevicesService;
  late RecordingService _recordingService;
  late SettingsService _settingsService;
  
  // Stream controllers to handle events from sub-services
  final _heartRateStreamController = StreamController<int?>.broadcast();
  final _connectedDevicesStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _recordingStateStreamController = StreamController<Map<String, dynamic>>.broadcast();
  
  OpenEarableBackgroundTaskHandler() {
    _initialize();
  }
  
  void _initialize() {
    // Initialize sub-services
    _settingsService = SettingsService();
    _connectedDevicesService = ConnectedDevicesService();
    _recordingService = RecordingService(
      connectedDevicesService: _connectedDevicesService,
      settingsService: _settingsService,
    );
    
    // Set up listeners for sub-services
    _connectedDevicesService.heartRateStream.listen((heartRate) {
      _heartRateStreamController.add(heartRate);
      // Send heart rate to main isolate
      FlutterForegroundTask.sendDataToMain({
        'type': 'heartRate',
        'value': heartRate,
      });
    });
    
    _connectedDevicesService.onDevicesChanged.listen((devices) {
      final devicesList = devices.map((device) => {
        'id': device.deviceId,
        'name': device.name,
        'type': device.runtimeType.toString(),
      }).toList();
      
      _connectedDevicesStreamController.add(devicesList);
      // Send connected devices to main isolate
      FlutterForegroundTask.sendDataToMain({
        'type': 'connectedDevices',
        'devices': devicesList,
      },);
    });
    
    _recordingService.onStateChanged.listen((state) {
      _recordingStateStreamController.add(state);
      // Send recording state to main isolate
      FlutterForegroundTask.sendDataToMain({
        'type': 'recordingState',
        'state': state,
      });
    });
  }
  
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Update notification
    FlutterForegroundTask.updateService(
      notificationTitle: 'OpenEarable Sport Study',
      notificationText: 'Service is running',
    );
    
    // Start device scanning when service starts
    _connectedDevicesService.startScanning();
  }
  
  @override
  void onRepeatEvent(DateTime timestamp) {
    // Periodic update of the notification (if needed)
    if (_recordingService.isRecording) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'OpenEarable Sport Study',
        notificationText: 'Recording in progress: ${_recordingService.formattedRecordingDuration}',
      );
    }
  }
  
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Cleanup resources
    _heartRateStreamController.close();
    _connectedDevicesStreamController.close();
    _recordingStateStreamController.close();
    
    // Stop recording if it's in progress
    if (_recordingService.isRecording) {
      await _recordingService.stopRecording();
    }
  }
  
  @override
  void onReceiveData(Object? data) {
    if (data is! Map<String, dynamic>) return;
    
    final command = data['command'] as String?;
    final params = data['params'] as Map<String, dynamic>?;
    
    switch (command) {
      case CMD_START_RECORDING:
        _recordingService.startRecording();
        break;
      case CMD_STOP_RECORDING:
        _recordingService.stopRecording();
        break;
      case CMD_SCAN_DEVICES:
        _connectedDevicesService.startScanning();
        break;
      case CMD_CONNECT_DEVICE:
        if (params != null && params.containsKey('deviceId') && params.containsKey('deviceName')) {
          _connectedDevicesService.connectToDevice(
            params['deviceId'] as String,
            params['deviceName'] as String,
          );
        }
        break;
      case CMD_SET_PARTICIPANT_ID:
        if (params != null && params.containsKey('participantId')) {
          _settingsService.setParticipantId(params['participantId'] as String);
        }
        break;
    }
  }
}

/// Manager class to control the background service from the main app
class BackgroundServiceManager {
  static final BackgroundServiceManager _instance = BackgroundServiceManager._();
  static BackgroundServiceManager get instance => _instance;
  
  BackgroundServiceManager._();
  
  bool _isInitialized = false;
  final StreamController<Map<String, dynamic>> _dataFromServiceController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<Map<String, dynamic>> get dataFromService => _dataFromServiceController.stream;
  
  // Stream transformers for specific data types
  Stream<int?> get heartRateStream => dataFromService
      .where((data) => data['type'] == 'heartRate')
      .map((data) => data['value'] as int?);
  
  Stream<List<Map<String, dynamic>>> get connectedDevicesStream => dataFromService
      .where((data) => data['type'] == 'connectedDevices')
      .map((data) => (data['devices'] as List<dynamic>).cast<Map<String, dynamic>>());
  
  Stream<Map<String, dynamic>> get recordingStateStream => dataFromService
      .where((data) => data['type'] == 'recordingState')
      .map((data) => data['state'] as Map<String, dynamic>);
  
  /// Initialize the background service manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Initialize port for communication between TaskHandler and UI
    FlutterForegroundTask.initCommunicationPort();
    
    // Set callback to receive data from background service
    FlutterForegroundTask.eventChannel.setListener(_handleBackgroundData);
    
    _isInitialized = true;
  }
  
  void _handleBackgroundData(dynamic data) {
    if (data is Map<String, dynamic>) {
      _dataFromServiceController.add(data);
    }
  }
  
  /// Request necessary permissions for the background service
  Future<bool> requestPermissions() async {
    // Request notification permission
    final notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
    
    // Request battery optimization permissions on Android
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }
    
    // Check for exact alarms permission on Android
    if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      await FlutterForegroundTask.openAlarmsAndRemindersSettings();
    }
    
    return true;
  }
  
  /// Initialize the foreground service
  void initForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'open_earable_sport_study',
        channelName: 'OpenEarable Sport Study',
        channelDescription: 'Background service for OpenEarable Sport Study app',
        importance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }
  
  /// Start the foreground service
  Future<bool> startService() async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Initialize service
    initForegroundService();
    
    // Start service
    final result = await FlutterForegroundTask.startService(
      notificationTitle: 'OpenEarable Sport Study',
      notificationText: 'Service is running',
      callback: startCallback,
    );
    
    return result == ServiceRequestResult.SUCCESS;
  }
  
  /// Stop the foreground service
  Future<bool> stopService() async {
    final result = await FlutterForegroundTask.stopService();
    return result == ServiceRequestResult.SUCCESS;
  }
  
  /// Check if the foreground service is running
  Future<bool> isServiceRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
  
  /// Send command to the background service
  void sendCommand(String command, [Map<String, dynamic>? params]) {
    FlutterForegroundTask.sendDataToTask({
      'command': command,
      'params': params ?? {},
    });
  }
  
  /// Start recording in the background service
  void startRecording() {
    sendCommand(OpenEarableBackgroundTaskHandler.cmdStartRecording);
  }

  /// Stop recording in the background service
  void stopRecording() {
    sendCommand(OpenEarableBackgroundTaskHandler.cmdStopRecording);
  }

  /// Start scanning for devices in the background service
  void startScanning() {
    sendCommand(OpenEarableBackgroundTaskHandler.cmdScanDevices);
  }

  /// Connect to a device in the background service
  void connectToDevice(String deviceId, String deviceName) {
    sendCommand(OpenEarableBackgroundTaskHandler.cmdConnectDevice, {
      'deviceId': deviceId,
      'deviceName': deviceName,
    },);
  }

  /// Set participant ID in the background service
  void setParticipantId(String participantId) {
    sendCommand(OpenEarableBackgroundTaskHandler.cmdSetParticipantId, {
      'participantId': participantId,
    },);
  }
  
  /// Dispose the background service manager
  void dispose() {
    _dataFromServiceController.close();
  }
}