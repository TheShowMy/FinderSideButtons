#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="${1:-0.1.1}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a version such as 0.1.1" >&2
  exit 1
fi
swift build -c release --arch arm64
bin_dir="$(swift build -c release --arch arm64 --show-bin-path)"
app="dist/FinderSideButtons.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$bin_dir/FinderSideButtons" "$app/Contents/MacOS/FinderSideButtons"
iconset=".build/AppIcon.iconset"
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" Assets/AppIcon.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
  retina=$((size * 2))
  sips -z "$retina" "$retina" Assets/AppIcon.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o "$app/Contents/Resources/AppIcon.icns"
cat > "$app/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleIdentifier</key><string>io.github.TheShowMy.FinderSideButtons</string>
  <key>CFBundleName</key><string>FinderSideButtons</string>
  <key>CFBundleExecutable</key><string>FinderSideButtons</string>
  <key>CFBundleIconFile</key><string>AppIcon.icns</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>$version</string>
  <key>CFBundleVersion</key><string>$version</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
</dict></plist>
EOF
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
archive="FinderSideButtons-$version-arm64.zip"
rm -f "dist/$archive"
ditto -c -k --keepParent "$app" "dist/$archive"
(cd dist && shasum -a 256 "$archive" > SHA256SUMS)
echo "Built $app and dist/$archive"
