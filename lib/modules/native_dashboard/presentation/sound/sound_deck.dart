import 'package:flutter/foundation.dart';

import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_engine.dart';
import 'package:hybrid_app/modules/native_dashboard/presentation/sound/sound_engine_api.dart';

/// One output for every brand. Starting a clip always stops the previous one.
class SoundDeck extends ChangeNotifier {
  SoundDeck({SoundEngine? engine}) : _engine = engine ?? createSoundEngine();

  final SoundEngine _engine;
  String? nowPlaying;
  bool looping = false;
  int _generation = 0;

  void playLoop(String id, Uint8List bytes) {
    if (bytes.isEmpty) return;
    _generation++;
    nowPlaying = id;
    looping = true;
    _engine.play(bytes, loop: true);
    notifyListeners();
  }

  void playOnce(String id, Uint8List bytes) {
    if (bytes.isEmpty) return;
    final generation = ++_generation;
    nowPlaying = id;
    looping = false;
    _engine.play(
      bytes,
      loop: false,
      onEnded: () {
        if (generation != _generation || nowPlaying != id) return;
        nowPlaying = null;
        notifyListeners();
      },
    );
    notifyListeners();
  }

  void stop() {
    _generation++;
    nowPlaying = null;
    looping = false;
    _engine.stop();
    notifyListeners();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }
}
