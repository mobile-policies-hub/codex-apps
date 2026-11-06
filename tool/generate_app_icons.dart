import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Slices the three home-screen icons into every slot named in Contents.json.
///
/// When `tool/icon_masters/<brand>.png` exists, that file is the artwork.
/// Otherwise the script paints a simple fallback. Marketing icons are
/// 1024x1024 RGB. Apple rejects an alpha channel, so the PNG color type is 2.
///
/// Run from the project root: `dart run tool/generate_app_icons.dart`.
void main() {
  final ancient = _loadOrPaint('ancient', const _Rgb(26, 5, 5), _paintAncient);
  final zenith = _loadOrPaint('zenith', const _Rgb(11, 18, 32), _paintZenith);
  final apex = _loadOrPaint('apex', const _Rgb(7, 14, 28), _paintApex);

  _writeSet('AppIconAncient.appiconset', ancient);
  _writeSet('AppIconZenith.appiconset', zenith);
  _writeSet('AppIconApex.appiconset', apex);
  // The unused template set is still compiled with the catalog.
  _writeSet('AppIcon.appiconset', zenith);

  stdout.writeln('Wrote opaque app icons for Ancient, Zenith, and Apex.');
}

const int _side = 1024;

img.Image _loadOrPaint(String name, _Rgb backdrop, img.Image Function() paint) {
  final file = File('tool/icon_masters/$name.png');
  if (!file.existsSync()) return _rgb(paint());
  final decoded = img.decodePng(file.readAsBytesSync());
  if (decoded == null) return _rgb(paint());
  final flat = _flatten(decoded, backdrop);
  if (flat.width == _side && flat.height == _side) return flat;
  return _rgb(
    img.copyResize(
      flat,
      width: _side,
      height: _side,
      interpolation: img.Interpolation.cubic,
    ),
  );
}

img.Image _flatten(img.Image source, _Rgb backdrop) {
  final out = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  final hasAlpha = source.numChannels == 4;
  for (final pixel in source) {
    final alpha = hasAlpha ? pixel.a / 255 : 1.0;
    out.setPixelRgb(
      pixel.x,
      pixel.y,
      _mix(backdrop.r, pixel.r.toInt(), alpha),
      _mix(backdrop.g, pixel.g.toInt(), alpha),
      _mix(backdrop.b, pixel.b.toInt(), alpha),
    );
  }
  return out;
}

img.Image _canvas() => img.Image(width: _side, height: _side, numChannels: 3);

img.Image _paintAncient() {
  final image = _canvas();
  _gradient(image, _Rgb(7, 24, 51), _Rgb(22, 50, 92), diagonal: false);
  _glow(image, 512, 500, 460, _Rgb(224, 169, 59), 0.34);
  _roundRect(image, 300, 310, 724, 730, 16, _Rgb(246, 230, 195));
  _textLines(image, 380, 220, const [420, 490, 560, 620], _Rgb(176, 132, 62));
  _roundRect(image, 248, 214, 776, 368, 72, _Rgb(224, 169, 59));
  _roundRect(image, 270, 300, 754, 360, 18, _Rgb(184, 126, 28));
  _roundRect(image, 248, 656, 776, 810, 72, _Rgb(224, 169, 59));
  _roundRect(image, 290, 678, 734, 736, 16, _Rgb(245, 214, 130));
  img.fillCircle(
    image,
    x: 640,
    y: 520,
    radius: 34,
    color: img.ColorRgb8(224, 169, 59),
  );
  return image;
}

img.Image _paintZenith() {
  final image = _canvas();
  _gradient(image, _Rgb(11, 18, 32), _Rgb(20, 148, 128), diagonal: true);
  _glow(image, 512, 512, 420, _Rgb(52, 211, 153), 0.4);
  _ring(image, 512, 512, 286, 30, _Rgb(236, 253, 245));
  _ring(image, 512, 512, 196, 24, _Rgb(167, 243, 208));
  img.fillCircle(
    image,
    x: 512,
    y: 512,
    radius: 112,
    color: img.ColorRgb8(6, 78, 59),
    antialias: true,
  );
  const check = _Rgb(248, 250, 252);
  _stroke(image, 452, 518, 498, 572, 42, check);
  _stroke(image, 498, 572, 590, 448, 42, check);
  return image;
}

