import 'package:flutter/material.dart';

import '../pages/connected_devices_page.dart';
import '../pages/stored_recordings_page.dart';

class ActionAppBar extends AppBar {
  ActionAppBar({Key? key})
      : super(
          key: key,
          title: const Text("Home"),
          actions: <Widget>[
            const SizedBox(width: 8),
            Builder(
              builder: (context) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StoredRecordingsPage(),
                    ),
                  );
                },
                child: const Text('Recordings'),
              ),
            ),
            const SizedBox(width: 8),
            Builder(
              builder: (context) => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ConnectedDevicesPage(),
                    ),
                  );
                },
                child: const Text('Devices'),
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
}
