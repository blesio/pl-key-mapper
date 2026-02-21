#!/bin/zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"
out_dir="$project_dir/dist"
build_dir="$project_dir/.build"
pkg_root="$build_dir/pkgroot"
payload_dir="$pkg_root/Library/Application Support/RemapKeysForPolishLanguageMenuBarInstaller"
payload_archive="$payload_dir/RemapKeysForPolishLanguage.app.tar.gz"
payload_version_file="$payload_dir/package-version.txt"

app_name="Remap Keys for Polish Language"
app_path="$out_dir/$app_name.app"
pkg_name="Remap-Keys-for-Polish-Language-MenuBar"
pkg_version="${PKG_VERSION:-1.2}"
pkg_path="$out_dir/$pkg_name-v$pkg_version.pkg"

"$project_dir/scripts/build-app.sh"

/bin/rm -rf "$pkg_root"
/bin/mkdir -p "$payload_dir"
/usr/bin/tar -C "$out_dir" -czf "$payload_archive" "$app_name.app"
printf '%s\n' "$pkg_version" > "$payload_version_file"

/usr/bin/pkgbuild \
  --root "$pkg_root" \
  --scripts "$script_dir/scripts" \
  --identifier "com.local.RemapKeysForPLLanguage.menubar.pkg" \
  --version "$pkg_version" \
  --install-location "/" \
  "$pkg_path"

printf 'Built package: %s\n' "$pkg_path"
