import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_earable_flutter_edge_ml_connection/open_earable_flutter_edge_ml_connection.dart';
import 'connected_device_controller.dart';
import 'settings_controller.dart';

class RecordingController extends ChangeNotifier {
  final ConnectedDeviceController deviceController;
  final SettingsController settingsController;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  Timer? _timer;

  bool get isRecording => _isRecording;

  Duration get recordingDuration => _recordingDuration;

  LastRecording? _lastRecording;

  LastRecording? get lastRecording => _lastRecording;

  // Heart rate for sync access
  int? _currentHeartRate;

  // Data of the current recording
  String _participantId = '';
  int? _startHeartRate;
  int? _exerciseHeartRate;
  Timer? _exerciseTimer;

  OpenEarableEdgeMLConnection? _edgeMLConnection;

  RecordingController({
    required this.deviceController,
    required this.settingsController,
  }) {
    // Listen to the heart rate stream to have this available sync
    deviceController.heartRateStream.listen(
      (heartRate) {
        _currentHeartRate = heartRate;
      },
    );

    // Restore connection if needed
    deviceController.registerOnConnectCallback(
      (wearable) {
        if (_isRecording) {
          _edgeMLConnection?.reconnectWearable(wearable);
        }
      },
    );
  }

  /// Initialize sensors for recording
  void _initSensorsForRecording() {
    for (final wearable in deviceController.connectedDevices) {
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
    for (final wearable in deviceController.connectedDevices) {
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
        // Set every sensor to maximum frequency to enable it
        for (var sensor in (wearable as SensorManager).sensors) {
          for (var configuration in sensor.relatedConfigurations) {
            if (configuration is SensorFrequencyConfiguration) {
              configuration.setFrequencyBestEffort(0);
            }
          }
        }
      }

      for (Sensor sensor in (wearable as SensorManager).sensors) {
        // Enable heart rate and HRV sensors
        if (sensor is HeartRateSensor ||
            sensor is HeartRateVariabilitySensor) {
          for (SensorConfiguration config in sensor.relatedConfigurations) {
            if (config is SensorFrequencyConfiguration) {
              config.setMaximumFrequency();
            }
          }
        }
      }
    }
  }

  void start() async {
    if (!_isRecording) {
      _isRecording = true;
      _lastRecording = null;

      _initSensorsForRecording();

      // Some data of the current recording
      _startHeartRate = _currentHeartRate;
      _participantId = settingsController.participantId;
      _exerciseHeartRate = null;

      // Start the recording
      _edgeMLConnection = await OpenEarableEdgeMLConnection.createCsvConnection(
        name: _participantId,
        wearableSensorGroups: deviceController.connectedDevices
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
      });

      _recordingDuration = Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration += const Duration(seconds: 1);
        notifyListeners();
      });
      notifyListeners();
    }
  }

  void stop() {
    if (_isRecording) {
      _isRecording = false;
      _exerciseTimer?.cancel();
      _exerciseTimer = null;

      _disableSensorsAfterRecording();
      _edgeMLConnection?.stop();

      _timer?.cancel();
      _timer = null;

      // Save the last recording metadata
      _lastRecording = LastRecording(
        participantId: _participantId,
        duration: _recordingDuration,
        startHeartRate: _startHeartRate,
        exerciseHeartRate: _exerciseHeartRate,
      );

      _edgeMLConnection = null;
      _recordingDuration = Duration.zero;
      notifyListeners();
    }
  }
}

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
}
