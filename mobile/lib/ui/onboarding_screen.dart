import 'package:flutter/material.dart';
import 'package:hina_mobile/prefs/app_prefs.dart';
import 'package:hina_mobile/ui/theme.dart';
import 'package:hina_mobile/ui/widgets.dart';

const _pages = [
  (null, 'Mình là Hina,\nrất vui được gặp bạn.', 'Một người bạn nhỏ luôn sẵn sàng đồng hành cùng bạn.'),
  (Icons.mic_none, 'Bạn cứ nói,\nmình sẽ lắng nghe.', 'Đọc chữ, tìm đồ vật và mô tả những gì đang ở trước mặt.'),
  (Icons.favorite_border, 'Mỗi ngày một chút\ndễ dàng hơn.', 'Cùng chuẩn bị vài thiết lập nhỏ để bắt đầu nhé.'),
];

/// Ba trang giới thiệu, chuyển bằng nút (không vuốt) để TalkBack dùng dễ.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _index = 0;

  void _finish() {
    widget.prefs.onboarded = true;
    Navigator.of(context).pushReplacementNamed(Routes.permissions);
  }

  @override
  Widget build(BuildContext context) {
    final (icon, title, hint) = _pages[_index];
    final last = _index == _pages.length - 1;
    return HinaPage(
      route: '/onboarding',
      actions: [
        _Dots(index: _index, count: _pages.length),
        HinaButton(
          last ? 'Thiết lập Hina' : 'Tiếp tục',
          onPressed: last ? _finish : () => setState(() => _index++),
        ),
        HinaButton('Bỏ qua giới thiệu', kind: ButtonKind.ghost, onPressed: _finish),
      ],
      children: [
        HinaFace(icon: icon),
        HinaHeading(title, hint: hint),
      ],
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return Semantics(
      label: 'Trang ${index + 1} trên $count',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3.5),
                width: i == index ? 24 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == index ? c.accent : const Color(0xFFEDD8E2),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