img.Image _paintApex() {
  final image = _canvas();
  _gradient(image, _Rgb(7, 14, 28), _Rgb(16, 28, 48), diagonal: false);
  img.fillCircle(
    image,
    x: 512,
    y: 512,
    radius: 360,
    color: img.ColorRgb8(18, 32, 56),
    antialias: true,
  );
  _plus(image, 512, 300, 340, 96, _Rgb(248, 250, 252));
  _times(image, 512, 548, 150, 64, _Rgb(255, 159, 28));
  _equals(image, 512, 760, 300, 52, 36, _Rgb(248, 250, 252));
  return image;
}

void _gradient(img.Image image, _Rgb from, _Rgb to, {required bool diagonal}) {
  final span = diagonal ? (_side * 2) - 2 : _side - 1;
  for (var y = 0; y < _side; y++) {
    for (var x = 0; x < _side; x++) {
      final t = (diagonal ? x + y : y) / span;
      image.setPixelRgb(
        x,
        y,
        _mix(from.r, to.r, t),
        _mix(from.g, to.g, t),
        _mix(from.b, to.b, t),
      );
    }
  }
}

void _glow(
  img.Image image,
  int cx,
  int cy,
  int radius,
  _Rgb color,
  double strength,
) {
  final radiusSquared = radius * radius;
  final x0 = math.max(0, cx - radius);
  final y0 = math.max(0, cy - radius);
  final x1 = math.min(_side - 1, cx + radius);
  final y1 = math.min(_side - 1, cy + radius);
  for (var y = y0; y <= y1; y++) {
    for (var x = x0; x <= x1; x++) {
      final dx = x - cx;
      final dy = y - cy;
      final distanceSquared = dx * dx + dy * dy;
      if (distanceSquared > radiusSquared) continue;
      final falloff = 1 - math.sqrt(distanceSquared) / radius;
      final amount = falloff * falloff * strength;
      final pixel = image.getPixel(x, y);
      image.setPixelRgb(
        x,
        y,
        _mix(pixel.r.toInt(), color.r, amount),
        _mix(pixel.g.toInt(), color.g, amount),
        _mix(pixel.b.toInt(), color.b, amount),
      );
    }
  }
}

void _roundRect(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  int radius,
  _Rgb color,
) {
  img.fillRect(
    image,
    x1: x1,
    y1: y1,
    x2: x2,
    y2: y2,
    radius: radius,
    color: img.ColorRgb8(color.r, color.g, color.b),
  );
}

void _textLines(
  img.Image image,
  int x1,
  int width,
  List<int> rows,
  _Rgb color,
) {
  for (final y in rows) {
    _roundRect(image, x1, y, x1 + width, y + 16, 8, color);
  }
}

void _ring(
  img.Image image,
  int cx,
  int cy,
  int radius,
  int thickness,
  _Rgb color,
) {
  final outer = radius.toDouble();
  final inner = (radius - thickness).toDouble();
  final pad = radius + 2;
  for (var y = cy - pad; y <= cy + pad; y++) {
    for (var x = cx - pad; x <= cx + pad; x++) {
      if (x < 0 || y < 0 || x >= _side || y >= _side) continue;
      final dx = x + 0.5 - cx;
      final dy = y + 0.5 - cy;
      final distance = math.sqrt(dx * dx + dy * dy);
      final coverage = math.min(
        (outer + 0.5 - distance).clamp(0.0, 1.0),
        (distance - (inner - 0.5)).clamp(0.0, 1.0),
      );
      if (coverage == 0) continue;
      _blend(image, x, y, color, coverage);
    }
  }
}

void _plus(
  img.Image image,
  int cx,
  int cy,
  int length,
  int thickness,
  _Rgb color,
) {
  final half = length ~/ 2;
  final bar = thickness ~/ 2;
  _roundRect(image, cx - half, cy - bar, cx + half, cy + bar, bar, color);
  _roundRect(image, cx - bar, cy - half, cx + bar, cy + half, bar, color);
}

void _times(
  img.Image image,
  int cx,
  int cy,
  int reach,
  int thickness,
  _Rgb color,
) {
  _stroke(
    image,
    cx - reach,
    cy - reach,
    cx + reach,
    cy + reach,
    thickness.toDouble(),
    color,
  );
  _stroke(
    image,
    cx - reach,
    cy + reach,
    cx + reach,
    cy - reach,
    thickness.toDouble(),
    color,
  );
}

