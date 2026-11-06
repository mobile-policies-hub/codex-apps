import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_engine_api.dart';

SoundEngine createSoundEngine() => WebSoundEngine();

class WebSoundEngine implements SoundEngine {
  HTMLAudioElement? _audio;
  String? _url;
  void Function()? _onEnded;
  DateTime _ignoreEndedUntil = DateTime.fromMillisecondsSinceEpoch(0);
  int _token = 0;
  bool _shouldPlay = false;

  HTMLAudioElement _element() {
    final existing = _audio;
    if (existing != null) return existing;
    final audio = HTMLAudioElement()
      ..style.position = 'fixed'
      ..style.width = '0'
      ..style.height = '0';
    document.body?.append(audio);
    audio.addEventListener(
      'ended',
      ((Event _) {
        if (DateTime.now().isBefore(_ignoreEndedUntil)) return;
        if (audio.loop) return;
        _onEnded?.call();
      }).toJS,
    );
    _audio = audio;
    return audio;
  }

  @override
  void play(Uint8List bytes, {required bool loop, void Function()? onEnded}) {
    if (bytes.isEmpty) return;
    final token = ++_token;
    _shouldPlay = true;
    _onEnded = onEnded;
    _ignoreEndedUntil = DateTime.now().add(const Duration(milliseconds: 180));
    try {
      final blob = Blob([bytes.toJS].toJS, BlobPropertyBag(type: 'audio/wav'));
      final url = URL.createObjectURL(blob);
      final previous = _url;
      _url = url;
      final audio = _element()
        ..loop = loop
        ..volume = 0.85
        ..src = url;
      if (previous != null) URL.revokeObjectURL(previous);
      unawaited(_start(audio, token));
    } catch (_) {
      _onEnded = null;
      _shouldPlay = false;
    }
  }

  Future<void> _start(HTMLAudioElement audio, int token) async {
    try {
      await audio.play().toDart;
    } catch (_) {}
    if (token == _token || _shouldPlay) return;
    try {
      audio.loop = false;
      audio.pause();
      audio.removeAttribute('src');
    } catch (_) {}
  }

  @override
  void stop() {
    _token++;
    _shouldPlay = false;
    _onEnded = null;
    _silence(_audio);
  }

  void _silence(HTMLAudioElement? audio) {
    if (audio == null) return;
    try {
      audio.loop = false;
      audio.pause();
      audio.removeAttribute('src');
      audio.load();
    } catch (_) {}
  }

  @override
  void dispose() {
    stop();
    final url = _url;
    if (url != null) URL.revokeObjectURL(url);
    _url = null;
    _audio = null;
  }
}
