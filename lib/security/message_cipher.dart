import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// AES-256-GCM message payload helper.
///
/// The caller must obtain [keyBytes] through a secure key-establishment
/// protocol and protect it with platform secure storage. This class does not
/// distribute keys or, by itself, make the application end-to-end encrypted.
class MessageCipher {
  MessageCipher._();

  static final AesGcm _algorithm = AesGcm.with256bits();

  /// Generates 32 random bytes for a conversation key.
  /// Do not upload this key in plaintext to Firestore or Firebase Storage.
  static Future<Uint8List> generateConversationKey() async {
    final key = await _algorithm.newSecretKey();
    return Uint8List.fromList(await key.extractBytes());
  }

  /// Encrypts UTF-8 text. The authentication tag is appended to ciphertext
  /// so changes to the encrypted payload are detected during decryption.
  static Future<Map<String, String>> encryptText({
    required String plaintext,
    required List<int> keyBytes,
  }) async {
    _validateKey(keyBytes);
    final nonce = _algorithm.newNonce();
    final box = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
    );
    final combined = <int>[...box.cipherText, ...box.mac.bytes];
    return {
      'ciphertext': base64Encode(combined),
      'nonce': base64Encode(nonce),
    };
  }

  /// Decrypts a payload created by [encryptText]. Throws if tampered.
  static Future<String> decryptText({
    required String ciphertext,
    required String nonce,
    required List<int> keyBytes,
  }) async {
    _validateKey(keyBytes);
    final combined = base64Decode(ciphertext);
    final decodedNonce = base64Decode(nonce);
    if (decodedNonce.length != 12 || combined.length < 16) {
      throw const FormatException('Invalid encrypted message payload.');
    }
    final splitAt = combined.length - 16;
    final box = SecretBox(
      combined.sublist(0, splitAt),
      nonce: decodedNonce,
      mac: Mac(combined.sublist(splitAt)),
    );
    final clearBytes = await _algorithm.decrypt(
      box,
      secretKey: SecretKey(keyBytes),
    );
    return utf8.decode(clearBytes);
  }

  static void _validateKey(List<int> keyBytes) {
    if (keyBytes.length != 32) {
      throw ArgumentError('AES-256 requires a 32-byte conversation key.');
    }
  }
}