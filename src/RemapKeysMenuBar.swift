import Cocoa

private struct MappingPair {
    let src: String
    let dst: String
}

private enum LaunchAgentConfig {
    static let label = "com.local.RemapKeysForPLLanguage.MenuBar"

    static var plistURL: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }
}

private func offKeyboardImage() -> NSImage? {
    guard let base = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard remapping") else {
        return nil
    }
    base.isTemplate = true
    guard let canvas = base.copy() as? NSImage else {
        return nil
    }
    canvas.lockFocus()
    defer { canvas.unlockFocus() }

    // Keep slash inside keyboard glyph bounds so icon remains visually centered
    // and the line does not span the full icon square.
    let glyphRect = NSRect(
        x: canvas.size.width * 0.15,
        y: canvas.size.height * 0.15,
        width: canvas.size.width * 0.70,
        height: canvas.size.height * 0.70
    )
    let start = NSPoint(x: glyphRect.minX + 0.8, y: glyphRect.maxY - 0.8)
    let end = NSPoint(x: glyphRect.maxX - 0.8, y: glyphRect.minY + 0.8)

    let slash = NSBezierPath()
    slash.move(to: start)
    slash.line(to: end)

    slash.lineCapStyle = .round
    slash.lineJoinStyle = .round
    slash.lineWidth = 3.0
    NSGraphicsContext.current?.compositingOperation = .clear
    slash.stroke()

    slash.lineWidth = 1.6
    NSGraphicsContext.current?.compositingOperation = .sourceOver
    NSColor.white.setStroke()
    slash.stroke()

    canvas.isTemplate = true
    return canvas
}

private func titleWithInlineSymbol(prefix: String, symbolName: String, suffix: String) -> NSAttributedString {
    let result = NSMutableAttributedString(string: "\(prefix) ")
    guard let symbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else {
        result.append(NSAttributedString(string: suffix.isEmpty ? "" : " \(suffix)"))
        return result
    }

    let configuredSymbol = symbol.withSymbolConfiguration(.init(pointSize: 12, weight: .regular)) ?? symbol
    configuredSymbol.isTemplate = true

    let attachment = NSTextAttachment()
    attachment.image = configuredSymbol
    result.append(NSAttributedString(attachment: attachment))
    if !suffix.isEmpty {
        result.append(NSAttributedString(string: " \(suffix)"))
    }
    return result
}

private final class MappingStore {
    private enum Keys {
        static let swapCommandOption = "swapCommandOption"
        static let mapF4ToLock = "mapF4ToLock"
        static let mapF6ToSleep = "mapF6ToSleep"
    }

    private let defaults = UserDefaults.standard

    var swapCommandOption: Bool
    var mapF4ToLock: Bool
    var mapF6ToSleep: Bool

    init() {
        self.swapCommandOption = defaults.object(forKey: Keys.swapCommandOption) as? Bool ?? true
        self.mapF4ToLock = defaults.object(forKey: Keys.mapF4ToLock) as? Bool ?? true
        self.mapF6ToSleep = defaults.object(forKey: Keys.mapF6ToSleep) as? Bool ?? true
        save()
    }

    func save() {
        defaults.set(swapCommandOption, forKey: Keys.swapCommandOption)
        defaults.set(mapF4ToLock, forKey: Keys.mapF4ToLock)
        defaults.set(mapF6ToSleep, forKey: Keys.mapF6ToSleep)
    }

    func buildPairs() -> [MappingPair] {
        var pairs: [MappingPair] = []

        if swapCommandOption {
            pairs.append(MappingPair(src: "0x7000000E6", dst: "0x7000000E7"))
            pairs.append(MappingPair(src: "0x7000000E7", dst: "0x7000000E6"))
        }

        if mapF4ToLock {
            pairs.append(MappingPair(src: "0x0C00000221", dst: "0x0C0000019E"))
            pairs.append(MappingPair(src: "0x70000003D", dst: "0x0C0000019E"))
        }

        if mapF6ToSleep {
            pairs.append(MappingPair(src: "0x10000009B", dst: "0x0C00000032"))
            pairs.append(MappingPair(src: "0x0B00000072", dst: "0x0C00000032"))
            pairs.append(MappingPair(src: "0x70000003F", dst: "0x0C00000032"))
        }

        return pairs
    }

    func buildUserKeyMappingJSON() -> String {
        let entries = buildPairs()
            .map { "{\"HIDKeyboardModifierMappingSrc\":\($0.src),\"HIDKeyboardModifierMappingDst\":\($0.dst)}" }
            .joined(separator: ",")
        return "{\"UserKeyMapping\":[\(entries)]}"
    }

    func applyMappings() throws {
        let payload = buildUserKeyMappingJSON()

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/hidutil")
        process.arguments = ["property", "--set", payload]

        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "RemapKeysMenuBar",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message?.isEmpty == false ? message! : "hidutil failed with status \(process.terminationStatus)"]
            )
        }
    }
}

private final class AppDelegate: NSObject, NSApplicationDelegate {
    private let store = MappingStore()

    private var statusItem: NSStatusItem!
    private let menu = NSMenu()

