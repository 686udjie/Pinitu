# Pinitu

A Flutter app that authenticates with Pinterest via an in-app WebView, extracts the user's cookies for authenticated requests, and displays the user's Pinterest home feed.

## Screenshots

### Homepage

<img width="739" height="1600" alt="Homepage" src="https://github.com/user-attachments/assets/3409e4cd-a0ad-42e8-b81d-f1a384cd5b59" />

### Search Page

<img width="739" height="1600" alt="Search Page" src="https://github.com/user-attachments/assets/5e8973ee-c340-4963-b1bc-3a7aac014b03" />
### Settings

<img width="739" height="1600" alt="Settings" src="https://github.com/user-attachments/assets/853c773e-38e9-4228-b264-b60db66e9b4f" />

# Status

The app, as it stands now, is functional and good enough for me. All the features I wanted are implemented. If there’s a feature you’d like, feel free to open an issue or submit a pull request. The only thing left for me to implement is the presets feature for iOS devices, which isn’t very crucial for me at the moment. Hopefully you can find value in this project!

# Stuff That Needs Improvement (Roadmap)

~~The image quality is very inconsistent. The goal is to achieve the same quality as what you find on Pinterest, which should be possible with the logic I currently have.~~ DONE

~~Image appearance: some images get cropped because I hardcoded the size of each element in the canvas. I need to add logic to make it dynamic because not every image has the same aspect ratio.~~ DONE

~~Once the image quality issue is solved, add a downloader. For now, I am aiming for images only, but video downloads will come later.~~ DONE

~~Add support for videos. This is already implemented, but during testing, no videos were shown. It needs more work.~~ DONE

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
