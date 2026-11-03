import 'package:flutter/material.dart';
import 'package:hina_mobile/app.dart';
import 'package:hina_mobile/audio/audio_capture.dart';
import 'package:hina_mobile/audio/audio_playback.dart';
import 'package:hina_mobile/camera/camera_manager.dart';
import 'package:hina_mobile/config.dart';
import 'package:hina_mobile/network/network_manager.dart';
import 'package:hina_mobile/permissions/device_permissions.dart';
import 'package:hina_mobile/prefs/app_prefs.dart';
import 'package:hina_mobile/session/session_controller.dart';
import 'package:hina_mobile/voice/voice_activation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await AppPrefs.load();
  runApp(
    HinaApp(
      prefs: prefs,
      controller: SessionController(
        network: HttpWsNetworkManager(serverUrl),
        camera: DeviceCameraManager(),
        capture: RecordAudioCapture(),
        playback: TtsAudioPlayback(),
        permissions: DevicePermissions(),
        voice: NoopVoiceActivation(),
      ),
    ),
  );
}
