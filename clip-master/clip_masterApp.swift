//
//  clip_masterApp.swift
//  clip-master
//
//  Created by 孙环宇 on 2025/3/6.
//

import SwiftUI
import SwiftData
import AppKit
import Combine

@main
struct clip_masterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ClipboardItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var clipboardManager: ClipboardManager?
    @StateObject private var windowController = WindowController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    if clipboardManager == nil {
                        let context = ModelContext(sharedModelContainer)
                        clipboardManager = ClipboardManager(modelContext: context)
                    }
                    
                    // 设置窗口控制器
                    windowController.setupHotkey()
                }
                .background(WindowAccessor(windowController: windowController))
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
    }
}

// 窗口控制器，用于管理窗口的显示和隐藏
class WindowController: ObservableObject {
    private var window: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var localEventMonitor: Any?
    private var globalEventMonitor: Any?
    
    // 设置全局快捷键
    func setupHotkey() {
        // 注册本地事件监听（可以拦截事件）
        let localEventMask = NSEvent.EventTypeMask.keyDown
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: localEventMask) { [weak self] event in
            // 检查是否按下了 Command+Shift+V
            if event.modifierFlags.contains(.command) && 
               event.modifierFlags.contains(.shift) && 
               event.keyCode == 9 { // V 键的键码
                self?.toggleWindowVisibility()
                return nil // 拦截事件
            }
            return event // 不拦截其他事件
        }
        
        // 同时保留全局事件监听（用于在应用不活跃时也能响应快捷键）
        let globalEventMask = NSEvent.EventTypeMask.keyDown
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: globalEventMask) { [weak self] event in
            // 检查是否按下了 Command+Shift+V
            if event.modifierFlags.contains(.command) && 
               event.modifierFlags.contains(.shift) && 
               event.keyCode == 9 { // V 键的键码
                self?.toggleWindowVisibility()
            }
        }
        
        // 添加调试日志
        print("快捷键监听已设置：Command+Shift+V")
    }
    
    // 切换窗口可见性
    func toggleWindowVisibility() {
        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
    
    // 设置窗口
    func setWindow(_ window: NSWindow) {
        self.window = window
        
        // 应用启动时隐藏窗口
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.window?.orderOut(nil)
        }
    }
    
    deinit {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}

// SwiftUI 视图，用于访问 NSWindow
struct WindowAccessor: NSViewRepresentable {
    let windowController: WindowController
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                windowController.setWindow(window)
            }
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {}
}
