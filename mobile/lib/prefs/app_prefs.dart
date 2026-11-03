import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccentColor { pink, rose, peach, lavender }

/// Cỡ chữ gốc (px) theo thiết kế: Nhỏ / Vừa / Lớn / XL.
enum FontSize {
  small('Nhỏ', 14),
  medium('Vừa', 16),
  large('Lớn', 19),
  xl('XL', 22);

  const FontSize(this.label, this.px);
  final String label;
  final double px;
}

/// Tuỳ chọn người dùng, lưu trên máy. Không chứa dữ liệu nhạy cảm.
class AppPrefs extends ChangeNotifier {
  AppPrefs._(this._store);

  static Future<AppPrefs> load() async =>
      AppPrefs._(await SharedPreferences.getInstance());

  final SharedPreferences _store;

  bool get onboarded => _store.getBool('onboarded') ?? false;
  AccentColor get color =>
      AccentColor.values.asNameMap()[_store.getString('color')] ?? AccentColor.pink;
  FontSize get fontSize =>
      FontSize.values.asNameMap()[_store.getString('fontSize')] ?? FontSize.medium;
  bool get highContrast => _store.getBool('highContrast') ?? false;
  bool get voiceGuide => _store.getBool('voiceGuide') ?? true;

  set onboarded(bool v) => _save(_store.setBool('onboarded', v));
  set color(AccentColor v) => _save(_store.setString('color', v.name));
  set fontSize(FontSize v) => _save(_store.setString('fontSize', v.name));
  set highContrast(bool v) => _save(_store.setBool('highContrast', v));
  set voiceGuide(bool v) => _save(_store.setBool('voiceGuide', v));

  // SharedPreferences cập nhật cache ngay khi gọi set; chỉ việc ghi đĩa là bất đồng bộ.
  void _save(Future<bool> write) {
    unawaited(write);
    notifyListeners();
  }
}
