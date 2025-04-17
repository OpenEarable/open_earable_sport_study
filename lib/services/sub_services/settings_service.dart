import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage settings in the background isolate
class SettingsService {
  static const String _keyParticipantId = 'participantId';
  
  String _participantId = '';
  final StreamController<String> _participantIdController = StreamController<String>.broadcast();
  
  String get participantId => _participantId;
  Stream<String> get onParticipantIdChanged => _participantIdController.stream;
  
  SettingsService() {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _participantId = prefs.getString(_keyParticipantId) ?? '';
    _participantIdController.add(_participantId);
  }
  
  Future<void> setParticipantId(String id) async {
    if (_participantId == id) return;
    
    _participantId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyParticipantId, id);
    _participantIdController.add(_participantId);
  }
  
  void dispose() {
    _participantIdController.close();
  }
}
