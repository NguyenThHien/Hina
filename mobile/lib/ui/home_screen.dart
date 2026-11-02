import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hina_mobile/session/session_controller.dart';

// "Chấm nổi": nền hồng phấn, mọi nét viền và chữ là tím mận; nút như một phím nổi.
const _blush = Color(0xFFFCE8EE);
const _petal = Color(0xFFF7C6D3);
const _plum = Color(0xFF3B0F22);
const _rose = Color(0xFFF48FB1); // bấm được (chữ mận ~7.3:1)
const _hotPink = Color(0xFFFF5C93); // đang nghe (~5.6:1)
const _mauve = Color(0xFFD9B8C7); // đang bận (~9:1)
const _berry = Color(0xFFA31545); // lỗi (chữ trắng ~7.6:1)
const _white = Color(0xFFFFFFFF);

const _lift = 8.0; // độ nổi của phím

enum _Glyph { icon, soundBars, brailleLoader }

class _Look {
  const _Look(this.fill, this.ink, this.title, this.icon, {this.glyph = _Glyph.icon});
  final Color fill;
  final Color ink;
  final String title;
  final IconData icon;
  final _Glyph glyph;
}

_Look _lookFor(SessionState state) => switch (state) {
      SessionState.init => const _Look(_mauve, _plum, 'Đang khởi động', Icons.hourglass_top,
          glyph: _Glyph.brailleLoader),
      SessionState.needsPermission => const _Look(_rose, _plum, 'Cấp quyền', Icons.lock_open),
      SessionState.permissionBlocked =>
        const _Look(_berry, _white, 'Mở cài đặt', Icons.settings),
      SessionState.ready => const _Look(_rose, _plum, 'Bấm để hỏi', Icons.mic),
      SessionState.listening =>
        const _Look(_hotPink, _plum, 'Đang nghe', Icons.graphic_eq, glyph: _Glyph.soundBars),
      SessionState.waiting => const _Look(_mauve, _plum, 'Đang xử lý', Icons.hourglass_top,
          glyph: _Glyph.brailleLoader),
      SessionState.disconnected => const _Look(_berry, _white, 'Mất kết nối', Icons.wifi_off),
      SessionState.error => const _Look(_berry, _white, 'Có lỗi', Icons.error_outline),
    };

const _tappable = {
  SessionState.needsPermission,
  SessionState.permissionBlocked,
  SessionState.ready,
  SessionState.listening,
};
const _connected = {SessionState.ready, SessionState.listening, SessionState.waiting};

