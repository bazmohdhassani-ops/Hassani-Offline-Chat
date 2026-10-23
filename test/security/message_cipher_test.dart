import 'package:flutter_test/flutter_test.dart';
import 'package:lets_talk/security/message_cipher.dart';

void main() {
  group('MessageCipher', () {
    test('encrypts and decrypts a message', () async {
      final key = await MessageCipher.generateConversationKey();
      const message = 'سلام! Lets Talk';
      final encrypted = await MessageCipher.encryptText(
        plaintext: message,
        keyBytes: key,
      );
      expect(encrypted['ciphertext'], isNot(message));
      expect(
        await MessageCipher.decryptText(
          ciphertext: encrypted['ciphertext']!,
          nonce: encrypted['nonce']!,
          keyBytes: key,
        ),
        message,
      );
    });

    test('rejects a modified encrypted payload', () async {
      final key = await MessageCipher.generateConversationKey();
      final encrypted = await MessageCipher.encryptText(
        plaintext: 'secret',
        keyBytes: key,
      );
      await expectLater(
        MessageCipher.decryptText(
          ciphertext: '${encrypted['ciphertext']}A',
          nonce: encrypted['nonce']!,
          keyBytes: key,
        ),
        throwsA(anything),
      );
    });

    test('rejects a key of the wrong length', () async {
      await expectLater(
        MessageCipher.encryptText(plaintext: 'hi', keyBytes: [1, 2]),
        throwsArgumentError,
      );
    });
  });
}