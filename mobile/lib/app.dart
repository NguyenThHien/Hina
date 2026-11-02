import 'package:flutter/material.dart';
import 'package:hina_mobile/session/session_controller.dart';
import 'package:hina_mobile/ui/home_screen.dart';

class HinaApp extends StatefulWidget {
  const HinaApp({super.key, required this.controller});

  final SessionController controller;

  @override
  State<HinaApp> createState() => _HinaAppState();
}

class _HinaAppState extends State<HinaApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.dispose();
    super.dispose();
  }

  // Chỉ `paused` (xuống nền) mới nhả camera; `inactive` xảy ra cả khi hiện hộp thoại quyền.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.controller.pause();
    } else if (state == AppLifecycleState.resumed) {
      widget.controller.resume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hina',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomeScreen(controller: widget.controller),
    );
  }
}
