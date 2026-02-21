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

        try? await Task.sleep(nanoseconds: 50_000_000)

        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cgAnnotatedSessionEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)

        if restoreClipboard {
            try? await Task.sleep(nanoseconds: 500_000_000)
            pasteboard.clearContents()
            pasteboard.writeObjects(savedItems)
        }
    }
}
