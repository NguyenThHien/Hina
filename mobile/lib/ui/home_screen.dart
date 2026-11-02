import 'package:flutter/material.dart';
import 'package:hina_mobile/session/session_controller.dart';

String _buttonLabel(SessionState state) => switch (state) {
      SessionState.init => 'Đang khởi động',
      SessionState.ready => 'Bấm để hỏi',
      SessionState.listening => 'Đang nghe, bấm để gửi',
      SessionState.waiting => 'Đang xử lý',
      SessionState.disconnected => 'Mất kết nối',
      SessionState.error => 'Có lỗi',
    };

/// Một nút lớn chiếm gần hết màn hình; trạng thái là live region để TalkBack tự đọc khi đổi.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final enabled = state == SessionState.ready || state == SessionState.listening;
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.message,
                      style: Theme.of(context).textTheme.headlineMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FilledButton(
                      onPressed: enabled ? controller.toggleListening : null,
                      child: Text(
                        _buttonLabel(state),
                        style: const TextStyle(fontSize: 32),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
