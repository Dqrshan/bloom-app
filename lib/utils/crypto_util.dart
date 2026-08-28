import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;

class CryptoUtil {
  /// Derives a 32-byte AES key from a shared secret or pairing code
  static enc.Key deriveKey(String secret) {
    final bytes = utf8.encode(secret);
    final digest = sha256.convert(bytes);
    return enc.Key(Uint8List.fromList(digest.bytes));
  }

  /// Generates a random 16-byte IV
  static enc.IV generateIV() {
    final rand = Random.secure();
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return enc.IV(bytes);
  }

  /// Encrypts a plaintext string using AES-CBC with PKCS7 padding
  static Map<String, String> encryptPayload(String plaintext, String secret) {
    final key = deriveKey(secret);
    final iv = generateIV();
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    return {
      'ciphertext': encrypted.base64,
      'iv': iv.base64,
    };
  }

  /// Decrypts a base64 ciphertext with base64 IV using AES-CBC
  static String decryptPayload(String base64Ciphertext, String base64Iv, String secret) {
    final key = deriveKey(secret);
    final iv = enc.IV.fromBase64(base64Iv);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

    final encrypted = enc.Encrypted.fromBase64(base64Ciphertext);
    return encrypter.decrypt(encrypted, iv: iv);
  }

  /// Generates a secure random pairing code (6 alphanumeric characters)
  static String generatePairingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Generates a unique device ID
  static String generateDeviceId() {
    final rand = Random.secure();
    final bytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = rand.nextInt(256);
    }
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
