#!/bin/zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_dir="$(cd "$script_dir/.." && pwd)"

"$script_dir/build-app.sh"

app_name="Remap Keys for Polish Language"
legacy_app_name="Remap Keys for PL Language"
exec_name="RemapKeysForPLLanguageMenuBar"
launch_label="com.local.RemapKeysForPLLanguage.MenuBar"

source_app="$project_dir/dist/$app_name.app"
plist_dir="$HOME/Library/LaunchAgents"
plist_path="$plist_dir/$launch_label.plist"
uid="$(/usr/bin/id -u)"

target_root="$HOME/Applications"
if [[ ! -w "$target_root" ]]; then
  target_root="$HOME/Library/Application Support/Remap Keys for Polish Language"
fi
target_app="$target_root/$app_name.app"
legacy_app="$target_root/$legacy_app_name.app"
legacy_user_app="$HOME/Applications/$legacy_app_name.app"
legacy_fallback_app="$HOME/Library/Application Support/Remap Keys for PL Language/$legacy_app_name.app"

/bin/mkdir -p "$target_root" "$plist_dir"
/bin/rm -rf "$legacy_user_app" "$legacy_fallback_app"
/bin/rm -rf "$legacy_app"
/bin/rm -rf "$target_app"
/bin/cp -R "$source_app" "$target_app"

cat > "$plist_path" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$launch_label</string>
    <key>ProgramArguments</key>
    <array>
        <string>$target_app/Contents/MacOS/$exec_name</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST

/bin/launchctl bootout "gui/$uid/$launch_label" >/dev/null 2>&1 || true
/bin/launchctl bootout "gui/$uid" "$plist_path" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "gui/$uid" "$plist_path"
/bin/launchctl kickstart -k "gui/$uid/$launch_label" >/dev/null 2>&1 || true

printf 'Installed app: %s\n' "$target_app"
printf 'Installed launch agent: %s\n' "$plist_path"
