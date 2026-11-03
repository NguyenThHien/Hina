import 'package:flutter/material.dart';
import 'package:hina_mobile/prefs/app_prefs.dart';
import 'package:hina_mobile/ui/theme.dart';
import 'package:hina_mobile/ui/widgets.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.prefs});

  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return ListenableBuilder(
      listenable: prefs,
      builder: (context, _) => HinaPage(
        route: Routes.settings,
        children: [
          const SizedBox(height: 17),
          const HinaHeading('Hina theo cách bạn thích.'),
          const SizedBox(height: 23),
          HinaCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Màu giao diện', style: TextStyle(fontSize: 13.8)),
              const SizedBox(height: 12),
              Wrap(spacing: 6, children: [
                for (final color in AccentColor.values) _Swatch(color: color, prefs: prefs),
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          HinaCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Cỡ chữ', style: TextStyle(fontSize: 13.8)),
              const SizedBox(height: 11),
              Row(children: [
                for (final (i, size) in FontSize.values.indexed) ...[
                  if (i > 0) const SizedBox(width: 7),
                  Expanded(child: _SizeChip(size: size, prefs: prefs)),
                ],
              ]),
            ]),
          ),
          const SizedBox(height: 14),
          _Toggle(
            icon: Icons.contrast,
            title: 'Độ tương phản cao',
            subtitle: 'Giúp chữ dễ đọc hơn',
            value: prefs.highContrast,
            onChanged: (v) => prefs.highContrast = v,
          ),
          const SizedBox(height: 14),
          _Toggle(
            icon: Icons.mic_none,
            title: 'Hướng dẫn bằng giọng nói',
            subtitle: 'Đọc trạng thái như "Sẵn sàng". Câu trả lời và cảnh báo luôn được đọc.',
            value: prefs.voiceGuide,
            onChanged: (v) => prefs.voiceGuide = v,
          ),
          const SizedBox(height: 14),
          HinaCard(
            onTap: () => goTo(context, Routes.permissions),
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              const SymbolBox(Icons.photo_camera_outlined),
              const SizedBox(width: 12),
              const Expanded(child: Text('Quản lý quyền truy cập', style: TextStyle(fontSize: 13.8))),
              Icon(Icons.chevron_right, color: c.ink),
            ]),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.color, required this.prefs});

  final AccentColor color;
  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final selected = prefs.color == color;
    final (fill, _) = accents[color] ?? accents.values.first;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Màu ${accentNames[color]}',
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => prefs.color = color,
        radius: 24,
        child: SizedBox.square(
          dimension: 48, // vùng chạm 48, chấm màu 33 như thiết kế
          child: Center(
            child: Container(
              width: 33,
              height: 33,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: selected ? const Color(0xFFB982A2) : const Color(0xFFE5CEDC),
                    spreadRadius: selected ? 2 : 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.size, required this.prefs});

  final FontSize size;
  final AppPrefs prefs;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    final selected = prefs.fontSize == size;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Cỡ chữ ${size.label}',
      excludeSemantics: true,
      child: Material(
        color: selected ? c.accentSoft : Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.line),
          borderRadius: BorderRadius.circular(11),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: () => prefs.fontSize = size,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(child: Text(size.label, style: const TextStyle(fontSize: 12))),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = HinaColors.of(context);
    return MergeSemantics(
      child: HinaCard(
        onTap: () => onChanged(!value),
        child: Row(children: [
          SymbolBox(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 13.8)),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(fontSize: 11.8, height: 1.5)),
            ]),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: c.accent,
            inactiveTrackColor: const Color(0xFFE4D4DC),
            thumbColor: const WidgetStatePropertyAll(Colors.white),
            trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
          ),
        ]),
      ),
    );
  }
}
