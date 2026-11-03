import 'package:flutter/material.dart';
import 'package:hina_mobile/prefs/app_prefs.dart';

// Bảng màu "Soft Pink" theo prototype: mọi chữ cùng một màu hồng nâu, Quicksand 400.
const _paper = Color(0xFFFFFBFD);
const _line = Color(0xFFF1E4EB);
const _ink = Color(0xFFAD8298); // ~3.2:1 trên nền: chỉ đạt AA cho chữ lớn
const _inkContrast = Color(0xFF725267); // ~6.5:1

const accents = {
  AccentColor.pink: (Color(0xFFD3A0B9), Color(0xFFFAEDF3)),
  AccentColor.rose: (Color(0xFFC896AB), Color(0xFFFAE9F0)),
  AccentColor.peach: (Color(0xFFCDA8A4), Color(0xFFFAEFEC)),
  AccentColor.lavender: (Color(0xFFB3A4CD), Color(0xFFF2EDFA)),
};

const accentNames = {
  AccentColor.pink: 'Hồng',
  AccentColor.rose: 'Hồng đất',
  AccentColor.peach: 'Đào',
  AccentColor.lavender: 'Oải hương',
};

@immutable
class HinaColors extends ThemeExtension<HinaColors> {
  const HinaColors({
    required this.paper,
    required this.line,
    required this.ink,
    required this.accent,
    required this.accentSoft,
  });

  final Color paper;
  final Color line;
  final Color ink;
  final Color accent; // nền nút chính, chữ trắng
  final Color accentSoft;

  static HinaColors of(BuildContext context) =>
      Theme.of(context).extension<HinaColors>() ?? fromPrefs(null);

  static HinaColors fromPrefs(AppPrefs? prefs) {
    final (accent, soft) = accents[prefs?.color ?? AccentColor.pink] ?? accents.values.first;
    final contrast = prefs?.highContrast ?? false;
    return HinaColors(
      paper: _paper,
      line: _line,
      ink: contrast ? _inkContrast : _ink,
      // Tối đi 35% để chữ trắng trên nút đạt >=4.5:1 ở cả 4 màu.
      accent: contrast ? Color.lerp(accent, Colors.black, 0.35) ?? accent : accent,
      accentSoft: soft,
    );
  }

  @override
  HinaColors copyWith() => this;

  @override
  HinaColors lerp(HinaColors? other, double t) => other ?? this;
}

ThemeData hinaTheme(AppPrefs prefs) {
  final c = HinaColors.fromPrefs(prefs);
  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Quicksand',
    scaffoldBackgroundColor: c.paper,
    colorScheme: ColorScheme.fromSeed(seedColor: c.accent, surface: c.paper),
    textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'Quicksand',
          bodyColor: c.ink,
          displayColor: c.ink,
        ),
    iconTheme: IconThemeData(color: c.ink),
    extensions: [c],
  );
}
