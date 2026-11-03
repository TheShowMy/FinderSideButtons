#!/bin/bash
set -euo pipefail
if [[ "$(uname -s)" != Darwin ]]; then
  echo "FinderSideButtons requires macOS 13 or later." >&2
  exit 1
fi
major="$(sw_vers -productVersion | cut -d. -f1)"
if (( major < 13 )); then
  echo "FinderSideButtons requires macOS 13 or later." >&2
  exit 1
fi
if [[ "$(uname -m)" != arm64 ]] && [[ "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" != 1 ]]; then
  echo "FinderSideButtons supports Apple Silicon (M-series) Macs only." >&2
  exit 1
fi
version="${1:-0.1.1}"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "Expected a version such as 0.1.1" >&2
  exit 1
fi
if pgrep -f '/FinderSideButtons.app/Contents/MacOS/FinderSideButtons' >/dev/null; then
  echo "Quit FinderSideButtons from its menu bar icon, then run this command again." >&2
  exit 1
fi
repo="https://github.com/TheShowMy/FinderSideButtons"
archive="FinderSideButtons-$version-arm64.zip"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
curl --fail --location --retry 3 "$repo/releases/download/v$version/$archive" -o "$temp_dir/$archive"
curl --fail --location --retry 3 "$repo/releases/download/v$version/SHA256SUMS" -o "$temp_dir/SHA256SUMS"
(cd "$temp_dir" && shasum -a 256 -c SHA256SUMS)
ditto -x -k "$temp_dir/$archive" "$temp_dir/unpacked"
app="$temp_dir/unpacked/FinderSideButtons.app"
codesign --verify --deep --strict "$app"
destination="$HOME/Applications/FinderSideButtons.app"
if [[ -e "$destination" ]]; then
  existing_id="$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$destination/Contents/Info.plist")"
  if [[ "$existing_id" != io.github.TheShowMy.FinderSideButtons ]]; then
    echo "Another application already exists at $destination; leaving it untouched." >&2
    exit 1
  fi
fi
mkdir -p "$HOME/Applications"
ditto "$app" "$destination"
echo "Installed: $destination"
echo "Enable FinderSideButtons in System Settings > Privacy & Security > Accessibility."
echo "This community build is ad-hoc signed, not Apple notarized. No security settings have been changed."
open "$destination"
