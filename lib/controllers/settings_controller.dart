import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/auto_connect_device.dart';

class SettingsController extends ChangeNotifier {
  /// Nullable list of auto-connect devices
  List<AutoConnectDevice>? _autoConnectDevices;

  static const String _autoConnectDevicesKey = 'auto_connect_devices';
  static const String _participantIdKey = 'participant_id';

  String _participantId = '';

  SettingsController() {
    _loadSettings();
  }

  List<AutoConnectDevice>? get autoConnectDevices => _autoConnectDevices;

  String get participantId => _participantId;

  /// Load settings from persistent storage on startup
  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? devicesJson = prefs.getString(_autoConnectDevicesKey);
    if (devicesJson != null) {
      try {
        List<dynamic> decoded = jsonDecode(devicesJson);
        _autoConnectDevices = decoded.map((item) => AutoConnectDevice.fromJson(item)).toList();
      } catch (e) {
        _autoConnectDevices = null;
      }
    }
    String participantIdValue = prefs.getString(_participantIdKey) ?? '';
    _participantId = participantIdValue;
    notifyListeners();
  }

  /// Set auto-connect devices and persist the settings
  Future<void> setAutoConnectDevices(List<AutoConnectDevice>? devices) async {
    _autoConnectDevices = devices;
    notifyListeners();
    await _saveSettings();
  }

  /// Set participant id and persist the settings
  Future<void> setParticipantId(String id) async {
    _participantId = id;
    notifyListeners();
    await _saveSettings();
  }

  /// Save settings to persistent storage
  Future<void> _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_autoConnectDevices != null) {
      String devicesJson = jsonEncode(_autoConnectDevices!.map((d) => d.toJson()).toList());
      await prefs.setString(_autoConnectDevicesKey, devicesJson);
    } else {
      await prefs.remove(_autoConnectDevicesKey);
    }
    await prefs.setString(_participantIdKey, _participantId);
  }
}
