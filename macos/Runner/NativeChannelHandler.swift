import Cocoa
import FlutterMacOS
import Carbon.HIToolbox
import Sparkle

class NativeChannelHandler: NSObject {
    static let channelName = "com.openyapper/native"

    private var channel: FlutterMethodChannel!
    private let hotkeyManager = HotkeyManager()
    private let pasteHelper = PasteHelper()
    private var captureResult: FlutterResult?
    private let permissionsHelper = PermissionsHelper()
    private let keychainHelper = KeychainHelper()
    private var overlayController: OverlayWindowController?
    private let updaterController: SPUStandardUpdaterController

    override init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(
            name: NativeChannelHandler.channelName,
            binaryMessenger: registrar.messenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }

        // Set up hotkey callbacks to notify Flutter
        hotkeyManager.onStartPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.channel.invokeMethod("onHotkeyStart", arguments: nil)
            }
        }
        hotkeyManager.onStopPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.channel.invokeMethod("onHotkeyStop", arguments: nil)
            }
        }
        hotkeyManager.onHoldDown = { [weak self] in
            DispatchQueue.main.async {
                self?.channel.invokeMethod("onHotkeyHoldDown", arguments: nil)
            }
        }
        hotkeyManager.onHoldUp = { [weak self] in
            DispatchQueue.main.async {
                self?.channel.invokeMethod("onHotkeyHoldUp", arguments: nil)
            }
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        // --- Hotkey ---
        case "setHotkeyConfig":
            guard let args = call.arguments as? [String: Any],
                  let skc = args["startKeyCode"] as? Int,
                  let sfl = args["startFlags"] as? Int,
                  let stkc = args["stopKeyCode"] as? Int,
                  let stfl = args["stopFlags"] as? Int,
                  let hkc = args["holdKeyCode"] as? Int,
                  let hfl = args["holdFlags"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing hotkey config", details: nil))
                return
            }
            let startEnabled = args["startEnabled"] as? Bool ?? true
            let stopEnabled = args["stopEnabled"] as? Bool ?? true
            let holdEnabled = args["holdEnabled"] as? Bool ?? true
            hotkeyManager.setConfig(
                startKeyCode: skc,
                startFlags: UInt64(sfl),
                stopKeyCode: stkc,
                stopFlags: UInt64(stfl),
                holdKeyCode: hkc,
                holdFlags: UInt64(hfl),
                startEnabled: startEnabled,
                stopEnabled: stopEnabled,
                holdEnabled: holdEnabled
            )
            result(true)

        case "startHotkeyListener":
            hotkeyManager.start()
            result(true)

        case "stopHotkeyListener":
            hotkeyManager.stop()
            result(true)

        case "setStopHotkeyEnabled":
            guard let args = call.arguments as? [String: Any],
                  let enabled = args["enabled"] as? Bool else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing enabled", details: nil))
                return
            }
            hotkeyManager.setStopHotkeyEnabled(enabled)
            result(true)

        case "captureNextHotkey":
            captureResult = result
            hotkeyManager.onCaptureNextKey = { [weak self] keyCode, flags in
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.captureResult?(["keyCode": keyCode, "flags": Int(flags)])
                    self.captureResult = nil
                    self.hotkeyManager.onCaptureNextKey = nil
                }
            }

        // --- Paste ---
        case "pasteText":
            guard let args = call.arguments as? [String: Any],
                  let text = args["text"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing text", details: nil))
                return
            }
            let restore = args["restoreClipboard"] as? Bool ?? true
            Task {
                await pasteHelper.paste(text: text, restoreClipboard: restore)
                DispatchQueue.main.async { result(true) }
            }

        case "getFrontmostAppName":
            result(NSWorkspace.shared.frontmostApplication?.localizedName)

        case "getInstalledApps":
            Task {
                let apps = Self.getInstalledAppsWithIcons()
                DispatchQueue.main.async {
                    result(apps)
                }
            }

        // --- Permissions ---
        case "checkAccessibility":
            result(AXIsProcessTrusted())

        case "requestAccessibility":
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            let trusted = AXIsProcessTrustedWithOptions(options)
            result(trusted)

        case "checkMicrophonePermission":
            permissionsHelper.checkMicrophone { granted in
                result(granted)
            }

        case "openAccessibilitySettings":
            openSystemSettings(pane: "Privacy_Accessibility", result: result)

        case "openMicrophoneSettings":
            openSystemSettings(pane: "Privacy_Microphone", result: result)

        case "restartApp":
            restartApp(result: result)

        // --- Updates ---
        case "checkForNativeUpdates":
            updaterController.checkForUpdates(nil)
            result(true)

        // --- Overlay Window ---
        case "showRecordingOverlay":
            if overlayController == nil {
                overlayController = OverlayWindowController()
            }
            overlayController?.onCancel = { [weak self] in
                self?.channel.invokeMethod("onCancelRequested", arguments: nil)
                self?.overlayController?.dismiss()
            }
            overlayController?.show(state: "recording")
            result(true)

        case "updateOverlayState":
            guard let args = call.arguments as? [String: Any],
                  let state = args["state"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing state", details: nil))
                return
            }
            let charCount = args["charCount"] as? Int
            let duration = args["duration"] as? Double
            overlayController?.updateState(state, charCount: charCount, duration: duration.map { TimeInterval($0) })
            result(true)

        case "updateOverlayLevel":
            guard let args = call.arguments as? [String: Any],
                  let level = args["level"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing level", details: nil))
                return
            }
            overlayController?.updateAudioLevel(Float(level))
            result(true)

        case "updateOverlayDuration":
            guard let args = call.arguments as? [String: Any],
                  let duration = args["duration"] as? Double else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing duration", details: nil))
                return
            }
            overlayController?.updateDuration(duration)
            result(true)

        case "dismissRecordingOverlay":
            overlayController?.dismiss()
            result(true)

        case "dismissRecordingOverlayImmediately":
            overlayController?.dismiss(immediately: true)
            result(true)

        // --- Keychain ---
        case "keychainSave":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String,
                  let value = args["value"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing key/value", details: nil))
                return
            }
            keychainHelper.save(key: key, value: value)
            result(true)

        case "keychainLoad":
            guard let args = call.arguments as? [String: Any],
                  let key = args["key"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing key", details: nil))
                return
            }
            result(keychainHelper.load(key: key))

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func openSystemSettings(pane: String, result: @escaping FlutterResult) {
        // Use the registered scheme to avoid macOS showing an app-picker dialog.
        let urlStrings = [
            "x-apple.systempreferences:com.apple.preference.security?\(pane)",
        ]
        for raw in urlStrings {
            if let url = URL(string: raw), NSWorkspace.shared.open(url) {
                result(true)
                return
            }
        }

        // 2. Shell open — runs in user session, works from Terminal
        if runShellOpen(urlStrings[0]) {
            result(true)
            return
        }

        // 3. AppleScript — different process context, often works when Process fails
        if runAppleScriptOpen(urlStrings[0]) {
            result(true)
            return
        }

        // 4. Open System Settings app directly (no deep link)
        if runShell("open \"/System/Applications/System Settings.app\"") {
            result(true)
            return
        }
        if runShell("open -a \"System Settings\"") {
            result(true)
            return
        }

        result(
            FlutterError(
                code: "OPEN_SETTINGS_FAILED",
                message: "Could not open macOS System Settings for \(pane).",
                details: nil
            )
        )
    }

    /// Run `open "url"` or `open "path"` via /bin/zsh for correct session/environment.
    private func runShellOpen(_ target: String) -> Bool {
        let escaped = target.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return runShell("open \"\(escaped)\"")
    }

    /// Run AppleScript `open location "url"` — different process context.
    private func runAppleScriptOpen(_ urlString: String) -> Bool {
        let escaped = urlString.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return runShell("osascript -e 'open location \"\(escaped)\"'")
    }

    private func runShell(_ command: String) -> Bool {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", command]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            task.waitUntilExit()
            return task.terminationStatus == 0
        } catch {
            return false
        }
    }

    private func restartApp(result: @escaping FlutterResult) {
        let bundlePath = Bundle.main.bundlePath
        // open -n launches new instance; shell ensures correct session
        let cmd = "open -n \"\(bundlePath.replacingOccurrences(of: "\"", with: "\\\""))\""
        guard runShell(cmd) else {
            result(FlutterError(code: "RESTART_FAILED", message: "Could not launch new instance", details: nil))
            return
        }
        result(true)
        // Give Launch Services time to start new instance before we quit
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NSApplication.shared.terminate(nil)
        }
    }

    /// Returns list of installed apps with name and base64-encoded PNG icon (64x64).
    static func getInstalledAppsWithIcons() -> [[String: Any]] {
        let fileManager = FileManager.default
        var apps: [[String: Any]] = []
        var seenNames = Set<String>()

        let searchPaths: [URL] = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            URL(fileURLWithPath: NSHomeDirectory() + "/Applications"),
        ]

        for baseURL in searchPaths {
            guard let enumerator = fileManager.enumerator(
                at: baseURL,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else { continue }

            while let url = enumerator.nextObject() as? URL {
                guard url.pathExtension == "app" else { continue }
                let path = url.path

                let name: String
                if let bundle = Bundle(path: path),
                   let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String, !displayName.isEmpty {
                    name = displayName
                } else if let bundle = Bundle(path: path),
                          let bundleName = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String, !bundleName.isEmpty {
                    name = bundleName
                } else {
                    name = url.deletingPathExtension().lastPathComponent
                }

                if seenNames.contains(name) { continue }
                seenNames.insert(name)

                let iconBase64 = Self.appIconToBase64(path: path, size: 64)
                apps.append([
                    "name": name,
                    "path": path,
                    "iconBase64": iconBase64 ?? "",
                ])
            }
        }

        apps.sort { ($0["name"] as? String ?? "") < ($1["name"] as? String ?? "") }
        return apps
    }

    private static func appIconToBase64(path: String, size: Int) -> String? {
        let icon = NSWorkspace.shared.icon(forFile: path)
        let targetSize = NSSize(width: size, height: size)
        let newImage = NSImage(size: targetSize)
        newImage.lockFocus()
        icon.draw(in: NSRect(origin: .zero, size: targetSize),
                  from: NSRect(origin: .zero, size: icon.size),
                  operation: .copy,
                  fraction: 1.0)
        newImage.unlockFocus()
        guard let tiffData = newImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else { return nil }
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else { return nil }
        return pngData.base64EncodedString()
    }
}
