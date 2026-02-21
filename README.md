# Remap Keys Menu Bar App

A native macOS menu bar app with independent toggles for:
- Right Command / Option swap (PL)
- Swap Backslash / Grave Tick (UK) (`0x35` <-> `0x64`)
- F4 magnifying glass as Lock Screen
- F6 moon as Sleep/Shutdown
- Show in Menu Bar after Restart (launch at login on/off)
- About dialog with version and credits

DISCLAMER: I'm not a full blown programmer, most was done by Codex

Includes a custom app icon with a `PL` badge, generated during build.

## Build

```bash
~/Projects/KeySwap/Remap-Keys-MenuBar/scripts/build-app.sh
```

Build output:
- `~/Projects/KeySwap/Remap-Keys-MenuBar/dist/Remap Keys for Polish Language.app`

## Install (login launch)

```bash
~/Projects/KeySwap/Remap-Keys-MenuBar/scripts/install-app.sh
```

Installs to:
- `~/Applications/Remap Keys for Polish Language.app` (if writable)
- otherwise fallback: `~/Library/Application Support/Remap Keys for Polish Language/Remap Keys for Polish Language.app`
- `~/Library/LaunchAgents/com.local.RemapKeysForPLLanguage.MenuBar.plist`

## Uninstall

```bash
~/Projects/KeySwap/Remap-Keys-MenuBar/scripts/uninstall-app.sh
```

The uninstall script removes the app + launch agent and clears `UserKeyMapping`.

## Build Toggle Installer PKG

```bash
~/Projects/KeySwap/Remap-Keys-MenuBar/installer/build-pkg.sh
```

Output:
- `~/Projects/KeySwap/Remap-Keys-MenuBar/dist/Remap-Keys-for-Polish-Language-MenuBar-v1.2.pkg`

Versioning:
- default package version is `1.2`
- override when needed: `PKG_VERSION=1.3 ~/Projects/KeySwap/Remap-Keys-MenuBar/installer/build-pkg.sh`

Package behavior:
- when app is not installed: installs app for the logged-in user at `~/Applications/Remap Keys for Polish Language.app` (fallback: `~/Library/Application Support/Remap Keys for Polish Language/Remap Keys for Polish Language.app`), creates the user LaunchAgent, and launches the app
- when installed app version is older/newer than the package version: stops app and updates to package version
- when installed app version is the same as package version: stops app and uninstalls app + LaunchAgent + related preferences
