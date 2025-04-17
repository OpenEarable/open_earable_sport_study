import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:open_earable_sport_study/services/background_service.dart';
import 'connected_device_controller.dart';
import 'settings_controller.dart';

class RecordingController extends ChangeNotifier {
  final ConnectedDeviceController deviceController;
  final SettingsController settingsController;
  final BackgroundServiceManager _backgroundService = BackgroundServiceManager.instance;

  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  StreamSubscription? _recordingStateSubscription;

  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  LastRecording? _lastRecording;
  LastRecording? get lastRecording => _lastRecording;

  RecordingController({
    required this.deviceController,
    required this.settingsController,
  }) {
    _initBackgroundService();
  }

  Future<void> _initBackgroundService() async {
    // Initialize and request permissions for the background service
    await _backgroundService.initialize();
    await _backgroundService.requestPermissions();
    
    // Listen to recording state changes from the background service
    _recordingStateSubscription = _backgroundService.recordingStateStream.listen(_handleRecordingStateUpdate);
    
    // If service is already running, start it up
    if (await _backgroundService.isServiceRunning() == false) {
      await _backgroundService.startService();
    }
    
    // Set the participant ID in the background service
    _backgroundService.setParticipantId(settingsController.participantId);
  }
  
  void _handleRecordingStateUpdate(Map<String, dynamic> state) {
    _isRecording = state['isRecording'] as bool;
    
    if (state.containsKey('recordingDuration')) {
      _recordingDuration = Duration(seconds: state['recordingDuration'] as int);
    }
    
    // Check if there's a last recording
    if (state.containsKey('lastRecording') && state['lastRecording'] != null) {
      final map = state['lastRecording'] as Map<String, dynamic>;
      _lastRecording = LastRecording(
        participantId: map['participantId'] as String,
        duration: Duration(seconds: map['duration'] as int),
        startHeartRate: map['startHeartRate'] as int?,
        exerciseHeartRate: map['exerciseHeartRate'] as int?,
      );
    }
    
    notifyListeners();
  }

  // Sensor configuration is now managed by the background service

  /// Start recording using the background service
  Future<void> start() async {
    if (!_isRecording) {
      // Make sure the service is running
      if (await _backgroundService.isServiceRunning() == false) {
        await _backgroundService.startService();
      }
      
      // Start recording via the background service
      _backgroundService.startRecording();
      
      // Local state update for immediate UI feedback
      _isRecording = true;
      _lastRecording = null;
      _recordingDuration = Duration.zero;
      notifyListeners();
    }
  }

  /// Stop recording using the background service
  void stop() {
    if (_isRecording) {
      // Stop recording via the background service
      _backgroundService.stopRecording();
      
      // Local state update for immediate UI feedback
      _isRecording = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _recordingStateSubscription?.cancel();
    super.dispose();
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
