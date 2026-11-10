import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:hina_mobile/audio/audio_capture.dart';
import 'package:hina_mobile/audio/audio_playback.dart';
import 'package:hina_mobile/camera/camera_manager.dart';
import 'package:hina_mobile/network/network_manager.dart';
import 'package:hina_mobile/network/server_event.dart';
import 'package:hina_mobile/permissions/device_permissions.dart';

class FakeNetwork implements NetworkManager {
  final _controller = StreamController<ServerEvent>.broadcast();
  final sent = <String>[];
  bool connected = false;
  int connects = 0;
  bool endSessionCalled = false;

  @override
  Stream<ServerEvent> get events => _controller.stream;
  @override
  bool get isConnected => connected;
  @override
  Future<void> connect() async => connects++;
  @override
  void sendAudio(int requestId, Uint8List pcm) => sent.add('audio:$requestId');
  @override
  void sendImage(int frameId, Uint8List jpeg) => sent.add('image:$frameId');
  @override
  Future<void> endSession() async {
    endSessionCalled = true;
    connected = false;
  }

  @override
  Future<void> close() async {}

  void emit(ServerEvent event) {
    if (event is ConnectedEvent) connected = true;
    if (event is DisconnectedEvent) connected = false;
    _controller.add(event);
  }
}

class FakeCamera implements CameraManager {
  @override
  Future<void> start() async {}
  @override
  Future<Uint8List?> capture() async => Uint8List.fromList([9]);
  @override
  Widget preview() => const SizedBox.shrink();
  @override
  Future<void> stop() async {}
}

class FakeCapture implements AudioCapture {
  @override
  Future<void> start() async {}
  @override
  Future<Uint8List> stop() async => Uint8List.fromList([1, 2, 3]);
}

class FakePlayback implements AudioPlayback {
  final spoken = <String>[];
  final played = <int>[];
  Object? playError;

  @override
  Future<void> play(Uint8List mp3) async {
    played.add(mp3.length);
    if (playError case final e?) throw e;
  }

  @override
  Future<void> speak(String text) async => spoken.add(text);
  @override
  Future<void> stop() async {}
}

class FakePermissions implements Permissions {
  FakePermissions(this.onCheck, this.onRequest);
  PermissionResult onCheck;
  PermissionResult onRequest;
  int settingsOpened = 0;

  @override
  Future<PermissionResult> check() async => onCheck;
  @override
  Future<PermissionResult> request() async => onRequest;
  @override
  Future<PermissionResult> statusOf(AppPermission p) async => onCheck;
  @override
  Future<PermissionResult> requestOf(AppPermission p) async => onRequest;
  @override
  Future<void> openSettings() async => settingsOpened++;
}
