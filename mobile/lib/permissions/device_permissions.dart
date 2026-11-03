import 'package:permission_handler/permission_handler.dart';

enum PermissionResult { granted, denied, permanentlyDenied }

/// Quyền app cần. Không xin "Thông báo": app không gửi thông báo.
enum AppPermission { microphone, camera }

abstract class Permissions {
  /// Kiểm tra camera + micro, không hiện popup.
  Future<PermissionResult> check();

  /// Hiện popup hệ thống cho quyền còn thiếu.
  Future<PermissionResult> request();

  /// Trạng thái/xin từng quyền riêng (màn Cấp quyền).
  Future<PermissionResult> statusOf(AppPermission p);
  Future<PermissionResult> requestOf(AppPermission p);

  Future<void> openSettings();
}

class DevicePermissions implements Permissions {
  static const _all = [Permission.microphone, Permission.camera];

  static Permission _of(AppPermission p) => switch (p) {
        AppPermission.microphone => Permission.microphone,
        AppPermission.camera => Permission.camera,
      };

  @override
  Future<PermissionResult> check() async {
    final statuses = await Future.wait(_all.map((p) => p.status));
    return _combine(statuses);
  }

  @override
  Future<PermissionResult> request() async {
    final results = await _all.request();
    return _combine(results.values);
  }

  @override
  Future<PermissionResult> statusOf(AppPermission p) async =>
      _combine([await _of(p).status]);

  // Android tự chuyển sang "permanentlyDenied" sau 2 lần từ chối: đó là lúc hiện hướng dẫn Cài đặt.
  @override
  Future<PermissionResult> requestOf(AppPermission p) async =>
      _combine([await _of(p).request()]);

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
