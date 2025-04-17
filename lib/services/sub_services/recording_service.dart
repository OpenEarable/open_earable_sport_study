import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_earable_flutter_edge_ml_connection/open_earable_flutter_edge_ml_connection.dart';

import 'connected_devices_service.dart';
import 'settings_service.dart';

/// Service to manage recording in the background isolate
class RecordingService {
  final ConnectedDevicesService connectedDevicesService;
  final SettingsService settingsService;
  
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;
  
  // Heart rate for sync access
  int? _currentHeartRate;
  
  // Data of the current recording
  String _participantId = '';
  int? _startHeartRate;
  int? _exerciseHeartRate;
  Timer? _exerciseTimer;
  
  OpenEarableEdgeMLConnection? _edgeMLConnection;
  
  // Stream controllers
  final StreamController<Map<String, dynamic>> _stateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  
  // Getters
  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  String get formattedRecordingDuration {
    final hours = _recordingDuration.inHours.toString().padLeft(2, '0');
    final minutes = (_recordingDuration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_recordingDuration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
  
  Stream<Map<String, dynamic>> get onStateChanged => _stateController.stream;
  
  RecordingService({
    required this.connectedDevicesService,
    required this.settingsService,
  }) {
    // Listen to the heart rate stream to have this available sync
    connectedDevicesService.heartRateStream.listen(
      (heartRate) {
        _currentHeartRate = heartRate;
      },
    );
  }
  
  /// Initialize sensors for recording
  void _initSensorsForRecording() {
    for (final wearable in connectedDevicesService.connectedDevices) {
      if (wearable is! SensorManager) {
        continue;
      }

      if (wearable is OpenEarableV2) {
        // Special case for the OpenEarable V2
        // Set every sensor to maximum frequency to enable it
        for (var sensor in (wearable as SensorManager).sensors) {
          if (sensor.sensorName == "ACCELEROMETER" &&
              sensor.axisCount >= 1 &&
              sensor.axisUnits[0] == "g") {
            // Bone conductor, we don't want to record this.
            // Extra case because we have two "ACCELEROMETER" sensors
            continue;
          }

          int? targetFrequencyHz;
          bool record = false;
          bool stream = false;

          switch (sensor.sensorName) {
            case "ACCELEROMETER":
              targetFrequencyHz = 50;
              record = true;
              break;
            case "GYROSCOPE":
              targetFrequencyHz = 50;
              record = true;
              break;
            case "MAGNETOMETER":
              targetFrequencyHz = 50;
              record = true;
              break;
            case "PHOTOPLETHYSMOGRAPHY":
              targetFrequencyHz = 400;
              record = true;
              break;
            case "BAROMETER":
              targetFrequencyHz = 200;
              record = true;
              stream = true;
              break;
            default:
              targetFrequencyHz = null;
          }

          if (targetFrequencyHz == null) {
            continue;
          }
          for (var configuration in sensor.relatedConfigurations) {
            if (configuration is SensorConfigurationOpenEarableV2) {
              configuration.setFrequencyBestEffort(
                targetFrequencyHz,
                streamData: stream,
                recordData: record,
              );
            } else if (configuration is SensorFrequencyConfiguration) {
              configuration.setFrequencyBestEffort(targetFrequencyHz);
            }
          }
        }
      } else {
        // Set every sensor to maximum frequency to enable it
        for (var sensor in (wearable as SensorManager).sensors) {
          for (var configuration in sensor.relatedConfigurations) {
            if (configuration is SensorFrequencyConfiguration) {
              configuration.setMaximumFrequency();
            }
          }
        }
      }
    }
  }

  /// Disables sensors after recording
  void _disableSensorsAfterRecording() {
    for (final wearable in connectedDevicesService.connectedDevices) {
      if (wearable is! SensorManager) {
        continue;
      }

      if (wearable is OpenEarableV2) {
        // Special case for the OpenEarable V2
        for (var sensor in (wearable as SensorManager).sensors) {
          if (sensor.sensorName == "ACCELEROMETER" &&
              sensor.axisCount >= 1 &&
              sensor.axisUnits[0] == "g") {
            // Bone conductor
            continue;
          }

          int? targetFrequencyHz;

          switch (sensor.sensorName) {
            case "ACCELEROMETER":
            case "GYROSCOPE":
            case "MAGNETOMETER":
            case "PHOTOPLETHYSMOGRAPHY":
            case "BAROMETER":
              targetFrequencyHz = 0;
              break;
            default:
              targetFrequencyHz = null;
          }

          if (targetFrequencyHz == null) {
            continue;
          }
          for (var configuration in sensor.relatedConfigurations) {
            if (configuration is SensorConfigurationOpenEarableV2) {
              configuration.setFrequencyBestEffort(
                targetFrequencyHz,
                streamData: false,
                recordData: false,
              );
            } else if (configuration is SensorFrequencyConfiguration) {
              configuration.setFrequencyBestEffort(targetFrequencyHz);
            }
          }
        }
      } else {
        // Set every sensor to frequency 0 to disable it
        for (var sensor in (wearable as SensorManager).sensors) {
          for (var configuration in sensor.relatedConfigurations) {
            if (configuration is SensorFrequencyConfiguration) {
              configuration.setFrequencyBestEffort(0);
            }
          }
        }
      }

      // Keep heart rate and HRV sensors enabled
      for (Sensor sensor in (wearable as SensorManager).sensors) {
        if (sensor is HeartRateSensor || sensor is HeartRateVariabilitySensor) {
          for (SensorConfiguration config in sensor.relatedConfigurations) {
            if (config is SensorFrequencyConfiguration) {
              config.setMaximumFrequency();
            }
          }
        }
      }
    }
  }

  /// Start a recording session
  Future<void> startRecording() async {
    if (!_isRecording) {
      _isRecording = true;
      _notifyStateChanged();

      _initSensorsForRecording();

      // Some data of the current recording
      _startHeartRate = _currentHeartRate;
      _participantId = settingsService.participantId;
      _exerciseHeartRate = null;

      // Start the recording
      _edgeMLConnection = await OpenEarableEdgeMLConnection.createCsvConnection(
        name: _participantId,
        wearableSensorGroups: connectedDevicesService.connectedDevices
            .map(
              (wearable) => WearableSensorGroup(
                wearable: wearable,
              ),
            )
            .toList(),
        metaData: {},
      );
      
      if (kDebugMode && _edgeMLConnection is CsvOpenEarableEdgeMLConnection) {
        print("");
        print(
          "CSV Path: \"${(_edgeMLConnection! as CsvOpenEarableEdgeMLConnection).filePath}\"",
        );
        print("");
      }

      // Start the timer to get the exercise heart rate after 2 minutes
      _exerciseTimer?.cancel();
      _exerciseTimer = Timer(const Duration(minutes: 2), () {
        _exerciseHeartRate = _currentHeartRate;
        _notifyStateChanged();
      });

      _recordingDuration = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        _notifyStateChanged();
      });
    }
  }

