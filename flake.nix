{
  description = "Jellyflix - A Jellyfin client for multiple platforms";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        # Common dependencies for all platforms
        commonBuildInputs = with pkgs; [
          # Flutter and Dart
          flutter

          # Build tools
          git
          curl
          unzip
          xz
        ] ++ pkgs.lib.optionals pkgs.stdenv.isLinux [
          # Linux desktop development dependencies (only on Linux)
          pkg-config
          cmake
          ninja
          xdg-user-dirs

          # GTK and other GUI libraries for Linux
          gtk3
          glib
          pcre2
          util-linux
          libselinux
          libsepol
          libthai
          libdatrie
          libxkbcommon
          libepoxy
          at-spi2-core
          dbus

          # Required for Flutter plugins
          libsecret
          sysprof

          # Audio libraries
          alsa-lib
          libpulseaudio

          # X11 libraries
          xorg.libXdmcp
          xorg.libX11

          # Media libraries and dependencies
          libass
          gst_all_1.gstreamer
          gst_all_1.gst-plugins-base
          gst_all_1.gst-plugins-good
          gst_all_1.gst-plugins-bad
          gst_all_1.gst-plugins-ugly
          gst_all_1.gst-libav
          mpv
        ];

        # Common shell setup
        commonShellHook = ''
          # Flutter setup
          export FLUTTER_ROOT="${pkgs.flutter}"
          export PATH="$FLUTTER_ROOT/bin:$PATH"

          # Chrome for web development
          export CHROME_EXECUTABLE="${pkgs.chromium}/bin/chromium"

          ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            # Set up Flutter for Linux desktop development
            export PKG_CONFIG_PATH="${pkgs.gtk3}/lib/pkgconfig:${pkgs.glib.dev}/lib/pkgconfig:${pkgs.libepoxy}/lib/pkgconfig:${pkgs.libsecret}/lib/pkgconfig:${pkgs.sysprof.dev}/lib/pkgconfig:${pkgs.alsa-lib}/lib/pkgconfig:${pkgs.libass}/lib/pkgconfig:${pkgs.xorg.libXdmcp}/lib/pkgconfig:$PKG_CONFIG_PATH"

            # Set up XDG directories for path_provider plugin
            export XDG_DATA_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}"
            export XDG_CONFIG_HOME="''${XDG_CONFIG_HOME:-$HOME/.config}"
            export XDG_CACHE_HOME="''${XDG_CACHE_HOME:-$HOME/.cache}"

            # Initialize XDG user directories if not exists
            if [ ! -f "$HOME/.config/user-dirs.dirs" ]; then
              ${pkgs.xdg-user-dirs}/bin/xdg-user-dirs-update
            fi
          ''}

          # Disable Flutter analytics
          flutter config --no-analytics 2>/dev/null || true

          ${pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            # Enable Linux desktop
            flutter config --enable-linux-desktop 2>/dev/null || true
          ''}

          # Enable web
          flutter config --enable-web 2>/dev/null || true

          echo "🎬 Jellyflix development environment loaded!"
          echo "📱 Flutter version: $(flutter --version | head -n1)"
        '';

        # Linux-specific LD_LIBRARY_PATH
        linuxLibraryPath = pkgs.lib.optionalString pkgs.stdenv.isLinux (
          pkgs.lib.makeLibraryPath [
            pkgs.gtk3
            pkgs.glib
            pkgs.pcre2
            pkgs.util-linux
            pkgs.libselinux
            pkgs.libsepol
            pkgs.libthai
            pkgs.libdatrie
            pkgs.libxkbcommon
            pkgs.libepoxy
            pkgs.at-spi2-core
            pkgs.dbus
            pkgs.libsecret
            pkgs.sysprof
            pkgs.alsa-lib
            pkgs.libpulseaudio
            pkgs.xorg.libXdmcp
            pkgs.xorg.libX11
            pkgs.libass
            pkgs.gst_all_1.gstreamer
            pkgs.gst_all_1.gst-plugins-base
            pkgs.mpv
          ]
        );

        # Android SDK configuration (only for full environment)
        androidComposition = pkgs.androidenv.composeAndroidPackages {
          cmdLineToolsVersion = "11.0";
          toolsVersion = "26.1.1";
          platformToolsVersion = "35.0.1";
          buildToolsVersions = [ "34.0.0" "33.0.2" ];
          includeEmulator = true;
          emulatorVersion = "34.2.16";
          platformVersions = [ "34" "33" "31" ];
          includeSources = false;
          includeSystemImages = true;
          systemImageTypes = [ "google_apis_playstore" ];
          abiVersions = [ "x86_64" "arm64-v8a" ];
          cmakeVersions = [ "3.22.1" ];
          includeNDK = true;
          ndkVersions = [ "26.3.11579264" ];
          useGoogleAPIs = false;
          useGoogleTVAddOns = false;
          includeExtras = [
            "extras;google;gcm"
          ];
        };

        androidSdk = androidComposition.androidsdk;

      in
      {
        # Default: Minimal environment for Linux and Web development
        devShells.default = pkgs.mkShell {
          buildInputs = commonBuildInputs;

          shellHook = commonShellHook + ''
            echo ""
            echo "💡 Minimal environment (Linux + Web only)"
            echo "   For Android development, use: nix develop .#full"
            echo ""
            echo "Available commands:"
            echo "  flutter doctor        - Check Flutter installation"
            echo "  flutter run -d linux  - Run on Linux desktop"
            echo "  flutter run -d chrome - Run on web (Chrome)"
            echo "  flutter build linux   - Build Linux desktop app"
            echo "  flutter pub get       - Get dependencies"
            echo ""
          '';

          LD_LIBRARY_PATH = linuxLibraryPath;
        };

        # Full environment with Android SDK
        devShells.full = pkgs.mkShell {
          buildInputs = commonBuildInputs ++ (with pkgs; [
            # Android development
            androidSdk
            jdk17
          ]);

          shellHook = commonShellHook + ''
            # Android SDK setup
            export ANDROID_HOME="${androidSdk}/libexec/android-sdk"
            export ANDROID_SDK_ROOT="$ANDROID_HOME"
            export ANDROID_NDK_ROOT="$ANDROID_HOME/ndk-bundle"

            # Add Android tools to PATH
            export PATH="$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"

            # Java setup
            export JAVA_HOME="${pkgs.jdk17}"

            echo "☕ Java version: $(java -version 2>&1 | head -n1)"
            echo "🤖 Android SDK: $ANDROID_HOME"
            echo ""
            echo "📦 Full environment (Linux + Web + Android)"
            echo ""
            echo "Available commands:"
            echo "  flutter doctor        - Check Flutter installation"
            echo "  flutter run           - Run the app"
            echo "  flutter run -d linux  - Run on Linux desktop"
            echo "  flutter run -d chrome - Run on web (Chrome)"
            echo "  flutter build apk     - Build Android APK"
            echo "  flutter build linux   - Build Linux desktop app"
            echo "  flutter pub get       - Get dependencies"
            echo ""
          '';

          LD_LIBRARY_PATH = linuxLibraryPath;
        };

        # Optional: Add a formatter
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