void _equals(
  img.Image image,
  int cx,
  int cy,
  int width,
  int thickness,
  int gap,
  _Rgb color,
) {
  final half = width ~/ 2;
  final top = cy - gap ~/ 2 - thickness;
  _roundRect(
    image,
    cx - half,
    top,
    cx + half,
    top + thickness,
    thickness ~/ 2,
    color,
  );
  final bottom = cy + gap ~/ 2;
  _roundRect(
    image,
    cx - half,
    bottom,
    cx + half,
    bottom + thickness,
    thickness ~/ 2,
    color,
  );
}

img.Image _rgb(img.Image source) {
  if (source.numChannels == 3) return source;
  final copy = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  for (final pixel in source) {
    copy.setPixelRgb(pixel.x, pixel.y, pixel.r, pixel.g, pixel.b);
  }
  return copy;
}

void _writeSet(String setName, img.Image master) {
  final directory = Directory('ios/Runner/Assets.xcassets/$setName');
  final catalog = jsonDecode(
    File('${directory.path}/Contents.json').readAsStringSync(),
  );
  final slots = catalog['images'] as List<dynamic>;
  final sizes = <String, int>{};
  for (final slot in slots) {
    final entry = slot as Map<String, dynamic>;
    final filename = entry['filename'] as String?;
    if (filename == null) continue;
    sizes[filename] = _pixels(
      entry['size'] as String,
      entry['scale'] as String,
    );
  }

  for (final size in sizes.entries) {
    final resized = size.value == master.width
        ? master
        : img.copyResize(
            master,
            width: size.value,
            height: size.value,
            interpolation: img.Interpolation.average,
          );
    final rgb = _rgb(resized);
    final bytes = img.encodePng(rgb);
    _expectOpaque(bytes, size.value, '$setName/${size.key}');
    File('${directory.path}/${size.key}').writeAsBytesSync(bytes);
  }
  stdout.writeln('$setName: ${sizes.length} PNG files, marketing icon is RGB.');
}

int _pixels(String size, String scale) {
  final points = double.parse(size.split('x').first);
  final factor = int.parse(scale.replaceAll('x', ''));
  return (points * factor).round();
}

void _expectOpaque(List<int> bytes, int side, String label) {
  if (bytes.length < 26 || bytes[25] != 2) {
    throw StateError('$label must be a PNG without an alpha channel.');
  }
  final width = _uint32(bytes, 16);
  final height = _uint32(bytes, 20);
  if (width != side || height != side) {
    throw StateError('$label is ${width}x$height, expected ${side}x$side.');
  }
  var offset = 8;
  while (offset + 8 <= bytes.length) {
    final length = _uint32(bytes, offset);
    final type = String.fromCharCodes(bytes.sublist(offset + 4, offset + 8));
    if (type == 'tRNS') {
      throw StateError('$label contains a transparency chunk.');
    }
    if (type == 'IEND') return;
    offset += 12 + length;
  }
}

int _uint32(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

void _stroke(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  double thickness,
  _Rgb color,
) {
  final pad = (thickness / 2).ceil() + 2;
  final left = math.min(x1, x2) - pad;
  final right = math.max(x1, x2) + pad;
  final top = math.min(y1, y2) - pad;
  final bottom = math.max(y1, y2) + pad;
  final dx = (x2 - x1).toDouble();
  final dy = (y2 - y1).toDouble();
  final lengthSquared = dx * dx + dy * dy;
  final half = thickness / 2;
  for (var y = top; y <= bottom; y++) {
    for (var x = left; x <= right; x++) {
      if (x < 0 || y < 0 || x >= _side || y >= _side) continue;
      final px = x + 0.5 - x1;
      final py = y + 0.5 - y1;
      final t = lengthSquared == 0
          ? 0.0
          : ((px * dx + py * dy) / lengthSquared).clamp(0.0, 1.0);
      final distance = math.sqrt(
        math.pow(px - t * dx, 2) + math.pow(py - t * dy, 2),
      );
      final coverage = (half + 0.5 - distance).clamp(0.0, 1.0);
      if (coverage == 0) continue;
      _blend(image, x, y, color, coverage);
    }
  }
}

void _blend(img.Image image, int x, int y, _Rgb color, double amount) {
  final pixel = image.getPixel(x, y);
  image.setPixelRgb(
    x,
    y,
    _mix(pixel.r.toInt(), color.r, amount),
    _mix(pixel.g.toInt(), color.g, amount),
    _mix(pixel.b.toInt(), color.b, amount),
  );
}

int _mix(int from, int to, double t) => (from + (to - from) * t).round();

class _Rgb {
  const _Rgb(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;
}
