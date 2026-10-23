import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cryptography/cryptography.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../security/message_cipher.dart';

/// Firestore-backed direct-chat primitives.
///
/// This service stores encrypted message payloads only. The caller must obtain
/// the same conversation key on both devices using a real authenticated key
/// exchange and store it using platform secure storage. Never pass a key
/// downloaded from Firestore or hard-code a key in the application.
class PrivateChatService {
  PrivateChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _chats =>
      _firestore.collection('chats');

  String get _currentUid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in before opening a private chat.');
    }
    return user.uid;
  }

  /// Creates or returns the stable direct-chat ID for the signed-in user and
  /// [otherUid]. The other account UID must come from a trusted contact flow.
  Future<String> createOrGetDirectChat(String otherUid) async {
    final me = _currentUid;
    if (otherUid.trim().isEmpty || otherUid == me) {
      throw ArgumentError('Choose another valid user for a direct chat.');
    }

    final participants = [me, otherUid]..sort();
    final digest = await Sha256().hash(utf8.encode(participants.join(':')));
    final chatId = 'direct_${digest.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    final ref = _chats.doc(chatId);
    final existing = await ref.get();

    if (existing.exists) {
      final data = existing.data();
      final stored = (data?['participants'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList()
        ..sort();
      if (stored.length != 2 ||
          stored[0] != participants[0] ||
          stored[1] != participants[1] ||
          data?['type'] != 'direct') {
        throw StateError('The existing chat record is invalid.');
      }
      return chatId;
    }

    await ref.set({
      'participants': participants,
      'type': 'direct',
      'createdAt': FieldValue.serverTimestamp(),
    });
    return chatId;
  }

  /// Sends a text message encrypted with the conversation key.
  ///
  /// The key must be a securely established 32-byte AES key. This method does
  /// not perform key exchange and does not claim to provide complete E2EE by
  /// itself.
  Future<void> sendEncryptedText({
    required String chatId,
    required String plaintext,
    required List<int> conversationKey,
    int keyVersion = 1,
  }) async {
    final uid = _currentUid;
    final chat = await _chats.doc(chatId).get();
    final participants = (chat.data()?['participants'] as List<dynamic>? ?? const [])
        .map((value) => value.toString())
        .toList();

    if (!chat.exists || !participants.contains(uid)) {
      throw StateError('This account is not a member of that private chat.');
    }
    if (keyVersion < 1) {
      throw ArgumentError.value(keyVersion, 'keyVersion', 'Must be positive.');
    }

    final encrypted = await MessageCipher.encryptText(
      plaintext: plaintext,
      keyBytes: conversationKey,
    );

    await _chats.doc(chatId).collection('messages').add({
      'senderUid': uid,
      'ciphertext': encrypted['ciphertext'],
      'nonce': encrypted['nonce'],
      'createdAt': FieldValue.serverTimestamp(),
      'kind': 'text',
      'keyVersion': keyVersion,
    });
  }

  /// Streams encrypted records for a chat. Decryption must happen on-device.
  Stream<QuerySnapshot<Map<String, dynamic>>> watchEncryptedMessages(
    String chatId,
  ) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .limit(200)
        .snapshots();
  }

  /// Decrypts one record locally using the conversation key held by the caller.
  Future<String> decryptTextRecord({
    required Map<String, dynamic> record,
    required List<int> conversationKey,
  }) async {
    final ciphertext = record['ciphertext'];
    final nonce = record['nonce'];
    if (ciphertext is! String || nonce is! String) {
      throw const FormatException('Message does not contain an encrypted text payload.');
    }
    return MessageCipher.decryptText(
      ciphertext: ciphertext,
      nonce: nonce,
      keyBytes: conversationKey,
    );
  }
}
