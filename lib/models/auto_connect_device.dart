class AutoConnectDevice {
  final String id;
  final String name;

  AutoConnectDevice({required this.id, required this.name});

  factory AutoConnectDevice.fromJson(Map<String, dynamic> json) {
    return AutoConnectDevice(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}
