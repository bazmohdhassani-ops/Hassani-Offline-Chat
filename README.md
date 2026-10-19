# Hassani Offline Chat — Android source v0.3

This package contains the Flutter source for the next test build.

## Included in this local prototype
- Create and open a new local conversation
- Type and display text messages in the open conversation
- Choose an image from the phone gallery and display it in the conversation
- Record a voice note, stop recording, and play it back
- Search the conversation list
- GitHub Actions workflow to build a debug APK

## Important limitations
This is still a **local prototype**, not yet a real device-to-device messenger. Messages, photos and audio are only displayed on the same phone and are not synchronized to another phone. Phone-number verification, Bluetooth/Wi-Fi Direct messaging, relaying between phones, persistence after closing the app, and whole-building coverage are not implemented. Do not use it for patient or other confidential information.

## Build the APK through GitHub Actions
1. Extract this ZIP on your computer.
2. In your GitHub repository, replace these files with the versions from this package:
   - `lib/main.dart`
   - `pubspec.yaml`
   - `.github/workflows/build-apk.yml`
   - `README.md`
3. Commit the changes to the `main` branch.
4. Open the repository's **Actions** tab and select **Build Android APK**.
5. Open the newest successful workflow run and download the artifact named `hassani-offline-chat-debug-apk`.
6. Extract the artifact ZIP. The `app-debug.apk` file inside is the Android installer.

The workflow creates Android platform files, adds microphone permissions, installs Flutter dependencies and builds the debug APK. The APK is not included in this source ZIP because a Flutter build has to run in GitHub Actions or on a computer with Flutter installed.
