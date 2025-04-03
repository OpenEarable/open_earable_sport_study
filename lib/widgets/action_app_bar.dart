import 'package:flutter/material.dart';

import '../pages/connected_devices_page.dart';
import '../pages/stored_recordings_page.dart';

class ActionAppBar extends AppBar {
  ActionAppBar({Key? key})
      : super(
          key: key,
          title: const Text("Home"),
          actions: <Widget>[
            Builder(
              builder: (context) => PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'connected') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConnectedDevicesPage(),
                      ),
                    );
                  } else if (value == 'recordings') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StoredRecordingsPage(),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'connected',
                    child: Text('Connected Devices'),
                  ),
                  PopupMenuItem(
                    value: 'recordings',
                    child: Text('Stored Recordings'),
                  ),
                ],
              ),
            ),
          ],
        );
}
