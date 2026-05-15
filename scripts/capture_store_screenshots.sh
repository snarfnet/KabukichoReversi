#!/usr/bin/env bash
set -euo pipefail

BUNDLE_ID="com.tokyonasu.kabukichireversi"
APP_NAME="KabukichoReversi"
OUT_DIR="AppStoreScreenshots"
TMP_DIR="build/store-screenshots"
DERIVED_DATA="build/simulator-derived-data"

mkdir -p "$OUT_DIR" "$TMP_DIR"
rm -f "$OUT_DIR"/kabukicho-reversi-*.png

runtime_id="$(
python3 - <<'PY'
import json
import subprocess

data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "runtimes", "--json"]))
runtimes = [r for r in data["runtimes"] if r.get("isAvailable") and r.get("platform") == "iOS"]
if not runtimes:
    raise SystemExit("No available iOS simulator runtime")
runtimes.sort(key=lambda r: r.get("version", "0"))
print(runtimes[-1]["identifier"])
PY
)"

device_type_id() {
  local family="$1"
  python3 - "$family" <<'PY'
import json
import subprocess
import sys

family = sys.argv[1]
data = json.loads(subprocess.check_output(["xcrun", "simctl", "list", "devicetypes", "--json"]))
types = data["devicetypes"]

preferred = {
    "iphone": [
        "iPhone 17 Pro Max",
        "iPhone 16 Pro Max",
        "iPhone 16 Plus",
        "iPhone 15 Pro Max",
        "iPhone 14 Pro Max",
    ],
    "ipad": [
        "iPad Pro 13-inch (M4)",
        "iPad Air 13-inch (M3)",
        "iPad Pro 12.9-inch (6th generation)",
        "iPad Pro 12.9-inch (5th generation)",
    ],
}[family]

for name in preferred:
    for item in types:
        if item["name"] == name:
            print(item["identifier"])
            raise SystemExit

needle = "iPhone" if family == "iphone" else "iPad"
for item in reversed(types):
    if needle in item["name"]:
        print(item["identifier"])
        raise SystemExit

raise SystemExit(f"No {family} simulator device type found")
PY
}

iphone_type="$(device_type_id iphone)"
ipad_type="$(device_type_id ipad)"

echo "Building simulator app for screenshot capture"
xcodebuild build \
  -project KabukichoReversi.xcodeproj \
  -scheme KabukichoReversi \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO

app_path="$(find "$DERIVED_DATA/Build/Products/Debug-iphonesimulator" -name "${APP_NAME}.app" -type d | head -n 1)"
if [[ -z "$app_path" ]]; then
  echo "Simulator app was not found"
  exit 1
fi

capture_device() {
  local label="$1"
  local device_type="$2"
  local width="$3"
  local height="$4"
  local device_name="KabukichoReversi ${label} Screenshots"
  local udid

  udid="$(xcrun simctl create "$device_name" "$device_type" "$runtime_id")"
  trap 'xcrun simctl shutdown all >/dev/null 2>&1 || true' EXIT

  echo "Booting $label simulator: $udid"
  xcrun simctl boot "$udid"
  xcrun simctl bootstatus "$udid" -b
  xcrun simctl install "$udid" "$app_path"
  xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 >/dev/null 2>&1 || true

  local modes=(title game dialogue result)
  local index=1
  for mode in "${modes[@]}"; do
    xcrun simctl terminate "$udid" "$BUNDLE_ID" >/dev/null 2>&1 || true
    xcrun simctl launch "$udid" "$BUNDLE_ID" "--screenshot-${mode}" >/dev/null
    sleep 4

    local raw="$TMP_DIR/${label}-${mode}-raw.png"
    local out="$OUT_DIR/kabukicho-reversi-${label}-0${index}.png"
    xcrun simctl io "$udid" screenshot "$raw"
    sips -z "$height" "$width" "$raw" --out "$out" >/dev/null
    echo "Captured $out"
    index=$((index + 1))
  done

  xcrun simctl shutdown "$udid" >/dev/null 2>&1 || true
  xcrun simctl delete "$udid" >/dev/null 2>&1 || true
}

capture_device iphone "$iphone_type" 1242 2688
capture_device ipad "$ipad_type" 2048 2732
