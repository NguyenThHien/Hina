import 'package:permission_handler/permission_handler.dart';

enum PermissionResult { granted, denied, permanentlyDenied }

abstract class Permissions {
  /// Kiểm tra camera + micro, không hiện popup.
  Future<PermissionResult> check();

  /// Hiện popup hệ thống cho quyền còn thiếu.
  Future<PermissionResult> request();

  Future<void> openSettings();
}

class DevicePermissions implements Permissions {
  static const _needed = [Permission.camera, Permission.microphone];

  @override
  Future<PermissionResult> check() async {
    final statuses = await Future.wait(_needed.map((p) => p.status));
    return _combine(statuses);
  }

  @override
  Future<PermissionResult> request() async {
    final results = await _needed.request();
    return _combine(results.values);
  }

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }

  PermissionResult _combine(Iterable<PermissionStatus> statuses) {
    if (statuses.every((s) => s.isGranted)) return PermissionResult.granted;
    if (statuses.any((s) => s.isPermanentlyDenied)) {
      return PermissionResult.permanentlyDenied;
    }
    return PermissionResult.denied;
  }
}
