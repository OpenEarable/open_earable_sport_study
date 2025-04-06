import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:open_earable_flutter_edge_ml_connection/open_earable_flutter_edge_ml_connection.dart';
import 'connected_device_controller.dart';
import 'settings_controller.dart';

class RecordingController extends ChangeNotifier {
  final ConnectedDeviceController deviceController;
  final SettingsController settingsController;

  bool _isRecording = false;
  DateTime? _recordingStart;

  bool get isRecording => _isRecording;

  DateTime? get recordingStart => _recordingStart;

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

  void start() async {
    if (!_isRecording) {
      _isRecording = true;
      _lastRecording = null;

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

      _recordingStart = DateTime.now();
      notifyListeners();
    }
  }

  void stop() {
    if (_isRecording) {
      _isRecording = false;
      _exerciseTimer?.cancel();
      _exerciseTimer = null;

      _edgeMLConnection?.stop();

      // Save the last recording metadata
      _lastRecording = LastRecording(
        participantId: _participantId,
        duration: DateTime.now().difference(_recordingStart!),
        startHeartRate: _startHeartRate,
        exerciseHeartRate: _exerciseHeartRate,
      );

      _edgeMLConnection = null;
      _recordingStart = null;
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
