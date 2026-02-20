#!/bin/zsh
set -euo pipefail

app_name="Remap Keys for Polish Language"
legacy_app_name="Remap Keys for PL Language"
launch_label="com.local.RemapKeysForPLLanguage.MenuBar"

app_path="$HOME/Applications/$app_name.app"
legacy_app_path="$HOME/Applications/$legacy_app_name.app"
fallback_app_path="$HOME/Library/Application Support/Remap Keys for Polish Language/$app_name.app"
legacy_fallback_app_path="$HOME/Library/Application Support/Remap Keys for PL Language/$legacy_app_name.app"
plist_path="$HOME/Library/LaunchAgents/$launch_label.plist"
uid="$(/usr/bin/id -u)"

/bin/launchctl bootout "gui/$uid/$launch_label" >/dev/null 2>&1 || true
/bin/launchctl bootout "gui/$uid" "$plist_path" >/dev/null 2>&1 || true
/usr/bin/pkill -f "RemapKeysForPLLanguageMenuBar" >/dev/null 2>&1 || true
/bin/rm -f "$plist_path"
/bin/rm -rf "$app_path" "$legacy_app_path"
/bin/rm -rf "$fallback_app_path" "$legacy_fallback_app_path"
/bin/rmdir "$HOME/Library/Application Support/Remap Keys for Polish Language" >/dev/null 2>&1 || true
/bin/rmdir "$HOME/Library/Application Support/Remap Keys for PL Language" >/dev/null 2>&1 || true
/usr/bin/hidutil property --set '{"UserKeyMapping":[]}' >/dev/null 2>&1 || true

printf 'Removed app: %s\n' "$app_path"
printf 'Removed legacy app: %s\n' "$legacy_app_path"
printf 'Removed fallback app: %s\n' "$fallback_app_path"
printf 'Removed legacy fallback app: %s\n' "$legacy_fallback_app_path"
printf 'Removed launch agent: %s\n' "$plist_path"
