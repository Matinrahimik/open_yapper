import Cocoa
import FlutterMacOS
import Carbon.HIToolbox

class NativeChannelHandler: NSObject {
    static let channelName = "com.openyapper/native"

    private var channel: FlutterMethodChannel!
    private let hotkeyManager = HotkeyManager()
    private let pasteHelper = PasteHelper()
    private let permissionsHelper = PermissionsHelper()
    private let keychainHelper = KeychainHelper()
    private var overlayController: OverlayWindowController?

    func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(
            name: NativeChannelHandler.channelName,
            binaryMessenger: registrar.messenger
        )

        channel.setMethodCallHandler { [weak self] call, result in
            self?.handleMethodCall(call, result: result)
        }

        // Set up hotkey callback to notify Flutter
        hotkeyManager.onHotkeyPressed = { [weak self] in
            DispatchQueue.main.async {
                self?.channel.invokeMethod("onHotkeyPressed", arguments: nil)
            }
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        // --- Hotkey ---
        case "startHotkeyListener":
            hotkeyManager.start()
            result(true)

        case "stopHotkeyListener":
            hotkeyManager.stop()
            result(true)

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

        // --- Permissions ---
        case "checkAccessibility":
            result(AXIsProcessTrusted())

        case "requestAccessibility":
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            result(AXIsProcessTrustedWithOptions(options))

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

        // --- Overlay Window ---
        case "showRecordingOverlay":
            if overlayController == nil {
                overlayController = OverlayWindowController()
            }
            overlayController?.show(state: "recording")
            result(true)

        case "updateOverlayState":
            guard let args = call.arguments as? [String: Any],
                  let state = args["state"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing state", details: nil))
                return
            }
            overlayController?.updateState(state)
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
        let urlString = "x-apple.systempreferences:com.apple.preference.security?\(pane)"
        // Use `open` via shell - matches Terminal behavior, most reliable on macOS
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", "open \"\(urlString)\""]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            result(true)
        } catch {
            // Fallback: direct open command
            let openTask = Process()
            openTask.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            openTask.arguments = [urlString]
            openTask.standardOutput = FileHandle.nullDevice
            openTask.standardError = FileHandle.nullDevice
            do {
                try openTask.run()
                result(true)
            } catch {
                // Last resort: NSWorkspace
                if let url = URL(string: urlString) {
                    NSWorkspace.shared.open(url)
                }
                result(true)
            }
        }
    }

    private func restartApp(result: @escaping FlutterResult) {
        let bundlePath = Bundle.main.bundlePath
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        task.arguments = ["-n", bundlePath]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        do {
            try task.run()
            result(true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NSApplication.shared.terminate(nil)
            }
        } catch {
            result(FlutterError(code: "RESTART_FAILED", message: "\(error)", details: nil))
        }
    }
}
