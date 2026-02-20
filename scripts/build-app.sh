#!/bin/zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
src_file="$project_dir/src/RemapKeysMenuBar.swift"
icon_src="$script_dir/generate-icon.swift"
out_dir="$project_dir/dist"

app_name="Remap Keys for Polish Language"
legacy_app_name="Remap Keys for PL Language"
bundle_id="com.local.RemapKeysForPLLanguage.menubar"
exec_name="RemapKeysForPLLanguageMenuBar"
app_dir="$out_dir/$app_name.app"
legacy_app_dir="$out_dir/$legacy_app_name.app"
contents_dir="$app_dir/Contents"
macos_dir="$contents_dir/MacOS"
resources_dir="$contents_dir/Resources"
plist_path="$contents_dir/Info.plist"
exec_path="$macos_dir/$exec_name"
build_dir="$project_dir/.build"
module_cache_dir="$build_dir/module-cache"
sdk_path="/Library/Developer/CommandLineTools/SDKs/MacOSX15.4.sdk"
iconset_dir="$build_dir/AppIcon.iconset"
icon_1024="$build_dir/AppIcon-1024.png"
icon_generator_bin="$build_dir/generate-icon"
icon_icns="$resources_dir/AppIcon.icns"
icon_png="$resources_dir/AppIcon.png"
icon_preview="$out_dir/AppIcon-PL-1024.png"
icon_file_value="AppIcon"

/bin/rm -rf "$app_dir"
/bin/rm -rf "$legacy_app_dir"
/bin/rm -rf "$iconset_dir"
/bin/mkdir -p "$macos_dir" "$resources_dir" "$module_cache_dir" "$iconset_dir"

/usr/bin/swiftc \
  -O \
  -parse-as-library \
  -sdk "$sdk_path" \
  -module-cache-path "$module_cache_dir" \
  -framework Cocoa \
  "$src_file" \
  -o "$exec_path"
/bin/chmod 755 "$exec_path"

/usr/bin/swiftc \
  -O \
  -sdk "$sdk_path" \
  -module-cache-path "$module_cache_dir" \
  -framework AppKit \
  "$icon_src" \
  -o "$icon_generator_bin"

"$icon_generator_bin" "$icon_1024"

/usr/bin/sips -z 16 16     "$icon_1024" --out "$iconset_dir/icon_16x16.png" >/dev/null
/usr/bin/sips -z 32 32     "$icon_1024" --out "$iconset_dir/icon_16x16@2x.png" >/dev/null
/usr/bin/sips -z 32 32     "$icon_1024" --out "$iconset_dir/icon_32x32.png" >/dev/null
/usr/bin/sips -z 64 64     "$icon_1024" --out "$iconset_dir/icon_32x32@2x.png" >/dev/null
/usr/bin/sips -z 128 128   "$icon_1024" --out "$iconset_dir/icon_128x128.png" >/dev/null
/usr/bin/sips -z 256 256   "$icon_1024" --out "$iconset_dir/icon_128x128@2x.png" >/dev/null
/usr/bin/sips -z 256 256   "$icon_1024" --out "$iconset_dir/icon_256x256.png" >/dev/null
/usr/bin/sips -z 512 512   "$icon_1024" --out "$iconset_dir/icon_256x256@2x.png" >/dev/null
/usr/bin/sips -z 512 512   "$icon_1024" --out "$iconset_dir/icon_512x512.png" >/dev/null
/usr/bin/sips -z 1024 1024 "$icon_1024" --out "$iconset_dir/icon_512x512@2x.png" >/dev/null

/bin/cp "$icon_1024" "$icon_preview"

if /usr/bin/iconutil --convert icns --output "$icon_icns" "$iconset_dir" >/dev/null 2>&1; then
  :
else
  /bin/cp "$icon_1024" "$icon_png"
  icon_file_value="AppIcon.png"
fi

cat > "$plist_path" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDisplayName</key>
    <string>$app_name</string>
    <key>CFBundleExecutable</key>
    <string>$exec_name</string>
    <key>CFBundleIdentifier</key>
    <string>$bundle_id</string>
    <key>CFBundleName</key>
    <string>$app_name</string>
    <key>CFBundleIconFile</key>
    <string>$icon_file_value</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

if [[ -x /usr/bin/codesign ]]; then
  /usr/bin/codesign --force --deep --sign - --timestamp=none "$app_dir" >/dev/null 2>&1 || true
fi
/usr/bin/xattr -dr com.apple.quarantine "$app_dir" >/dev/null 2>&1 || true

printf 'Built menu bar app: %s\n' "$app_dir"
