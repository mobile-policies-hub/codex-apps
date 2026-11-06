import 'dart:math' as math;
import 'dart:typed_data';

/// Original beds. Ambient loops run about half a minute so the repeat
/// is not a two-second tick.
class SoundClips {
  static const _rate = 22050;
  static final _rain = _loop(_rainSamples);
  static final _forest = _loop(_forestSamples);
  static final _noise = _loop(_noiseSamples);
  static final _bowl = _loop(_bowlSamples);
  static final _lessons = <String, Uint8List>{};
  static final _chime = _toneSequence(const [523, 659, 784], 0.16);
  static final _done = _toneSequence(const [784, 1046], 0.18);

  static Uint8List ambient(String name) {
    return switch (name) {
      'rain' => _rain,
      'forest' => _forest,
      'bowl' => _bowl,
      _ => _noise,
    };
  }

  static Uint8List lesson(String id) {
    return _lessons.putIfAbsent(id, () {
      final base = switch (id) {
        'scarab' => 196.0,
        'house' => 247.0,
        'incense' => 146.0,
        _ => 220.0,
      };
      return _loop(() => _padSamples(base, id));
    });
  }

  static Uint8List glyph(String reading) {
    const pitch = <String, double>{
      'a': 220,
      'e': 247,
      'i': 294,
      'o': 330,
      'u': 370,
      'r': 185,
      'n': 165,
      't': 440,
      'h': 494,
      'p': 349,
      'k': 392,
      'd': 155,
      'j': 147,
      'm': 208,
      's': 466,
      'l': 174,
      'w': 311,
      'y': 523,
    };
    final notes = [for (final char in reading.split('')) pitch[char] ?? 240];
    if (notes.isEmpty) return _chime;
    return _toneSequence(notes, 0.22);
  }

  static Uint8List chime() => _chime;

  static Uint8List focusDone() => _done;

  static Uint8List preset(String id) {
    final note = switch (id) {
      'mortgage' => 262.0,
      'deposit' => 330.0,
      'stake' => 392.0,
      _ => 494.0,
    };
    return _toneSequence([note, note * 1.25, note * 1.5], 0.11);
  }

  static Uint8List _loop(List<double> Function() build) {
    final samples = build();
    const fade = 2400;
    if (samples.length > fade * 2) {
      for (var i = 0; i < fade; i++) {
        final weight = i / fade;
        final tail = samples[samples.length - fade + i];
        samples[i] = samples[i] * weight + tail * (1 - weight);
        samples[samples.length - fade + i] *= 1 - weight;
      }
    }
    return _wav(samples);
  }

  static List<double> _rainSamples() {
    const seconds = 32;
    final length = _rate * seconds;
    final random = math.Random(4);
    final samples = List<double>.filled(length, 0);
    var hiss = 0.0;
    var body = 0.0;
    for (var i = 0; i < length; i++) {
      final t = i / _rate;
      final swell = _swell(t, 9.5, 17.0, 6.4).clamp(0.22, 1.0);
      final white = random.nextDouble() * 2 - 1;
      hiss = hiss * 0.78 + white * 0.22;
      body = body * 0.96 + white * 0.04;
      samples[i] = (hiss * 0.2 + body * 0.1) * swell;
      final chance = 0.003 + swell * 0.02;
      if (random.nextDouble() < chance) {
        _drop(samples, i, random, 0.18 + swell * 0.42);
      }
    }
    _rumble(samples, _at(6.2), 1.6, 31);
    _rumble(samples, _at(15.4), 2.1, 32);
    _rumble(samples, _at(24.8), 1.5, 33);
    return samples;
  }

  static List<double> _forestSamples() {
    const seconds = 32;
    final length = _rate * seconds;
    final random = math.Random(11);
    final samples = List<double>.filled(length, 0);
    var wind = 0.0;
    var leaves = 0.0;
    for (var i = 0; i < length; i++) {
      final t = i / _rate;
      final gust = _swell(t, 7.2, 13.5, 4.8).clamp(0.25, 1.0);
      final white = random.nextDouble() * 2 - 1;
      wind = wind * 0.985 + white * 0.015;
      leaves = leaves * 0.55 + white * 0.45;
      samples[i] = wind * 0.34 * gust + leaves * 0.035 * gust;
    }
    for (var n = 0; n < 22; n++) {
      final at = _at(0.8 + random.nextDouble() * 29);
      _bird(samples, at, random);
    }
    return samples;
  }

  static List<double> _noiseSamples() {
    const seconds = 24;
    final length = _rate * seconds;
    final random = math.Random(2);
    final samples = List<double>.filled(length, 0);
    var low = 0.0;
    var air = 0.0;
    for (var i = 0; i < length; i++) {
      final t = i / _rate;
      final color = (0.35 + 0.55 * _swell(t, 8.0, 14.0, 5.5)).clamp(0.2, 0.95);
      final white = random.nextDouble() * 2 - 1;
      low = low * (1 - color * 0.35) + white * color * 0.35;
      air = air * 0.2 + white * 0.8;
      final level = 0.72 + 0.28 * math.sin(2 * math.pi * t / 11);
      samples[i] = (air * 0.55 - low) * 0.2 * level;
    }
    return samples;
  }

