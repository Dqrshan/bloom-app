// ignore_for_file: depend_on_referenced_packages, avoid_print
import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final files = [
    'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-hdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
    'android/app/src/main/res/mipmap-mdpi/ic_launcher_round.png',
    'android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png',
    'android/app/src/main/res/mipmap-xhdpi/ic_launcher_round.png',
    'android/app/src/main/res/mipmap-xxhdpi/ic_launcher_round.png',
    'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher_round.png',
  ];

  final sizeMap = {
    'mdpi': 48,
    'hdpi': 72,
    'xhdpi': 96,
    'xxhdpi': 144,
    'xxxhdpi': 192,
  };

  final sortedKeys = sizeMap.keys.toList()..sort((a, b) => b.length.compareTo(a.length));
  for (final path in files) {
    final density = sortedKeys.firstWhere((k) => path.contains(k));
    final size = sizeMap[density]!;
    final isRound = path.contains('_round');

    final image = generateBloomingFlowerAppIcon(size, isRound: isRound);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(image));
    print('Generated: $path ($size x $size)');
  }
}

img.Image generateBloomingFlowerAppIcon(int size, {bool isRound = false}) {
  final image = img.Image(width: size, height: size);
  final center = (size - 1) / 2.0;
  final radius = size * 0.46;
  final cornerRadius = isRound ? radius : size * 0.28;

  // Background: BloomColors.rose500 (#E05368) to rose600 (#C9184A) gradient
  for (int y = 0; y < size; y++) {
    final t = y / size;
    final r = (224 * (1 - t) + 201 * t).round();
    final g = (83 * (1 - t) + 24 * t).round();
    final b = (104 * (1 - t) + 74 * t).round();

    for (int x = 0; x < size; x++) {
      final dx = (x - center).abs();
      final dy = (y - center).abs();

      bool inside = false;
      if (isRound) {
        inside = (dx * dx + dy * dy) <= (radius * radius);
      } else {
        if (dx <= radius - cornerRadius || dy <= radius - cornerRadius) {
          inside = dx <= radius && dy <= radius;
        } else {
          final cdx = dx - (radius - cornerRadius);
          final cdy = dy - (radius - cornerRadius);
          inside = (cdx * cdx + cdy * cdy) <= (cornerRadius * cornerRadius);
        }
      }

      if (inside) {
        image.setPixelRgba(x, y, r, g, b, 255);
      } else {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  // Draw 5 Outer Radiant Blooming Petals
  final white = img.ColorRgba8(255, 255, 255, 255);
  final softPink = img.ColorRgba8(255, 240, 243, 220);
  final petalDist = size * 0.17;
  final petalRadiusX = size * 0.11;
  final petalRadiusY = size * 0.18;

  for (int i = 0; i < 5; i++) {
    final angleDeg = i * 72.0;
    final rad = angleDeg * pi / 180.0;
    final cx = center + petalDist * sin(rad);
    final cy = center - petalDist * cos(rad);
    _drawPetal(image, cx, cy, petalRadiusX, petalRadiusY, angleDeg, white);
  }

  // Draw 5 Inner Layer Petals (offset by 36 degrees)
  for (int i = 0; i < 5; i++) {
    final angleDeg = i * 72.0 + 36.0;
    final rad = angleDeg * pi / 180.0;
    final cx = center + (petalDist * 0.7) * sin(rad);
    final cy = center - (petalDist * 0.7) * cos(rad);
    _drawPetal(image, cx, cy, petalRadiusX * 0.8, petalRadiusY * 0.8, angleDeg, softPink);
  }

  // Draw Flower Center Core
  final coreRadius = size * 0.09;
  final coreColor = img.ColorRgba8(224, 83, 104, 255);
  final centerDotColor = img.ColorRgba8(255, 255, 255, 255);

  for (int y = (center - coreRadius).toInt(); y <= (center + coreRadius).toInt(); y++) {
    for (int x = (center - coreRadius).toInt(); x <= (center + coreRadius).toInt(); x++) {
      final d2 = (x - center) * (x - center) + (y - center) * (y - center);
      if (d2 <= coreRadius * coreRadius) {
        if (d2 <= (coreRadius * 0.45) * (coreRadius * 0.45)) {
          image.setPixel(x, y, centerDotColor);
        } else {
          image.setPixel(x, y, coreColor);
        }
      }
    }
  }

  return image;
}

void _drawPetal(img.Image image, double cx, double cy, double rx, double ry, double angleDeg, img.Color color) {
  final rad = angleDeg * pi / 180.0;
  final cosA = cos(rad);
  final sinA = sin(rad);

  final minX = (cx - max(rx, ry) * 1.5).clamp(0, image.width - 1).toInt();
  final maxX = (cx + max(rx, ry) * 1.5).clamp(0, image.width - 1).toInt();
  final minY = (cy - max(rx, ry) * 1.5).clamp(0, image.height - 1).toInt();
  final maxY = (cy + max(rx, ry) * 1.5).clamp(0, image.height - 1).toInt();

  for (int y = minY; y <= maxY; y++) {
    for (int x = minX; x <= maxX; x++) {
      final dx = x - cx;
      final dy = y - cy;

      final u = dx * cosA + dy * sinA;
      final v = -dx * sinA + dy * cosA;

      if ((u * u) / (rx * rx) + (v * v) / (ry * ry) <= 1.0) {
        if (image.getPixel(x, y).a > 0) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}