/// Một phím lớn ở dưới màn hình. Chạm bất cứ đâu cũng là bấm phím,
/// để người không nhìn rõ không phải ngắm vị trí.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        final look = _lookFor(state);
        final tappable = _tappable.contains(state);

        return Semantics(
          container: true,
          button: true,
          enabled: tappable,
          child: ColoredBox(
            color: _blush,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: tappable ? controller.toggleListening : null,
                onHighlightChanged: (down) => setState(() => _pressed = down && tappable),
                splashFactory: NoSplash.splashFactory,
                highlightColor: Colors.transparent,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Header(connected: _connected.contains(state)),
                        const SizedBox(height: 32),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              controller.message,
                              style: const TextStyle(
                                color: _plum,
                                fontSize: 28,
                                fontWeight: FontWeight.w500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _Key(look: look, raised: tappable && !_pressed),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Phím nổi: viền mận dày + bóng cứng. Lún xuống khi bấm hoặc khi app đang bận.
class _Key extends StatelessWidget {
  const _Key({required this.look, required this.raised});

  final _Look look;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final size = MediaQuery.sizeOf(context);
    final titleSize = (size.width * 0.14).clamp(40.0, 60.0);

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 120),
      height: size.height * 0.42,
      transform: Matrix4.translationValues(0, raised ? 0 : _lift, 0),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: look.fill,
        borderRadius: BorderRadius.circular(44),
        border: Border.all(color: _plum, width: 3),
        boxShadow: [BoxShadow(color: _plum, offset: Offset(0, raised ? _lift : 0))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 72, child: _glyph(reduceMotion)),
          Text(
            look.title,
            style: TextStyle(
              color: look.ink,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.0,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glyph(bool reduceMotion) => switch (look.glyph) {
        _Glyph.icon => Icon(look.icon, size: 64, color: look.ink),
        _Glyph.soundBars => _SoundBars(color: look.ink, animate: !reduceMotion),
        _Glyph.brailleLoader => _BrailleLoader(color: look.ink, animate: !reduceMotion),
      };
}

/// Logo: 4 ô Braille đúng chính tả "hina" + chữ Hina.
class _Header extends StatelessWidget {
  const _Header({required this.connected});

  final bool connected;

  static const _hina = [
    {1, 2, 5}, // h
    {2, 4}, // i
    {1, 3, 4, 5}, // n
    {1}, // a
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              for (final dots in _hina)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _BrailleCell(on: dots, dot: 5, gap: 3, onColor: _plum, offColor: _petal),
                ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        const Text(
          'Hina',
          style: TextStyle(color: _plum, fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: connected ? _plum : Colors.transparent,
            border: Border.all(color: _plum, width: 2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          connected ? 'Đã kết nối' : 'Chưa kết nối',
          style: const TextStyle(color: _plum, fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Ô Braille 2 cột x 3 hàng; chấm 1-2-3 cột trái, 4-5-6 cột phải.
class _BrailleCell extends StatelessWidget {
  const _BrailleCell({
    required this.on,
    required this.dot,
    required this.gap,
    required this.onColor,
    required this.offColor,
  });

  final Set<int> on;
  final double dot;
  final double gap;
  final Color onColor;
  final Color offColor;

  Widget _dot(int n) => Container(
        width: dot,
        height: dot,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on.contains(n) ? onColor : offColor,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 0; row < 3; row++)
          Padding(
            padding: EdgeInsets.only(bottom: row < 2 ? gap : 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [_dot(row + 1), SizedBox(width: gap), _dot(row + 4)],
            ),
          ),
      ],
    );
  }
}

/// Đang xử lý: 6 chấm của một ô Braille sáng dần theo thứ tự 1 → 6.
class _BrailleLoader extends StatelessWidget {
  const _BrailleLoader({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _Looping(
      animate: animate,
      period: const Duration(milliseconds: 1400),
      builder: (t) {
        final lit = animate ? math.min((t * 7).floor(), 6) : 6;
        return _BrailleCell(
          on: {for (var i = 1; i <= lit; i++) i},
          dot: 16,
          gap: 8,
          onColor: color,
          offColor: color.withAlpha(60),
        );
      },
    );
  }
}

/// Đang nghe: 5 vạch sóng âm nhún theo nhịp.
class _SoundBars extends StatelessWidget {
  const _SoundBars({required this.color, required this.animate});

  final Color color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return _Looping(
      animate: animate,
      period: const Duration(milliseconds: 900),
      builder: (t) => Row(
        children: [
          for (var i = 0; i < 5; i++)
            Container(
              width: 10,
              height: 18 + 46 * (0.5 + 0.5 * math.sin(2 * math.pi * (t + i * 0.18))),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
            ),
        ],
      ),
    );
  }
}

/// Vòng lặp animation; dừng khi người dùng bật giảm chuyển động.
class _Looping extends StatefulWidget {
  const _Looping({required this.animate, required this.period, required this.builder});

  final bool animate;
  final Duration period;
  final Widget Function(double t) builder;

  @override
  State<_Looping> createState() => _LoopingState();
}

class _LoopingState extends State<_Looping> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(_Looping old) {
    super.didUpdateWidget(old);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      AnimatedBuilder(animation: _controller, builder: (_, __) => widget.builder(_controller.value));
}
