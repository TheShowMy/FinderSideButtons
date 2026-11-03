import AppKit
import ApplicationServices
import NavigationCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
    private let toggle = NSMenuItem(title: "启用侧键导航", action: #selector(toggleEnabled), keyEquivalent: "")
    private let reverse = NSMenuItem(title: "交换返回 / 前进", action: #selector(toggleReversed), keyEquivalent: "")
    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var permissionTimer: Timer?
    private var router = NavigationRouter()
    private var enabled = true
    private var reversed = UserDefaults.standard.bool(forKey: "reversed")

    func applicationDidFinishLaunching(_ notification: Notification) {
        // LaunchServices normally prevents this; also cover direct binary launches.
        let instances = NSRunningApplication.runningApplications(withBundleIdentifier: "io.github.TheShowMy.FinderSideButtons")
        if instances.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
            NSApp.terminate(nil)
            return
        }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "arrow.left.arrow.right", accessibilityDescription: "FinderSideButtons")
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "FinderSideButtons", action: nil, keyEquivalent: ""))
        menu.addItem(status)
        menu.addItem(.separator())
        for item in [toggle, reverse] {
            item.target = self
            menu.addItem(item)
        }
        let permissions = NSMenuItem(title: "打开辅助功能权限设置…", action: #selector(openPermissions), keyEquivalent: "")
        permissions.target = self
        menu.addItem(permissions)
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
        statusItem.menu = menu
        refreshTap()
        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshTap()
        }
        if !AXIsProcessTrusted() {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }

    private func refreshTap() {
        guard AXIsProcessTrusted() else {
            stopTap()
            updateMenu()
            return
        }
        if tap == nil {
            let mask = [CGEventType.otherMouseDown, .otherMouseUp, .otherMouseDragged]
                .reduce(CGEventMask(0)) { $0 | (CGEventMask(1) << $1.rawValue) }
            tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
                                   options: .defaultTap, eventsOfInterest: mask,
                                   callback: { _, type, event, context in
                guard let context else { return Unmanaged.passUnretained(event) }
                return Unmanaged<AppDelegate>.fromOpaque(context).takeUnretainedValue()
                    .handle(type: type, event: event)
            }, userInfo: Unmanaged.passUnretained(self).toOpaque())
            if let tap {
                runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
                CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
                CGEvent.tapEnable(tap: tap, enable: true)
            }
        }
        updateMenu()
    }

    private func handle(type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        let phase: MousePhase
        switch type {
        case .otherMouseDown: phase = .down
        case .otherMouseUp: phase = .up
        case .otherMouseDragged: phase = .drag
        default: return Unmanaged.passUnretained(event)
        }
        let front = NSWorkspace.shared.frontmostApplication
        let decision = router.handle(button: event.getIntegerValueField(.mouseEventButtonNumber),
                                     phase: phase, finderActive: front?.bundleIdentifier == "com.apple.finder",
                                     enabled: enabled, reversed: reversed)
        switch decision {
        case .pass: return Unmanaged.passUnretained(event)
        case .swallow: return nil
        case .back, .forward:
            if let pid = front?.processIdentifier {
                // Finder's standard shortcuts: Command-[ and Command-].
                let key: CGKeyCode = decision == .back ? 33 : 30
                let source = CGEventSource(stateID: .privateState)
                let down = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: true)
                let up = CGEvent(keyboardEventSource: source, virtualKey: key, keyDown: false)
                down?.flags = .maskCommand
                up?.flags = .maskCommand
                // Target Finder specifically so a focus change cannot send keys to another app.
                down?.postToPid(pid)
                up?.postToPid(pid)
            }
            return nil
        }
    }

    private func stopTap() {
        if let tap { CFMachPortInvalidate(tap) }
        if let runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes) }
        tap = nil
        runLoopSource = nil
        router = NavigationRouter()
    }

    private func updateMenu() {
        status.title = !AXIsProcessTrusted() ? "等待辅助功能授权" :
            tap == nil ? "监听未启动，请重新打开应用" :
            enabled ? "已启用 · 仅访达前台生效" : "已暂停"
        toggle.state = enabled ? .on : .off
        reverse.state = reversed ? .on : .off
    }

    func menuWillOpen(_ menu: NSMenu) { refreshTap() }
    @objc private func toggleEnabled() { enabled.toggle(); updateMenu() }
    @objc private func toggleReversed() {
        reversed.toggle()
        UserDefaults.standard.set(reversed, forKey: "reversed")
        updateMenu()
    }
    @objc private func openPermissions() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    @objc private func quitApp() { NSApp.terminate(nil) }
    func applicationWillTerminate(_ notification: Notification) {
        permissionTimer?.invalidate()
        stopTap()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
