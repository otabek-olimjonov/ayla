#!/usr/bin/env zsh
# =============================================================================
# Ayla – Android SDK setup + APK build
# Run: zsh scripts/setup_android_and_build.sh
# =============================================================================
set -e

export JAVA_HOME=/opt/homebrew/opt/openjdk@17
export PATH="$JAVA_HOME/bin:$PATH"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

SDKMANAGER=/opt/homebrew/bin/sdkmanager

echo "\n▶ Java version"
java -version

echo "\n▶ Accepting Android SDK licenses"
yes | $SDKMANAGER --sdk_root="$ANDROID_HOME" --licenses 2>&1 | grep -E "Accept|license" | tail -3

echo "\n▶ Installing SDK components (this may take a few minutes)"
$SDKMANAGER --sdk_root="$ANDROID_HOME" \
  "platform-tools" \
  "platforms;android-35" \
  "build-tools;35.0.0"

echo "\n▶ Telling Flutter where the SDK is"
flutter config --android-sdk "$ANDROID_HOME"

echo "\n▶ Flutter doctor"
flutter doctor --android-licenses 2>&1 | tail -5 || true
flutter doctor 2>&1

echo "\n▶ Building release APK"
cd /Users/otabek/Documents/startup/Ayla
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://wsvldokpfovenivinidq.supabase.co \
  "--dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indzdmxkb2twZm92ZW5pdmluaWRxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQzNjg3NzMsImV4cCI6MjA4OTk0NDc3M30.6cHBfFgJ84KRcwDN0PmmdYunAMpJYZibTbCub3r_V3c"

APK_PATH="build/ios/../android/../build/app/outputs/flutter-apk/app-release.apk"
ACTUAL=$(find build -name "app-release.apk" 2>/dev/null | head -1)
if [[ -f "$ACTUAL" ]]; then
  SIZE=$(du -sh "$ACTUAL" | cut -f1)
  echo "\n✅ APK built successfully!"
  echo "   Path: $ACTUAL"
  echo "   Size: $SIZE"
  echo "\n   Share via AirDrop or copy to phone:"
  echo "   open \$(dirname $ACTUAL)"
else
  echo "\n❌ APK not found – check errors above"
fi
