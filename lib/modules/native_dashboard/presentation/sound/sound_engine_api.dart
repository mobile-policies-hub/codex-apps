import 'dart:typed_data';

abstract class SoundEngine {
  void play(Uint8List bytes, {required bool loop, void Function()? onEnded});

  void stop();

  void dispose();
}
