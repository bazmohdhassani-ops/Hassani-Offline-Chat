# Firebase setup — Hassani Offline Chat

Firebase client initialization has been added to the Flutter app. This does **not** mean online messaging is finished yet.

## Required one-time console setup
1. In Firebase Console, open **Authentication → Sign-in method** and enable **Email/Password** (or choose the sign-in method implemented in a later app update).
2. Open **Firestore Database** and create a database in production mode.
3. Open **Storage** and enable it if media uploads are needed.
4. Publish `firestore.rules` and `storage.rules` from this repository in the matching Firebase console sections.

## Important
- Never use open rules such as `allow read, write: if true`.
- This app currently only initializes Firebase; it does not yet authenticate users or send/receive remote messages.
- Do not use this prototype for patient or confidential hospital information.
- The Firebase Android client configuration is not a server credential. Keep all data protected by Security Rules; never commit service-account private keys.
