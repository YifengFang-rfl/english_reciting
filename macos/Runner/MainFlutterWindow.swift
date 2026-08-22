import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 限制窗口最小尺寸，避免内容被压坏
    self.contentMinSize = NSSize(width: 320, height: 660)
    // 初始尺寸（不小于最小尺寸）
    self.setContentSize(NSSize(width: 900, height: 700))

    super.awakeFromNib()
  }
}
