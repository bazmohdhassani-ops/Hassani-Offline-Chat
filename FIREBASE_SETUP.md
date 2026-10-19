# Firebase setup — Hassani Offline Chat

The current branch now contains an initial online messaging MVP:
- Email/password registration and login using Firebase Authentication.
- One shared Firestore chat room with live message updates.
- Text messages only. Photos, voice messages, calls, private chats, and offline device-to-device networking are not yet connected to the online backend.

## One-time Firebase Console setup
1. Open Firebase Console and select `hassani-offline-chat`.
2. Go to **Authentication → Sign-in method** and enable **Email/Password**.
3. Go to **Firestore Database → Create database** and create the database in production mode.
4. In **Firestore Database → Rules**, paste the contents of this repository's `firestore.rules` and click **Publish**.

## Testing
1. Install/build this branch on two Android phones.
2. On each phone, create a separate account using a different email and a password of at least 6 characters.
3. Send a message from one phone; it should appear in the shared room on the other phone when both have internet access.

## Important limitations
- The shared room is visible to every authenticated user of this app. Do not use it for private or confidential messages.
- Do not use this prototype for patient or confidential hospital information.
- Photos, voice-message uploads, calls, private/group conversations, and offline direct communication across a building still require implementation and testing.
- The Firebase Android client configuration is not a server credential. Never commit service-account private keys or use open rules such as `allow read, write: if true`.
