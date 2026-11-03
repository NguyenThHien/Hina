import 'package:flutter/material.dart';
import 'package:hina_mobile/ui/theme.dart';

abstract final class Routes {
  static const home = '/home';
  static const permissions = '/permissions';
  static const camera = '/camera';
  static const record = '/record';
  static const settings = '/settings';
}

/// Khung chung: AppBar có chữ "hina ✿", nút Trang chủ và Cài đặt; nội dung cuộn được.
class HinaPage extends StatelessWidget {
  const HinaPage({super.key, required this.route, required this.children, this.actions});

  final String route;
  final List<Widget> children;
  final List<Widget>? actions; // ghim cuối trang

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.paper,
        surfaceTintColor: c.paper,
        automaticallyImplyLeading: false,
        toolbarHeight: 65,
        shape: Border(bottom: BorderSide(color: c.line)),
        title: Semantics(
          label: 'Hina',
          excludeSemantics: true,
          child: Row(children: [
            Text('hina', style: TextStyle(fontSize: 30, color: c.accent, height: 1)),
            const SizedBox(width: 6),
            Icon(Icons.local_florist, size: 20, color: c.accent),
          ]),
        ),
        actions: [
          _NavIcon(Icons.home_outlined, 'Trang chủ', Routes.home, route),
          _NavIcon(Icons.settings_outlined, 'Cài đặt', Routes.settings, route),
          const SizedBox(width: 13),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(23, 25, 23, 0),
            sliver: SliverList.list(children: children),
          ),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(23, 18, 23, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, a) in (actions ?? const <Widget>[]).indexed) ...[
                    if (i > 0) const SizedBox(height: 9),
                    a,
                  ],
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(this.icon, this.label, this.target, this.current);

  final IconData icon;
  final String label;
  final String target;
  final String current;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    final here = target == current;
    return IconButton(
      tooltip: label,
      isSelected: here,
      style: IconButton.styleFrom(
        backgroundColor: here ? c.accentSoft : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        minimumSize: const Size(48, 48), // vùng chạm tối thiểu cho TalkBack
      ),
      icon: Icon(icon, color: c.ink, size: 22),
      onPressed: here ? null : () => goTo(context, target),
    );
  }
}

/// Trang chủ là gốc; các trang khác nằm trên nó.
void goTo(BuildContext context, String route) {
  final nav = Navigator.of(context);
  if (route == Routes.home) {
    nav.pushNamedAndRemoveUntil(Routes.home, (_) => false);
  } else {
    nav.pushNamed(route);
  }
}

class HinaHeading extends StatelessWidget {
  const HinaHeading(this.title, {super.key, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final hint = this.hint;
    return Column(children: [
      Semantics(
        header: true,
        child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, height: 1.43)),
      ),
      if (hint != null) ...[
        const SizedBox(height: 13),
        Text(hint, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13.6, height: 1.76)),
      ],
    ]);
  }
}

enum ButtonKind { primary, secondary, ghost }

class HinaButton extends StatelessWidget {
  const HinaButton(this.label, {super.key, required this.onPressed, this.kind = ButtonKind.primary});

  final String label;
  final VoidCallback? onPressed;
  final ButtonKind kind;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    final (bg, fg) = switch (kind) {
      ButtonKind.primary => (c.accent, Colors.white),
      ButtonKind.secondary => (c.accentSoft, c.ink),
      ButtonKind.ghost => (Colors.transparent, c.ink),
    };
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: bg.withValues(alpha: 0.5),
        disabledForegroundColor: fg.withValues(alpha: 0.7),
        minimumSize: const Size.fromHeight(50),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontFamily: 'Quicksand', fontSize: 13.6),
        elevation: 0,
      ),
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}

/// Ô vuông bo góc chứa icon (hàng quyền, thẻ cài đặt, hộp thoại).
class SymbolBox extends StatelessWidget {
  const SymbolBox(this.icon, {super.key, this.size = 46, this.background});

  final IconData icon;
  final double size;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? c.accentSoft,
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Icon(icon, size: size / 2, color: c.ink),
    );
  }
}

/// Thẻ trắng viền hồng nhạt; bấm được nếu có onTap.
class HinaCard extends StatelessWidget {
  const HinaCard({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    final shape = RoundedRectangleBorder(
      side: BorderSide(color: c.line),
      borderRadius: BorderRadius.circular(18),
    );
    return Material(
      color: Colors.white,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Mặt cười Hina trên khối hồng nghiêng (màn giới thiệu).
class HinaFace extends StatelessWidget {
  const HinaFace({super.key, this.icon});

  final IconData? icon; // null = mặt cười

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    final icon = this.icon;
    return ExcludeSemantics(
      child: SizedBox(
        height: 265,
        child: Center(
          child: Transform.rotate(
            angle: -0.17,
            child: Container(
              width: 188,
              height: 188,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.elliptical(100, 92)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFF4F9), Color(0xFFF3D2E2)],
                ),
              ),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: 0.17,
                child: Container(
                  width: 119,
                  height: 119,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFAFD),
                    borderRadius: BorderRadius.circular(55),
                  ),
                  alignment: Alignment.center,
                  child: icon == null
                      ? CustomPaint(size: const Size(58, 44), painter: _Smile(c.accent))
                      : Icon(icon, size: 34, color: c.ink),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Smile extends CustomPainter {
  const _Smile(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = color;
    canvas.drawRRect(RRect.fromLTRBR(11, 7, 17, 18, const Radius.circular(3)), fill);
    canvas.drawRRect(RRect.fromLTRBR(41, 7, 47, 18, const Radius.circular(3)), fill);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(const Rect.fromLTWH(22, 18, 14, 14), 0.3, 2.5, false, stroke);
  }

  @override
  bool shouldRepaint(_Smile old) => old.color != color;
}

/// Hộp thoại kiểu Hina: icon, tiêu đề, mô tả, (hộp hướng dẫn), nút chính + "Để sau".
Future<bool> showHinaDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String text,
  required String confirm,
  String? guide,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x734E3745),
    builder: (context) {
      final c = HinaColors.of(context);
      return Dialog(
        backgroundColor: c.paper,
        insetPadding: const EdgeInsets.all(19),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 23, 20, 19),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: SymbolBox(icon, size: 57)),
              const SizedBox(height: 17),
              Semantics(
                header: true,
                child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 21, height: 1.4)),
              ),
              const SizedBox(height: 12),
              Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, height: 1.75)),
              const SizedBox(height: 19),
              if (guide != null) ...[
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(14)),
                  child: Text(guide, style: const TextStyle(fontSize: 12, height: 1.9)),
                ),
                const SizedBox(height: 17),
              ],
              HinaButton(confirm, onPressed: () => Navigator.pop(context, true)),
              const SizedBox(height: 8),
              HinaButton('Để sau', kind: ButtonKind.ghost, onPressed: () => Navigator.pop(context, false)),
            ],
          ),
        ),
      );
    },
  );
  return ok ?? false;
}
