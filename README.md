# Smart Shoe

This repository contains the Smart Shoe project, including firmware, mobile app, and supporting documentation.

## Structure

- `firmware/` — embedded firmware source and configuration for the shoe hardware.
- `mobile-app/` — Flutter mobile application and platform-specific project files.
- `docs/` — project documentation and design notes.
- `images/` — project images and visual assets.

## Getting Started

1. Open `mobile-app/smart_shoe/` in your IDE for the Flutter mobile app.
2. Open `firmware/` in PlatformIO or your embedded toolchain for firmware development.

## Notes

- The mobile app targets multiple platforms and uses Flutter.
- The firmware is built for the shoe's microcontroller and includes sensor/communication logic.
- Keep platform-specific dependencies updated in `android/`, `ios/`, `linux/`, `macos/`, `web/`, and `windows/` as needed.
