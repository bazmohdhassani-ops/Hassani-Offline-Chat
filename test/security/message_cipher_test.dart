import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lets_talk/security/message_cipher.dart';

void main() {
  group('MessageCipher', () {
    late List<int> key;

    setUp(() {
      key = List<int>.generate(32, (index) => index);
    });

    test('round-trips UTF-8 text', () async {
      const message = 'سلام! Lets Talk 🔐';
      final encrypted = await MessageCipher.encryptText(plaintext: message, keyBytes: key);
      expect(encrypted['ciphertext'], isNot(message));
      expect(await MessageCipher.decryptText(
        ciphertext: encrypted['ciphertext']!,
        nonce: encrypted['nonce']!,
        keyBytes: key,
      ), message);
    });

    test('rejects keys that are not 32 bytes', () async {
      await expectLater(
        MessageCipher.encryptText(plaintext: 'hello', keyBytes: [1, 2, 3]),
        throwsArgumentError,
      );
    });

    test('rejects a modified encrypted payload', () async {
      final encrypted = await MessageCipher.encryptText(plaintext: 'private message', keyBytes: key);
      final bytes = base64Decode(encrypted['ciphertext']!);
      bytes[0] ^= 1;
      await expectLater(
        MessageCipher.decryptText(
          ciphertext: base64Encode(bytes),
          nonce: encrypted['nonce']!,
          keyBytes: key,
        ),
        throwsA(anything),
      );
    });

    test('rejects a different key', () async {
      final encrypted = await MessageCipher.encryptText(plaintext: 'private message', keyBytes: key);
      final otherKey = List<int>.generate(32, (index) => 255 - index);
      await expectLater(
        MessageCipher.decryptText(
          ciphertext: encrypted['ciphertext']!,
          nonce: encrypted['nonce']!,
          keyBytes: otherKey,
        ),
        throwsA(anything),
      );
    });
  });
}
