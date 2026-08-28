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

    final image = generateLocalFloristAppIcon(size, isRound: isRound);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(img.encodePng(image));
    print('Generated: $path ($size x $size)');
  }
}

img.Image generateLocalFloristAppIcon(int size, {bool isRound = false}) {
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

  // Draw the crisp white local_florist lotus petals matching Settings page icon
  final white = img.ColorRgba8(255, 255, 255, 255);

  // Top center bud (pointy droplet)
  _drawPetal(image, center, center * 0.72, size * 0.09, size * 0.22, 0, white);
  // Center main body
  _drawPetal(image, center, center * 1.02, size * 0.13, size * 0.26, 0, white);
  // Left inner wing
  _drawPetal(image, center - size * 0.12, center * 0.96, size * 0.10, size * 0.22, -26, white);
  // Right inner wing
  _drawPetal(image, center + size * 0.12, center * 0.96, size * 0.10, size * 0.22, 26, white);
  // Left outer wing
  _drawPetal(image, center - size * 0.19, center * 1.08, size * 0.08, size * 0.18, -50, white);
  // Right outer wing
  _drawPetal(image, center + size * 0.19, center * 1.08, size * 0.08, size * 0.18, 50, white);

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

      final taper = 1.0 - (v / ry) * 0.35;
      final currentRx = rx * taper.clamp(0.3, 1.2);

      if ((u * u) / (currentRx * currentRx) + (v * v) / (ry * ry) <= 1.0) {
        if (image.getPixel(x, y).a > 0) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}
