import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hina_mobile/permissions/device_permissions.dart';
import 'package:hina_mobile/session/session_controller.dart';
import 'package:hina_mobile/ui/theme.dart';
import 'package:hina_mobile/ui/widgets.dart';

typedef _Info = ({IconData icon, String name, String use, String why});

const _info = <AppPermission, _Info>{
  AppPermission.microphone: (
    icon: Icons.mic_none,
    name: 'Microphone',
    use: 'Nghe lời nói của bạn',
    why: 'Hina cần microphone để lắng nghe lời nói và câu hỏi của bạn trong lúc trò chuyện.',
  ),
  AppPermission.camera: (
    icon: Icons.photo_camera_outlined,
    name: 'Camera',
    use: 'Đọc chữ và quan sát môi trường',
    why: 'Hina cần camera để đọc chữ, nhận biết đồ vật và cảnh báo vật cản phía trước.',
  ),
};

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key, required this.permissions, required this.controller});

  final Permissions permissions;
  final SessionController controller;

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _status = <AppPermission, PermissionResult>{};
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh); // quay lại từ Cài đặt hệ thống
    unawaited(_refresh());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    for (final p in AppPermission.values) {
      final s = await widget.permissions.statusOf(p);
      if (!mounted) return;
      setState(() => _status[p] = s);
    }
  }

  Future<void> _ask(AppPermission p) async {
    final info = _info[p];
    if (info == null || _status[p] == PermissionResult.granted) return;
    if (_status[p] == PermissionResult.permanentlyDenied) return _guide(info);

    final agreed = await showHinaDialog(
      context,
      icon: info.icon,
      title: 'Hina xin phép dùng ${info.name.toLowerCase()} nhé?',
      text: info.why,
      confirm: 'Đồng ý, tiếp tục',
    );
    if (!agreed || !mounted) return;

    final result = await widget.permissions.requestOf(p);
    if (!mounted) return;
    setState(() => _status[p] = result);
    switch (result) {
      case PermissionResult.granted:
        await widget.controller.start(); // đủ cả hai quyền thì phiên tự kết nối
      case PermissionResult.denied:
        await showHinaDialog(
          context,
          icon: Icons.favorite_border,
          title: 'Bạn có thể thử lại sau nhé.',
          text: 'Bạn vẫn dùng được những tính năng không cần quyền này.',
          confirm: 'Đã hiểu',
        );
      case PermissionResult.permanentlyDenied:
        final more = await showHinaDialog(
          context,
          icon: Icons.favorite_border,
          title: 'Bạn có thể thử lại sau nhé.',
          text: 'Bạn đã từ chối quyền hai lần. Hina sẽ hướng dẫn cấp quyền trong Cài đặt.',
          confirm: 'Xem hướng dẫn',
        );
        if (more && mounted) await _guide(info);
    }
  }

  Future<void> _guide(_Info info) async {
    final open = await showHinaDialog(
      context,
      icon: info.icon,
      title: 'Bật quyền trong Cài đặt',
      text: 'Bạn có thể tự cấp quyền ${info.name} theo hướng dẫn dưới đây.',
      guide: '1. Mở Cài đặt trên điện thoại\n2. Chọn Ứng dụng → Hina → Quyền\n3. Chọn ${info.name} → Cho phép',
      confirm: 'Mở Cài đặt',
    );
    if (open) await widget.permissions.openSettings();
  }

  Future<void> _enter() async {
    await widget.controller.start();
    if (mounted) goTo(context, Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return HinaPage(
      route: Routes.permissions,
      actions: [HinaButton('Vào trang chủ', onPressed: _enter)],
      children: [
        const HinaHeading(
          'Hina xin phép bạn\nmột chút nhé.',
          hint: 'Bạn có thể cấp quyền khi cần sử dụng các tính năng tương ứng.',
        ),
        const SizedBox(height: 20),
        for (final p in AppPermission.values)
          if (_info[p] case final info?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _PermissionRow(info: info, status: _status[p], onTap: () => _ask(p)),
            ),
      ],
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.info, required this.status, required this.onTap});

  final _Info info;
  final PermissionResult? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    final granted = status == PermissionResult.granted;
    return Semantics(
      button: !granted,
      label: '${info.name}, ${info.use}, ${granted ? 'đã cấp' : 'chưa cấp'}',
      excludeSemantics: true,
      child: HinaCard(
        onTap: onTap,
        padding: const EdgeInsets.all(13),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(children: [
            SymbolBox(info.icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(info.name, style: const TextStyle(fontSize: 13.8)),
                const SizedBox(height: 5),
                Text(info.use, style: const TextStyle(fontSize: 11.8, height: 1.5)),
              ]),
            ),
            Icon(granted ? Icons.check : Icons.chevron_right, color: c.ink),
          ]),
        ),
      ),
    );
  }
}
