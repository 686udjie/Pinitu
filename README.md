# Pinitu

A Flutter app that authenticates with Pinterest via an in-app WebView, extracts the user's cookies for authenticated requests, and displays the user's Pinterest home feed.

# Status

The app, as it stands now, works but has no real use case. For now, it just displays the home feed of a user's Pinterest account. My goal for this project is similar to what you can find [here](https://github.com/Notsfsssf/pixez-flutter). I have tested this initial release on both iOS and Android; both should work (on emulators and actual `.ipa` and `.apk` files).

# Stuff That Needs Improvement (Roadmap)

- The image quality is very inconsistent. The goal is to achieve the same quality as what you find on Pinterest, which should be possible with the logic I currently have.

~~Image appearance: some images get cropped because I hardcoded the size of each element in the canvas. I need to add logic to make it dynamic because not every image has the same aspect ratio.~~ DONE

~~Once the image quality issue is solved, add a downloader. For now, I am aiming for images only, but video downloads will come later.~~ DONE (vids will come in the future)

- Add support for videos. This is already implemented, but during testing, no videos were shown. It needs more work.

~~Add a search feature.~~ DONE

~~Remove the logout button on the home feed and replace it with navigation buttons (e.g., settings, saved pins, etc.).~~ DONE

~~Add theme options (Material, dark/light mode sync with the system) and add color presets for iOS users because Material theming may not work properly on iOS.~~ DONE (partial, need to add presets for iOS)

# Build Instructions

## Dependencies

This project requires **Flutter** to be installed on your system

### Clone the Repository
```bash
git clone https://github.com/686udjie/Pinitu.git
cd pinitu
```

### Install Dependencies
```bash
flutter pub get
```

### Build for iOS
```bash
flutter build ios --release # add --no-codesign to leave it unsigned
```
This will generate an `.ipa` file in `build/ios/ipa/`

### Build for Android
```bash
flutter build apk --release
```
This will generate an `.apk` file in `build/app/outputs/flutter-apk/`

# Contributing

All contributions are wholeheartedly welcomed!
