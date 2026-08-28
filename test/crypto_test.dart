import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloom/utils/crypto_util.dart';

void main() {
  group('CryptoUtil Tests', () {
    test('generatePairingCode generates 6-character alphanumeric string', () {
      final code = CryptoUtil.generatePairingCode();
      expect(code.length, equals(6));
      expect(RegExp(r'^[A-Z0-9]{6}$').hasMatch(code), isTrue);
    });

    test('generateDeviceId generates unique hex identifier', () {
      final id1 = CryptoUtil.generateDeviceId();
      final id2 = CryptoUtil.generateDeviceId();
      expect(id1.isNotEmpty, isTrue);
      expect(id1, isNot(equals(id2)));
    });

    test('encryptPayload and decryptPayload round-trip matches plaintext', () {
      const secret = 'bloom_test_secret_key_12345';
      final payload = {
        'cycles': [
          {'id': 1, 'startDate': 1700000000000, 'notes': 'Test cycle'},
        ],
        'notes': [
          {'id': 1, 'date': 1700000000000, 'content': 'Feeling good', 'mood': '😊'},
        ],
      };
      final plaintext = jsonEncode(payload);

      final encResult = CryptoUtil.encryptPayload(plaintext, secret);
      expect(encResult.containsKey('ciphertext'), isTrue);
      expect(encResult.containsKey('iv'), isTrue);
      expect(encResult['ciphertext'], isNot(equals(plaintext)));

      final decrypted = CryptoUtil.decryptPayload(
        encResult['ciphertext']!,
        encResult['iv']!,
        secret,
      );
      expect(decrypted, equals(plaintext));
      final decoded = jsonDecode(decrypted) as Map<String, dynamic>;
      expect(decoded['cycles'].length, equals(1));
      expect(decoded['notes'][0]['mood'], equals('😊'));
    });

    test('encryptPayload generates distinct IV and ciphertext for identical plaintext', () {
      const secret = 'shared_key_xyz';
      const text = 'secret period tracker data';

      final res1 = CryptoUtil.encryptPayload(text, secret);
      final res2 = CryptoUtil.encryptPayload(text, secret);

      expect(res1['iv'], isNot(equals(res2['iv'])));
      expect(res1['ciphertext'], isNot(equals(res2['ciphertext'])));
    });
  });
}
