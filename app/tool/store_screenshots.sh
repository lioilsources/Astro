#!/usr/bin/env bash
# Screenshoty do App Store (7 scén) — opakovatelně.
#
#   app/tool/store_screenshots.sh              # iPhone i iPad
#   app/tool/store_screenshots.sh ios-phone
#
# Zařízení:
#   ios-phone   iPhone 6.9" (1320×2868)  simulátor iPhone 18/17 Pro Max
#   ios-tablet  iPad 13"   (2064×2752)   simulátor iPad Pro 13-inch (M5/M4)
#
# Výstup: fastlane/metadata/ios/<cs|en-US>/screenshots/<zařízení>_<n>_<scéna>.png
# Appka je jen česky: en-US dostane stejné (české) snímky.
# Scény: app/integration_test/store_screenshots_test.dart.
# Nahrání: python3 app/tool/upload_store_screenshots.py ios
set -euo pipefail

APP="$(cd "$(dirname "$0")/.." && pwd)"            # app/
META="$(cd "$APP/.." && pwd)/fastlane/metadata"
RAW="$APP/build/store_screenshots"
DEVICES=("$@"); [ ${#DEVICES[@]} -eq 0 ] && DEVICES=(ios-phone ios-tablet)
export FLUTTER_XCODE_COMPILATION_CACHE_ENABLE_CACHING=NO
# Stará sestava by mohla nést starý test (Xcode build jinak změnu testu nepozná).
rm -rf "$APP/build/ios"

sim_udid() { # první dostupný simulátor z názvů
  for name in "$@"; do
    local id
    id=$(xcrun simctl list devices available | grep -F "    $name (" | head -1 | grep -oE '[0-9A-F-]{36}' || true)
    [ -n "$id" ] && { echo "$id"; return; }
  done
  echo "chybí simulátor: $*" >&2; exit 1
}

ios() { # ios <kind> <prefix> <simulátory…>
  local kind=$1 prefix=$2; shift 2
  local udid booted=0; udid=$(sim_udid "$@")
  xcrun simctl list devices | grep -F "$udid" | grep -q Booted && booted=1
  xcrun simctl boot "$udid" 2>/dev/null || true
  xcrun simctl bootstatus "$udid" -b >/dev/null
  xcrun simctl status_bar "$udid" override --time 9:41 --dataNetwork wifi --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
  rm -rf "$RAW/$kind"; mkdir -p "$RAW/$kind"
  local ok=0
  (cd "$APP" && SCREENSHOT_DIR="$RAW/$kind" flutter drive \
    --driver=test_driver/screenshot_driver.dart \
    --target=integration_test/store_screenshots_test.dart -d "$udid") || ok=$?
  xcrun simctl status_bar "$udid" clear
  [ $booted = 1 ] || xcrun simctl shutdown "$udid"
  [ $ok = 0 ] || { echo "flutter drive selhal ($ok)" >&2; exit $ok; }
  for loc in cs en-US; do
    local out="$META/ios/$loc/screenshots"; mkdir -p "$out"; rm -f "$out/${prefix}"_*.png
    for f in "$RAW/$kind"/cs_*.png; do
      cp "$f" "$out/${prefix}_$(basename "$f" | cut -d_ -f2-)"
    done
  done
}

for d in "${DEVICES[@]}"; do
  echo "== $d"
  case $d in
    ios-phone)  ios ios-phone iphone69 "iPhone 18 Pro Max" "iPhone 17 Pro Max" ;;
    ios-tablet) ios ios-tablet ipad13 "iPad Pro 13-inch (M5)" "iPad Pro 13-inch (M4)" ;;
    *) echo "neznámé zařízení: $d" >&2; exit 1 ;;
  esac
done
echo "hotovo: $META/ios"
