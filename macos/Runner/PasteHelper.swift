import Cocoa
import Carbon.HIToolbox

class PasteHelper {
    func paste(text: String, restoreClipboard: Bool = true) async {
        let pasteboard = NSPasteboard.general

        var savedItems: [NSPasteboardItem] = []
        if restoreClipboard {
            savedItems = pasteboard.pasteboardItems?.compactMap { item -> NSPasteboardItem? in
                let newItem = NSPasteboardItem()
                for type in item.types {
                    if let data = item.data(forType: type) { newItem.setData(data, forType: type) }
                }
                return newItem
            } ?? []
        }

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Delay so clipboard is fully available before simulating paste.
        // Longer delay helps when pasting into the same app (Open Yapper).
        try? await Task.sleep(nanoseconds: 150_000_000)

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)

        if restoreClipboard {
            let itemsToRestore = savedItems
            // Restore the clipboard in the background so the caller can dismiss
            // UI as soon as the paste gesture has been sent.
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                pasteboard.clearContents()
                pasteboard.writeObjects(itemsToRestore)
            }
        }
    }
}