  static List<double> _bowlSamples() {
    const seconds = 28;
    final length = _rate * seconds;
    final samples = List<double>.filled(length, 0);
    for (var i = 0; i < length; i++) {
      final t = i / _rate;
      final swell = 0.55 + 0.45 * _swell(t, 11.0, 17.0, 6.0);
      final fundamental = math.sin(2 * math.pi * 174 * t);
      final shimmer = math.sin(2 * math.pi * 176.4 * t);
      final ring = math.sin(2 * math.pi * 349 * t);
      samples[i] = (fundamental * 0.22 + shimmer * 0.16 + ring * 0.04) * swell;
    }
    return samples;
  }

  static List<double> _padSamples(double frequency, String id) {
    const seconds = 18;
    final length = _rate * seconds;
    final fifth = switch (id) {
      'incense' => 1.25,
      'house' => 2.0,
      'barque' => 1.5,
      _ => 1.498,
    };
    final samples = List<double>.filled(length, 0);
    for (var i = 0; i < length; i++) {
      final t = i / _rate;
      final drift = 1 + 0.008 * math.sin(2 * math.pi * t * 0.13);
      final breath = 0.62 + 0.38 * _swell(t, 6.0, 10.0, 3.5);
      final fundamental = math.sin(2 * math.pi * frequency * drift * t);
      final overtone = math.sin(2 * math.pi * frequency * fifth * t);
      samples[i] = (fundamental * 0.2 + overtone * 0.07) * breath;
    }
    return samples;
  }

  static double _swell(double time, double a, double b, double c) {
    return 0.5 +
        0.28 * math.sin(2 * math.pi * time / a) +
        0.14 * math.sin(2 * math.pi * time / b) +
        0.08 * math.sin(2 * math.pi * time / c);
  }

  static void _drop(
    List<double> samples,
    int at,
    math.Random random,
    double amp,
  ) {
    final tone = 700 + random.nextDouble() * 2400;
    final life = 160 + random.nextInt(260);
    for (var k = 0; k < life && at + k < samples.length; k++) {
      final env = math.exp(-k / (40 + amp * 30));
      samples[at + k] += math.sin(2 * math.pi * tone * k / _rate) * env * amp;
    }
  }

  static void _rumble(List<double> samples, int at, double seconds, int seed) {
    final random = math.Random(seed);
    final life = _at(seconds);
    var brown = 0.0;
    for (var i = 0; i < life && at + i < samples.length; i++) {
      final env = math.sin(math.pi * i / life);
      final white = random.nextDouble() * 2 - 1;
      brown = (brown * 0.96 + white * 0.04).clamp(-1.0, 1.0);
      samples[at + i] += brown * env * 0.7;
    }
  }

  static void _bird(List<double> samples, int at, math.Random random) {
    final notes = 1 + random.nextInt(3);
    final base = 1500 + random.nextDouble() * 1600;
    final fall = random.nextBool();
    var cursor = at;
    for (var n = 0; n < notes; n++) {
      final freq = base * (fall ? math.pow(0.86, n) : math.pow(1.12, n));
      final life = 700 + random.nextInt(900);
      for (var i = 0; i < life && cursor + i < samples.length; i++) {
        final env = math.sin(math.pi * i / life);
        samples[cursor + i] +=
            math.sin(2 * math.pi * freq * i / _rate) * env * 0.28;
      }
      cursor += life + 180 + random.nextInt(400);
    }
  }

  static int _at(double seconds) => (_rate * seconds).round();

  static Uint8List _toneSequence(List<double> notes, double seconds) {
    final noteLength = _at(seconds);
    final gap = _at(0.04);
    final samples = List<double>.filled(notes.length * (noteLength + gap), 0);
    for (var n = 0; n < notes.length; n++) {
      final start = n * (noteLength + gap);
      for (var i = 0; i < noteLength; i++) {
        final t = i / _rate;
        final env = math.sin(math.pi * i / noteLength);
        final attack = i < 120 ? i / 120 : 1.0;
        final fundamental = math.sin(2 * math.pi * notes[n] * t);
        final octave = math.sin(2 * math.pi * notes[n] * 2 * t);
        final fifth = math.sin(2 * math.pi * notes[n] * 1.5 * t);
        samples[start + i] =
            (fundamental * 0.42 + octave * 0.12 + fifth * 0.08) * env * attack;
      }
    }
    return _wav(samples);
  }

  static Uint8List _wav(List<double> samples) {
    final dataSize = samples.length * 2;
    final bytes = BytesBuilder();
    void text(String value) => bytes.add(value.codeUnits);
    void u32(int value) {
      bytes.add([
        value & 0xff,
        (value >> 8) & 0xff,
        (value >> 16) & 0xff,
        (value >> 24) & 0xff,
      ]);
    }

    void u16(int value) {
      bytes.add([value & 0xff, (value >> 8) & 0xff]);
    }

    text('RIFF');
    u32(36 + dataSize);
    text('WAVE');
    text('fmt ');
    u32(16);
    u16(1);
    u16(1);
    u32(_rate);
    u32(_rate * 2);
    u16(2);
    u16(16);
    text('data');
    u32(dataSize);
    for (final sample in samples) {
      final clamped = (sample * 32767).round().clamp(-32768, 32767);
      u16(clamped);
    }
    return bytes.toBytes();
  }
}
