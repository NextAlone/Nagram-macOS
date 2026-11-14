#!/bin/bash
set -euo pipefail

usage() {
    echo "usage: $0 <Telegram.app> <output directory> <file name without extension>" >&2
    exit 2
}

[ "$#" -eq 3 ] || usage
SOURCE="$1"
OUTPUT="$2"
NAME="$3"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

test -d "$SOURCE"
mkdir -p "$OUTPUT"
WORK="$(mktemp -d "${RUNNER_TEMP:-${TMPDIR:-/tmp}}/nagram-package.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

APP="$WORK/stage/Nagram.app"
mkdir -p "$WORK/stage"
ditto "$SOURCE" "$APP"
plutil -replace CFBundleName -string Nagram "$APP/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string Nagram "$APP/Contents/Info.plist"

ENTITLEMENTS="$WORK/app.entitlements"
cp "$ROOT/Telegram-Mac/Telegram-Sandbox.entitlements" "$ENTITLEMENTS"
for key in com.apple.developer.associated-domains com.apple.developer.maps keychain-access-groups; do
    if /usr/libexec/PlistBuddy -c "Print :$key" "$ENTITLEMENTS" > /dev/null 2>&1; then
        /usr/libexec/PlistBuddy -c "Delete :$key" "$ENTITLEMENTS"
    fi
done

codesign --force --deep --timestamp=none -s - "$APP"
codesign --force --timestamp=none -s - \
    --entitlements "$ROOT/TelegramShare/TelegramShare.entitlements" \
    "$APP/Contents/PlugIns/TelegramShare.appex"
codesign --force --timestamp=none -s - --entitlements "$ENTITLEMENTS" "$APP"
codesign --verify --deep --strict "$APP"

mkdir -p "$WORK/image"
ditto "$APP" "$WORK/image/Nagram.app"
ln -s /Applications "$WORK/image/Applications"
for attempt in 1 2 3; do
    if hdiutil create -volname Nagram -srcfolder "$WORK/image" -format UDZO -ov "$OUTPUT/$NAME.dmg" > /dev/null; then
        break
    fi
    if [ "$attempt" -eq 3 ]; then
        echo "hdiutil could not create $NAME.dmg" >&2
        exit 1
    fi
    sleep 10
done
(cd "$WORK/stage" && ditto -c -k --sequesterRsrc --keepParent Nagram.app "$OUTPUT/$NAME.zip")

plutil -extract LSMinimumSystemVersion raw "$APP/Contents/Info.plist"
