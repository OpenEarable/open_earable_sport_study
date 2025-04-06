import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'controllers/connected_device_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/recording_controller.dart';
import 'pages/home_page.dart';
import 'pages/recording_page.dart';

SettingsController? _settingsController;
ConnectedDeviceController? _connectedDeviceController;
RecordingController? _recordingController;

// The callback function should always be a top-level or static function.
@pragma('vm:entry-point')
void startCallback() {

  _settingsController = SettingsController();
  _connectedDeviceController = ConnectedDeviceController(
    settingsController: _settingsController!,
  );
  _recordingController = RecordingController(
    deviceController: _connectedDeviceController!,
    settingsController: _settingsController!,
  );

  print(" ====== > startCallback");
  FlutterForegroundTask.setTaskHandler(_connectedDeviceController!);
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();


  _settingsController = SettingsController();
  _connectedDeviceController = ConnectedDeviceController(
    settingsController: _settingsController!,
  );
  _recordingController = RecordingController(
    deviceController: _connectedDeviceController!,
    settingsController: _settingsController!,
  );

  FlutterForegroundTask.initCommunicationPort();

  print(" ====== > main");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>(
          create: (_) {
            return _settingsController!;
          },
        ),
        ChangeNotifierProxyProvider<SettingsController,
            ConnectedDeviceController>(
          create: (context) {
            return _connectedDeviceController!;
          },
          update: (context, settingsController, connectedDeviceController) =>
              connectedDeviceController!,
        ),
        ChangeNotifierProvider<RecordingController>(
          create: (context) {
            return _recordingController!;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Request permissions and initialize the service.
      await _requestPermissions();
      _initService();
      await _startService();
    });
  }

  void _initService() {
    print(" ====== > _initService");
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<ServiceRequestResult> _startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        notificationIcon: null,
        notificationButtons: [
          const NotificationButton(id: 'btn_hello', text: 'hello'),
        ],
        notificationInitialRoute: '/',
        callback: startCallback,
      );
    }
  }

  Future<void> _requestPermissions() async {
    print(" ====== > _requestPermissions");
    // Android 13+, you need to allow notification permission to display foreground service notification.
    //
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Use this utility only if you provide services that require long-term survival,
      // such as exact alarm service, healthcare service, or Bluetooth communication.
      //
      // This utility requires the "android.permission.SCHEDULE_EXACT_ALARM" permission.
      // Using this permission may make app distribution difficult due to Google policy.
      // if (!await FlutterForegroundTask.canScheduleExactAlarms) {
      //   // When you call this function, will be gone to the settings page.
      //   // So you need to explain to the user why set it.
      //   await FlutterForegroundTask.openAlarmsAndRemindersSettings();
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingController = Provider.of<RecordingController>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Devices App',
      home: recordingController.isRecording
          ? const RecordingPage()
          : const HomePage(),
    );
  }
}
