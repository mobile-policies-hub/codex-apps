import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_engine_api.dart';

SoundEngine createSoundEngine() => IoSoundEngine();

class IoSoundEngine implements SoundEngine {
  AudioPlayer? _player;
  StreamSubscription<void>? _complete;
  int _token = 0;
  int _callbackToken = -1;
  bool _shouldPlay = false;
  void Function()? _onEnded;
  File? _clip;

  static final _playback = AudioContext(
    iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
  );

  AudioPlayer? _ensure() {
    try {
      final player = _player ??= AudioPlayer();
      _complete ??= player.onPlayerComplete.listen((_) {
        if (_callbackToken != _token) return;
        final callback = _onEnded;
        _onEnded = null;
        callback?.call();
      });
      return player;
    } catch (_) {
      return null;
    }
  }

  @override
  void play(Uint8List bytes, {required bool loop, void Function()? onEnded}) {
    final player = _ensure();
    if (player == null) return;
    if (bytes.isEmpty) return;
    final token = ++_token;
    _shouldPlay = true;
    if (!loop && onEnded != null) {
      _onEnded = onEnded;
      _callbackToken = token;
    } else {
      _onEnded = null;
      _callbackToken = -1;
    }
    unawaited(_start(player, bytes, loop: loop, token: token));
  }

  Future<void> _start(
    AudioPlayer player,
    Uint8List bytes, {
    required bool loop,
    required int token,
  }) async {
    final clip = File('${Directory.systemTemp.path}/hybrid-sound-$token.wav');
    try {
      await clip.writeAsBytes(bytes, flush: true);
      if (token != _token) {
        await clip.delete();
        return;
      }
      await player.setAudioContext(_playback);
      await player.setReleaseMode(
        loop ? ReleaseMode.loop : ReleaseMode.release,
      );
      await player.setVolume(0.85);
      await player.play(DeviceFileSource(clip.path, mimeType: 'audio/wav'));
      final previous = _clip;
      _clip = clip;
      if (previous != null && previous.path != clip.path) {
        await previous.delete();
      }
    } catch (_) {
      try {
        await clip.delete();
      } catch (_) {}
    }
    if (token == _token || _shouldPlay) return;
    try {
      await player.stop();
    } catch (_) {}
  }

  @override
  void stop() {
    _token++;
    _shouldPlay = false;
    _onEnded = null;
    _callbackToken = -1;
    try {
      _player?.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    stop();
    _complete?.cancel();
    _complete = null;
    try {
      _player?.dispose();
    } catch (_) {}
    _player = null;
    final clip = _clip;
    _clip = null;
    if (clip != null) {
      try {
        clip.deleteSync();
      } catch (_) {}
    }
  }
}
