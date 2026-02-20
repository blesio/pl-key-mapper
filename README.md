# Remap Keys Menu Bar App

A native macOS menu bar app with independent toggles for:
- Right Command/Option swap
- Non-US Backslash (§) / Grave Tick swap (`)
- F4 -> Lock Screen
- F6 -> Sleep
- Show in Menu Bar after Restart (launch at login on/off)

Includes a custom app icon with a `PL` badge, generated during build.

## Build

```bash
/Users/radek/Projects/KeySwap/Remap-Keys-MenuBar/scripts/build-app.sh
```

Build output:
- `/Users/radek/Projects/KeySwap/Remap-Keys-MenuBar/dist/Remap Keys for Polish Language.app`

## Install (login launch)

```bash
/Users/radek/Projects/KeySwap/Remap-Keys-MenuBar/scripts/install-app.sh
```

Installs to:
- `~/Applications/Remap Keys for Polish Language.app` (if writable)
- otherwise fallback: `~/Library/Application Support/Remap Keys for Polish Language/Remap Keys for Polish Language.app`
- `~/Library/LaunchAgents/com.local.RemapKeysForPLLanguage.MenuBar.plist`

## Uninstall

```bash
/Users/radek/Projects/KeySwap/Remap-Keys-MenuBar/scripts/uninstall-app.sh
```

The uninstall script removes the app + launch agent and clears `UserKeyMapping`.

## Build Toggle Installer PKG

```bash
/Users/radek/Projects/KeySwap/Remap-Keys-MenuBar/installer/build-pkg.sh
```

Output:
- `/Users/radek/Projects/KeySwap/Remap-Keys-MenuBar/dist/Remap-Keys-for-Polish-Language-MenuBar-v1.0.pkg`

Versioning:
- default package version is `1.0`
- override when needed: `PKG_VERSION=1.1 /Users/radek/Projects/KeySwap/Remap-Keys-MenuBar/installer/build-pkg.sh`

Package behavior:
- 1st run: installs app for the logged-in user at `~/Applications/Remap Keys for Polish Language.app` (fallback: `~/Library/Application Support/Remap Keys for Polish Language/Remap Keys for Polish Language.app`), creates the user LaunchAgent, and launches the app immediately
- 2nd run: stops app and removes app + LaunchAgent + related preferences
- 3rd run: installs again (toggle behavior on each run)
