#!/bin/zsh
set -euo pipefail
cd "$(dirname "$0")"
APP="../ForceQ.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" .build-cache
swiftc -parse-as-library -module-cache-path .build-cache -target arm64-apple-macosx13.0 -O ForceQ.swift MemoryMonitor.swift -o "$APP/Contents/MacOS/ForceQ"
cp Info.plist "$APP/Contents/Info.plist"
cp ForceQ.icns "$APP/Contents/Resources/ForceQ.icns"
codesign --force --sign - "$APP"
