import 'package:flutter/material.dart';
import 'package:hina_mobile/session/session_controller.dart';
import 'package:hina_mobile/ui/theme.dart';
import 'package:hina_mobile/ui/widgets.dart';

const _features = [
  (Icons.article_outlined, 'Đọc văn bản'),
  (Icons.image_outlined, 'Mô tả cảnh vật'),
  (Icons.help_outline, 'Hỏi về cảnh vật'),
  (Icons.logout, 'Kết thúc trò chuyện'),
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.controller});

  final SessionController controller;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return HinaPage(
      route: Routes.home,
      children: [
        const SizedBox(height: 18),
        // Chỉ thay câu phụ khi có vấn đề (mất mạng, thiếu quyền) để người dùng biết vì sao.
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => HinaHeading(
            'Hôm nay bạn cần\nmình giúp gì?',
            hint: switch (controller.state) {
              SessionState.ready || SessionState.listening || SessionState.waiting =>
                'Hina luôn ở đây để lắng nghe.',
              _ => controller.message,
            },
          ),
        ),
        const SizedBox(height: 23),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF0F6), Color(0xFFF6DCE9)],
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            ExcludeSemantics(
              child: Row(children: [
                const SymbolBox(Icons.mic_none, size: 51, background: Colors.white),
                const SizedBox(width: 13),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gọi Hina nhé!', style: TextStyle(fontSize: 13.8)),
                  Text('Bắt đầu trò chuyện', style: TextStyle(fontSize: 11.8, color: c.ink)),
                ]),
              ]),
            ),
            const SizedBox(height: 17),
            HinaButton('Bắt đầu trò chuyện', onPressed: () async {
              if (controller.state == SessionState.ended) await controller.startNewSession();
              if (context.mounted) goTo(context, Routes.record);
            }),
          ]),
        ),
        const SizedBox(height: 23),
        const Text('Hina có thể giúp bạn', style: TextStyle(fontSize: 14)),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.45,
          children: [
            for (final (icon, label) in _features)
              Semantics(
                button: true,
                label: '$label, mở camera',
                excludeSemantics: true,
                child: HinaCard(
                  onTap: () => goTo(context, Routes.camera),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, size: 25, color: c.ink),
                      Text(label, style: const TextStyle(fontSize: 13.8)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        HinaCard(
          onTap: () => goTo(context, Routes.camera),
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            const SymbolBox(Icons.photo_camera_outlined),
            const SizedBox(width: 12),
            const Expanded(child: Text('Mở camera', style: TextStyle(fontSize: 13.8))),
            Icon(Icons.chevron_right, color: c.ink),
          ]),
        ),
      ],
    );
  }
}
