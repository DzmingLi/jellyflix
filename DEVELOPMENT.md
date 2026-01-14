# Development Guide

This project uses Nix flakes for reproducible development environments.

## Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- (Optional) [direnv](https://direnv.net/) for automatic environment loading

## Quick Start

### Choose Your Development Environment

We provide two development environments:

#### 1. **Minimal Environment** (Default, Recommended for most users)

For Linux desktop and Web development only - fast to set up, no Android SDK:

```bash
nix develop
# or
nix develop .#default
```

This provides:
- Flutter SDK
- Linux desktop development libraries (GTK3, GStreamer)
- Web development tools (Chromium)
- All build tools

Perfect for:
- Linux desktop development
- Web development
- Quick prototyping
- CI/CD pipelines

#### 2. **Full Environment** (Android + Linux + Web)

For Android development - includes the complete Android SDK:

```bash
nix develop .#full
```

This adds:
- Android SDK with platforms 31, 33, 34
- Build tools and platform tools
- Android NDK
- Android Emulator with Google Play Store images
- Java 17

### Option 3: Using direnv (Automatic)

If you have direnv installed:

```bash
direnv allow
```

The minimal environment will automatically load when you enter the project directory.

To use the full environment with direnv, edit `.envrc` and change the line to:
```bash
use flake .#full
```

## Available Commands

Once in the development environment:

```bash
# Check Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Run on different platforms
flutter run                    # Auto-detect device
flutter run -d linux           # Run on Linux desktop
flutter run -d chrome          # Run on web browser
flutter run -d <device-id>     # Run on specific Android device

# Build for different platforms
flutter build apk              # Build Android APK
flutter build appbundle        # Build Android App Bundle
flutter build linux            # Build Linux desktop app
flutter build web              # Build web app

# Development tools
flutter analyze                # Analyze code
flutter test                   # Run tests
flutter clean                  # Clean build artifacts
```

## Platform-Specific Notes

### Linux Desktop (Both Environments)

Both environments include all necessary GTK3 and GStreamer libraries for Linux desktop development.

### Android (Full Environment Only)

**Note:** Android development requires the full environment: `nix develop .#full`

The Android SDK is pre-configured with:
- Platform API levels: 31, 33, 34
- Build tools: 33.0.2, 34.0.0
- NDK version: 26.3.11579264
- Emulator support with Google Play Store images

To list connected devices:
```bash
adb devices
```

To use Android emulator:
```bash
flutter emulators
flutter emulators --launch <emulator_id>
```

### Web (Both Environments)

Chrome/Chromium is configured as the default browser for web development.

## Environment Comparison

| Feature | Minimal (`default`) | Full (`full`) |
|---------|---------------------|---------------|
| Flutter SDK | ✅ | ✅ |
| Linux Desktop | ✅ | ✅ |
| Web Support | ✅ | ✅ |
| Android SDK | ❌ | ✅ |
| Java/JDK | ❌ | ✅ (JDK 17) |
| Build Time | Fast (~2 min) | Slow (~15-30 min) |
| Disk Space | Small (~2 GB) | Large (~8-10 GB) |

## Troubleshooting

### Flutter Doctor Issues

Run `flutter doctor` to diagnose issues. Common fixes:

1. **Android licenses**: Accept all licenses
   ```bash
   flutter doctor --android-licenses
   ```

2. **Missing dependencies**: The Nix environment should provide everything, but if something is missing, check the `flake.nix` file.

### Build Issues

If you encounter build issues:

1. Clean the build directory:
   ```bash
   flutter clean
   flutter pub get
   ```

2. Exit and re-enter the Nix environment:
   ```bash
   exit
   nix develop
   ```

## Modifying the Environment

To add or change dependencies, edit `flake.nix` and run:

```bash
nix flake update  # Update flake.lock
nix develop       # Rebuild environment
```

## Contributing

When contributing, ensure:
1. Code follows Flutter style guidelines
2. All tests pass: `flutter test`
3. No analysis errors: `flutter analyze`
4. Commits follow conventional commit format
