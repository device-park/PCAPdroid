#!/bin/bash
# PCAPdroid Headless - APK üretir (com.emanuelef.remote_capture.headless.debug)
# Çıktı: releases/pcapdroid-headless.apk

set -euo pipefail

cd "$(dirname "$0")"

APK="app/build/outputs/apk/headless/debug/app-headless-debug.apk"
OUT="releases/pcapdroid-headless.apk"

# --- Android SDK bul ---
for dir in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" \
           "$HOME/Library/Android/sdk" \
           "/opt/homebrew/share/android-commandlinetools" \
           "/usr/local/share/android-commandlinetools"; do
    if [ -n "$dir" ] && [ -d "$dir/platforms" ]; then
        export ANDROID_HOME="$dir"
        export ANDROID_SDK_ROOT="$dir"
        break
    fi
done

if [ -z "${ANDROID_HOME:-}" ]; then
    echo "HATA: Android SDK bulunamadı. ANDROID_HOME ayarlayın." >&2
    exit 1
fi
echo "==> SDK: $ANDROID_HOME"

# --- Native kod submodule'leri ---
if [ ! -f submodules/zdtun/CMakeLists.txt ]; then
    echo "==> Submodule'ler çekiliyor..."
    git submodule update --init --recursive
fi

echo "==> ./gradlew assembleHeadlessDebug"
./gradlew assembleHeadlessDebug

if [ ! -f "$APK" ]; then
    echo "HATA: APK bulunamadı: $APK" >&2
    exit 1
fi

mkdir -p releases
cp "$APK" "$OUT"

echo
echo "==> Tamam: $OUT ($(du -h "$OUT" | cut -f1))"
echo "    adb install -r $OUT"