  /// Stop the current recording session
  Future<void> stopRecording() async {
    if (_isRecording) {
      _isRecording = false;
      _exerciseTimer?.cancel();
      _exerciseTimer = null;

      _disableSensorsAfterRecording();
      await _edgeMLConnection?.stop();

      _timer?.cancel();
      _timer = null;

      // Create the final recording state with metadata
      final lastRecording = {
        'participantId': _participantId,
        'duration': _recordingDuration.inSeconds,
        'startHeartRate': _startHeartRate,
        'exerciseHeartRate': _exerciseHeartRate,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _edgeMLConnection = null;
      _recordingDuration = Duration.zero;
      
      // Notify with the final recording state
      _stateController.add({
        'isRecording': false,
        'recordingDuration': 0,
        'lastRecording': lastRecording,
      });
    }
  }
  
  /// Notify state changes to listeners
  void _notifyStateChanged() {
    _stateController.add({
      'isRecording': _isRecording,
      'recordingDuration': _recordingDuration.inSeconds,
      'formattedDuration': formattedRecordingDuration,
      'startHeartRate': _startHeartRate,
      'exerciseHeartRate': _exerciseHeartRate,
    });
  }
  
  /// Clean up resources
  void dispose() {
    _timer?.cancel();
    _exerciseTimer?.cancel();
    _edgeMLConnection?.stop();
    _stateController.close();
  }
}


/// Recording metadata class for the UI
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
  
  /// Create from a map received from the background service
  factory LastRecording.fromMap(Map<String, dynamic> map) {
    return LastRecording(
      participantId: map['participantId'] as String,
      duration: Duration(seconds: map['duration'] as int),
      startHeartRate: map['startHeartRate'] as int?,
      exerciseHeartRate: map['exerciseHeartRate'] as int?,
    );
  }
}