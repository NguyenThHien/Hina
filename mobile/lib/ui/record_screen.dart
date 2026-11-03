import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hina_mobile/session/session_controller.dart';
import 'package:hina_mobile/ui/theme.dart';
import 'package:hina_mobile/ui/widgets.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  final _clock = Stopwatch();
  Timer? _tick;
  bool _asked = false; // đã hỏi ít nhất một lần: nút đổi thành "Ghi âm lại"

  SessionController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onState);
  }

  @override
  void dispose() {
    _c.removeListener(_onState);
    _tick?.cancel();
    // Rời màn giữa chừng: bỏ đoạn đang thu. Chạy sau frame vì nó báo listener khác.
    unawaited(Future(_c.cancelListening));
    super.dispose();
  }

  void _onState() {
    if (_c.state == SessionState.listening && !_clock.isRunning) {
      _clock
        ..reset()
        ..start();
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
    } else if (_c.state != SessionState.listening && _clock.isRunning) {
      _clock.stop();
      _tick?.cancel();
      _asked = true;
    }
    setState(() {});
  }

  (String, VoidCallback?) _mainAction() => switch (_c.state) {
        SessionState.ready => (_asked ? 'Ghi âm lại' : 'Bắt đầu ghi âm', _c.toggleListening),
        SessionState.listening => ('Dừng ghi âm', _c.toggleListening),
        SessionState.waiting => ('Hina đang trả lời', null),
        SessionState.needsPermission ||
        SessionState.permissionBlocked =>
          ('Cấp quyền', () => goTo(context, Routes.permissions)),
        SessionState.init => ('Đang kết nối', null),
        SessionState.disconnected => ('Đang kết nối lại', null),
        SessionState.error => ('Có lỗi, thử lại sau', null),
      };

  @override
  Widget build(BuildContext context) {
    final listening = _c.state == SessionState.listening;
    final (label, action) = _mainAction();
    final s = _clock.elapsed.inSeconds;
    final time = '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
    return HinaPage(
      route: Routes.record,
      actions: [
        HinaButton(label, onPressed: action),
        HinaButton('Về trang chủ', kind: ButtonKind.ghost, onPressed: () => goTo(context, Routes.home)),
      ],
      children: [
        const SizedBox(height: 19),
        const HinaHeading('Mình đang lắng nghe bạn.', hint: 'Nói điều bạn cần Hina giúp nhé.'),
        const SizedBox(height: 32),
        const _MicCircle(),
        const SizedBox(height: 19),
        Semantics(
          label: 'Thời gian ghi âm $s giây',
          excludeSemantics: true,
          child: Text(time, textAlign: TextAlign.center, style: const TextStyle(fontSize: 31)),
        ),
        _Wave(active: listening),
        const SizedBox(height: 3),
        // Câu trả lời đã được đọc bằng giọng nói; hiện chữ cho người còn thị lực một phần.
        Text(_c.message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, height: 1.6)),
      ],
    );
  }
}

class _MicCircle extends StatelessWidget {
  const _MicCircle();

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return ExcludeSemantics(
      child: Center(
        child: Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF7E4EE),
            border: Border.all(color: const Color(0xFFEFD8E4)),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 121,
            height: 121,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
            child: Icon(Icons.mic_none, size: 43, color: c.ink),
          ),
        ),
      ),
    );
  }
}

/// 21 vạch sóng âm; chỉ chuyển động khi đang ghi và hệ thống không tắt hiệu ứng.
class _Wave extends StatefulWidget {
  const _Wave({required this.active});

  final bool active;

  @override
  State<_Wave> createState() => _WaveState();
}

class _WaveState extends State<_Wave> with SingleTickerProviderStateMixin {
  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Wave old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final move = widget.active && !MediaQuery.disableAnimationsOf(context);
    if (move && !_anim.isAnimating) {
      unawaited(_anim.repeat(reverse: true));
    } else if (!move && _anim.isAnimating) {
      _anim
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return ExcludeSemantics(
      child: SizedBox(
        height: 76,
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 21; i++)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 4,
                  // Lệch pha theo vị trí, giống nth-child(2n/3n) trong prototype.
                  height: widget.active
                      ? 13 + 36 * (0.5 + 0.5 * math.sin(2 * math.pi * (_anim.value + i / 7)))
                      : 13,
                  decoration: BoxDecoration(color: c.accent, borderRadius: BorderRadius.circular(5)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
