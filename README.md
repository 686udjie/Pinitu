# Pinitu

A Flutter app that authenticates with Pinterest via an in-app WebView, extracts the user's cookies for authenticated requests, and displays the user's Pinterest home feed.

## Screenshots

| Homepage | Search Page | Settings |
|----------|-------------|----------|
| <img width="200" height="433" alt="Homepage" src="https://github.com/user-attachments/assets/3409e4cd-a0ad-42e8-b81d-f1a384cd5b59" /> | <img width="200" height="433" alt="Search Page" src="https://github.com/user-attachments/assets/5e8973ee-c340-4963-b1bc-3a7aac014b03" /> | <img width="200" height="433" alt="Settings" src="https://github.com/user-attachments/assets/853c773e-38e9-4228-b264-b60db66e9b4f" /> |
# Status

The app, as it stands now, is functional and good enough for me. All the features I wanted are implemented. If there’s a feature you’d like, feel free to open an issue or submit a pull request. The only thing left for me to implement is the presets feature for iOS devices, which isn’t very crucial for me at the moment. Hopefully you can find value in this project!

# Features

- High-quality image display
- Video playback support
- Image and video downloading support
- Search functionality
- Light/Dark mode support

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
