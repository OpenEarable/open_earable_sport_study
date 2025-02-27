import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/connected_device_controller.dart';
import 'pages/home_page.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ConnectedDeviceController(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Devices App',
      home: HomePage(),
    );
  }
}