    private var swapItem: NSMenuItem!
    private var lockItem: NSMenuItem!
    private var sleepItem: NSMenuItem!
    private var statusLineItem: NSMenuItem!
    private var launchAtLoginItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        refreshToggleStates()
        refreshLaunchAtLoginState()
        applyMappingsAndUpdateStatus()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard remapping")
            button.image?.isTemplate = true
            button.toolTip = "Remap Keys for Polish Language"
        }

        let titleItem = NSMenuItem(title: "Remap Keys for Polish Language", action: nil, keyEquivalent: "")
        titleItem.isEnabled = false
        menu.addItem(titleItem)
        menu.addItem(.separator())

        swapItem = NSMenuItem(title: "Swap Right Command/Option", action: #selector(toggleSwap), keyEquivalent: "")
        swapItem.target = self
        menu.addItem(swapItem)

        lockItem = NSMenuItem(title: "F4 -> Lock Screen", action: #selector(toggleLock), keyEquivalent: "")
        lockItem.target = self
        lockItem.attributedTitle = titleWithInlineSymbol(prefix: "F4", symbolName: "magnifyingglass", suffix: "-> Lock Screen")
        menu.addItem(lockItem)

        sleepItem = NSMenuItem(title: "F6 -> Sleep", action: #selector(toggleSleep), keyEquivalent: "")
        sleepItem.target = self
        sleepItem.attributedTitle = titleWithInlineSymbol(prefix: "F6", symbolName: "moon", suffix: "-> Sleep")
        menu.addItem(sleepItem)

        menu.addItem(.separator())

        statusLineItem = NSMenuItem(title: "Status: Starting...", action: nil, keyEquivalent: "")
        statusLineItem.isEnabled = false
        menu.addItem(statusLineItem)

        menu.addItem(.separator())

        launchAtLoginItem = NSMenuItem(title: "Show in Menu Bar after Restart", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        menu.addItem(launchAtLoginItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    private func refreshToggleStates() {
        swapItem.state = store.swapCommandOption ? .on : .off
        lockItem.state = store.mapF4ToLock ? .on : .off
        sleepItem.state = store.mapF6ToSleep ? .on : .off
    }

    private func refreshLaunchAtLoginState() {
        launchAtLoginItem.state = FileManager.default.fileExists(atPath: LaunchAgentConfig.plistURL.path) ? .on : .off
    }

    private func launchctl(_ arguments: [String], allowFailure: Bool = false) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = arguments

        let stderr = Pipe()
        process.standardError = stderr

        try process.run()
        process.waitUntilExit()

        guard allowFailure || process.terminationStatus == 0 else {
            let errData = stderr.fileHandleForReading.readDataToEndOfFile()
            let message = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "RemapKeysMenuBar",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: message?.isEmpty == false ? message! : "launchctl failed"]
            )
        }
    }

    private func setLaunchAtLogin(enabled: Bool) throws {
        let plistURL = LaunchAgentConfig.plistURL
        let uid = String(getuid())

        if enabled {
            guard let executablePath = Bundle.main.executablePath else {
                throw NSError(
                    domain: "RemapKeysMenuBar",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Could not resolve app executable path"]
                )
            }

            try FileManager.default.createDirectory(
                at: plistURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(LaunchAgentConfig.label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(executablePath)</string>
                </array>
                <key>RunAtLoad</key>
                <true/>
            </dict>
            </plist>
            """

            try plist.write(to: plistURL, atomically: true, encoding: .utf8)

            try launchctl(["bootout", "gui/\(uid)/\(LaunchAgentConfig.label)"], allowFailure: true)
            try launchctl(["bootout", "gui/\(uid)", plistURL.path], allowFailure: true)
            try launchctl(["bootstrap", "gui/\(uid)", plistURL.path])
        } else {
            try launchctl(["bootout", "gui/\(uid)/\(LaunchAgentConfig.label)"], allowFailure: true)
            try launchctl(["bootout", "gui/\(uid)", plistURL.path], allowFailure: true)
            try? FileManager.default.removeItem(at: plistURL)
        }
    }

    private func activeOptionCount() -> Int {
        var count = 0
        if store.swapCommandOption { count += 1 }
        if store.mapF4ToLock { count += 1 }
        if store.mapF6ToSleep { count += 1 }
        return count
    }

    private func updateStatusLine() {
        let count = activeOptionCount()
        statusLineItem.title = count == 0 ? "Status: Off" : "Status: \(count) Active"
        if let button = statusItem.button {
            if count == 0 {
                button.image = offKeyboardImage() ?? NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard remapping")
                button.image?.isTemplate = true
            } else {
                let onImage = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "Keyboard remapping")
                onImage?.isTemplate = true
                button.image = onImage
            }
            button.contentTintColor = nil
        }
    }

    private func applyMappingsAndUpdateStatus() {
        do {
            try store.applyMappings()
            updateStatusLine()
        } catch {
            statusLineItem.title = "Status: Error - \(error.localizedDescription)"
        }
    }

    @objc private func toggleSwap() {
        store.swapCommandOption.toggle()
        store.save()
        refreshToggleStates()
        applyMappingsAndUpdateStatus()
    }

    @objc private func toggleLock() {
        store.mapF4ToLock.toggle()
        store.save()
        refreshToggleStates()
        applyMappingsAndUpdateStatus()
    }

    @objc private func toggleSleep() {
        store.mapF6ToSleep.toggle()
        store.save()
        refreshToggleStates()
        applyMappingsAndUpdateStatus()
    }

    @objc private func toggleLaunchAtLogin() {
        let shouldEnable = !FileManager.default.fileExists(atPath: LaunchAgentConfig.plistURL.path)
        do {
            try setLaunchAtLogin(enabled: shouldEnable)
        } catch {
            statusLineItem.title = "Status: Error - \(error.localizedDescription)"
        }
        refreshLaunchAtLoginState()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

@main
private enum RemapKeysMenuBarMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
