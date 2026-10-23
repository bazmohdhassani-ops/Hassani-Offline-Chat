# Hassani Offline Chat — Android messaging MVP

This Flutter source now includes an initial Firebase-backed online messaging flow.

## Included in this branch
- Email/password account registration and login.
- One shared live text chat room backed by Cloud Firestore.
- Local prototype code for selecting images and recording/playing voice notes.
- GitHub Actions workflow that automatically attempts to build a debug APK when this branch changes.

## Important limitations
- The Firebase online room currently supports text messages only.
- The shared room is readable by every authenticated user of this app; it is not private.
- Online photo/audio/file transfer, private and group chats, read receipts, contacts, phone-number verification, voice/video calls, and offline phone-to-phone networking are not implemented yet.
- Do not use this prototype for patient or other confidential hospital information.

## Firebase setup required once
1. In Firebase Console, select project hassani-offline-chat.
2. Open **Authentication → Sign-in method** and enable **Email/Password**.
3. Open **Firestore Database** and create a database in production mode.
4. In **Firestore Database → Rules**, publish the exact rules from this repository's firestore.rules.

The rules in the repository do not become active in Firebase until you publish them in the Firebase Console.

## Test the online text room
1. Install the APK from a successful GitHub Actions run.
2. On each of two phones, create a different account with an email and a password of at least 6 characters.
3. Send a text message; with both phones online, it should appear in the same shared room.

## APK build
The workflow at .github/workflows/build-apk.yml runs on pushes to feature/full-messaging-foundation. Open the repository's **Actions** tab, select the latest **Build Android APK** run, and download the artifact named hassani-offline-chat-apk if the run succeeds.

## Encryption work in progress
- `lib/security/message_cipher.dart` now provides AES-256-GCM encryption/decryption for text payloads, with an authentication tag and nonce.
- Unit tests cover round-trip encryption, tampering rejection, and key-length validation.
- **This is not yet end-to-end encryption in the running app.** Secure contact key exchange, protected key storage, and wiring the cipher into private-chat send/receive still need implementation and device testing. Do not treat the current app as a secure private messenger yet.
