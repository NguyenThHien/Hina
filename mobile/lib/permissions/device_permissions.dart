import 'package:permission_handler/permission_handler.dart';

abstract class Permissions {
  /// true nếu cả camera và micro đã được cấp.
  Future<bool> requestAll();
}

class DevicePermissions implements Permissions {
  @override
  Future<bool> requestAll() async {
    final results = await [Permission.camera, Permission.microphone].request();
    return results.values.every((s) => s.isGranted);
  }
}
