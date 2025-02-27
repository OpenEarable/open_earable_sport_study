import 'package:flutter/material.dart';
import '../widgets/scan_view.dart';

class ConnectedDevicesPage extends StatelessWidget {
  const ConnectedDevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connected Devices"),
        leading: const BackButton(),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: ScanView(),
        ),
      ),
    );
  }
}
