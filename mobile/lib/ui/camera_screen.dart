import 'package:flutter/material.dart';
import 'package:hina_mobile/camera/camera_manager.dart';
import 'package:hina_mobile/ui/widgets.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key, required this.camera});

  final CameraManager camera;

  @override
  Widget build(BuildContext context) {
    return HinaPage(
      route: Routes.camera,
      actions: [
        HinaButton('Ghi âm câu hỏi', onPressed: () => Navigator.of(context).pushReplacementNamed(Routes.record)),
        HinaButton('Về trang chủ', kind: ButtonKind.ghost, onPressed: () => goTo(context, Routes.home)),
      ],
      children: [
        const SizedBox(height: 14),
        const HinaHeading(
          'Hina đang nhìn cùng bạn.',
          hint: 'Hướng camera đến điều bạn muốn quan sát.',
        ),
        const SizedBox(height: 18),
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 275,
              color: const Color(0xFFF5E7ED),
              child: Stack(fit: StackFit.expand, children: [
                Center(child: camera.preview()),
                // Khung ngắm: gợi ý đặt vật cần xem vào giữa.
                FractionallySizedBox(
                  widthFactor: 0.58,
                  heightFactor: 0.45,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Hina vẫn cảnh báo vật cản kể cả khi bạn không hỏi.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
