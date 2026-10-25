#!/bin/bash
# 在模拟器里启动预览 App 并截图：preview-screenshots.sh <IndigoPreview.app> <输出目录>
set -euxo pipefail
app="$1"
out="$2"
mkdir -p "$out"
bundle=com.vancaesar.indigo.preview

# 选一台常规尺寸的 iPhone 模拟器
udid="$(xcrun simctl list devices available -j | python3 -c '
import json, sys
devs = [d for rt, ds in json.load(sys.stdin)["devices"].items() if "iOS" in rt for d in ds]
phones = [d for d in devs if d["name"].startswith("iPhone")]
for want in ("iPhone 17 Pro", "iPhone 17", "iPhone 16 Pro", "iPhone 16"):
    hit = [d for d in phones if d["name"] == want]
    if hit:
        print(hit[-1]["udid"]); break
else:
    print(phones[-1]["udid"])
')"
xcrun simctl list devices | grep "$udid"
xcrun simctl boot "$udid" || true
xcrun simctl bootstatus "$udid" -b
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 || true
xcrun simctl install "$udid" "$app"

shot() {
  local name="$1"; shift
  xcrun simctl terminate "$udid" "$bundle" 2>/dev/null || true
  xcrun simctl launch "$udid" "$bundle" "$@"
  sleep 4
  xcrun simctl io "$udid" screenshot "$out/$name.png"
}

shot keyboard-light -IndigoPreview letters -IndigoTheme light
shot keyboard-dark -IndigoPreview letters -IndigoTheme dark
shot numbers-light -IndigoPreview numbers -IndigoTheme light
shot numbers-dark -IndigoPreview numbers -IndigoTheme dark
shot app-home -IndigoPreview home -IndigoTheme light
ls -lh "$out"
