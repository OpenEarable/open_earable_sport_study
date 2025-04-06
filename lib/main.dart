import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/connected_device_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/recording_controller.dart';
import 'pages/home_page.dart';
import 'pages/recording_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsController>(
          create: (_) => SettingsController(),
        ),
        ChangeNotifierProxyProvider<SettingsController,
            ConnectedDeviceController>(
          create: (context) => ConnectedDeviceController(
            settingsController: Provider.of<SettingsController>(
              context,
              listen: false,
            ),
          ),
          update: (context, settingsController, connectedDeviceController) =>
              connectedDeviceController!,
        ),
        ChangeNotifierProvider<RecordingController>(
          create: (context) => RecordingController(
            deviceController: Provider.of<ConnectedDeviceController>(
              context,
              listen: false,
            ),
            settingsController: Provider.of<SettingsController>(
              context,
              listen: false,
            ),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      // Consider the app active only when resumed; otherwise, mark it as not active
      _isActive = (state == AppLifecycleState.resumed);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isActive) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Bluetooth Devices App',
        home: Scaffold(
          body: Center(
            child: Text('Not Active'),
          ),
        ),
      );
    }

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
