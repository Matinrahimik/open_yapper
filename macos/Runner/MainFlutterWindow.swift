import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // Window size constraints
    self.minSize = NSSize(width: 700, height: 500)
    self.maxSize = NSSize(width: 1920, height: 1200)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let registrar = flutterViewController.registrar(forPlugin: "NativeChannelHandler")
    NativeChannelHandler().register(with: registrar)

    super.awakeFromNib()
  }
}
