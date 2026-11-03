import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hina_mobile/prefs/app_prefs.dart';
import 'package:hina_mobile/session/session_controller.dart';
import 'package:hina_mobile/ui/camera_screen.dart';
import 'package:hina_mobile/ui/home_screen.dart';
import 'package:hina_mobile/ui/onboarding_screen.dart';
import 'package:hina_mobile/ui/permissions_screen.dart';
import 'package:hina_mobile/ui/record_screen.dart';
import 'package:hina_mobile/ui/settings_screen.dart';
import 'package:hina_mobile/ui/theme.dart';
import 'package:hina_mobile/ui/widgets.dart';

class HinaApp extends StatefulWidget {
  const HinaApp({super.key, required this.controller, required this.prefs});

  final SessionController controller;
  final AppPrefs prefs;

  @override
  State<HinaApp> createState() => _HinaAppState();
}

class _HinaAppState extends State<HinaApp> with WidgetsBindingObserver {
  SessionController get _c => widget.controller;
  AppPrefs get _prefs => widget.prefs;
  late final bool _onboarded = _prefs.onboarded; // màn gốc chỉ chọn một lần lúc mở app

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prefs.addListener(_syncVoice);
    _syncVoice();
    // Lần đầu: để màn Giới thiệu/Cấp quyền gọi start(), tránh app tự đọc lời xin quyền.
    if (_onboarded) unawaited(_c.start());
  }

  void _syncVoice() => _c.voiceGuide = _prefs.voiceGuide;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _prefs.removeListener(_syncVoice);
    _c.dispose();
    super.dispose();
  }

  // Chỉ `paused` (xuống nền) mới nhả camera; `inactive` xảy ra cả khi hiện hộp thoại quyền.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_c.pause());
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_c.resume());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _prefs,
      builder: (context, _) => MaterialApp(
        title: 'Hina',
        theme: hinaTheme(_prefs),
        // Cỡ chữ trong app nhân thêm với cỡ chữ hệ thống, không thay thế nó.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          final scale = mq.textScaler.scale(1) * _prefs.fontSize.px / FontSize.medium.px;
          return MediaQuery(
            data: mq.copyWith(textScaler: TextScaler.linear(scale)),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: _onboarded ? HomeScreen(controller: _c) : OnboardingScreen(prefs: _prefs),
        routes: {
          Routes.home: (_) => HomeScreen(controller: _c),
          Routes.permissions: (_) => PermissionsScreen(permissions: _c.permissions, controller: _c),
          Routes.camera: (_) => CameraScreen(camera: _c.camera),
          Routes.record: (_) => RecordScreen(controller: _c),
          Routes.settings: (_) => SettingsScreen(prefs: _prefs),
        },
      ),
    );
  }
}
