import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  private let nativeChannelHandler = NativeChannelHandler()

  private func updateWindowSizeConstraints(for screen: NSScreen) {
    let visibleFrame = screen.visibleFrame
    let maxFrameSize = visibleFrame.size
    let maxContentSize = contentRect(forFrameRect: visibleFrame).size

    minSize = NSSize(
      width: min(700, maxFrameSize.width),
      height: min(500, maxFrameSize.height)
    )
    maxSize = maxFrameSize
    contentMaxSize = maxContentSize
  }

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController
    delegate = self

    // Window size constraints
    if let screen = (self.screen ?? NSScreen.main) {
      let screenVisibleFrame = screen.visibleFrame

      // Open maximized to the usable screen area (not macOS fullscreen space).
      setFrame(screenVisibleFrame, display: true)
      updateWindowSizeConstraints(for: screen)
    } else {
      minSize = NSSize(width: 700, height: 500)
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    let registrar = flutterViewController.registrar(forPlugin: "NativeChannelHandler")
    nativeChannelHandler.register(with: registrar)

    super.awakeFromNib()
  }

  func windowDidChangeScreen(_ notification: Notification) {
    guard let screen = self.screen else { return }
    updateWindowSizeConstraints(for: screen)
  }

  func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
    guard let screen = sender.screen ?? NSScreen.main else { return frameSize }
    let maxFrameSize = screen.visibleFrame.size

    return NSSize(
      width: min(frameSize.width, maxFrameSize.width),
      height: min(frameSize.height, maxFrameSize.height)
    )
  }
}
