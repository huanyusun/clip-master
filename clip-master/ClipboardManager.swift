//
//  ClipboardManager.swift
//  clip-master
//
//  Created by 孙环宇 on 2025/3/6.
//

import Foundation
import SwiftUI
import SwiftData
import AppKit

class ClipboardManager: ObservableObject {
    @Published var currentItem: ClipboardItem?
    @Published var isMonitoring: Bool = false
    
    private var timer: Timer?
    private var pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastChangeCount = pasteboard.changeCount
    }
    
    // 开始监听剪贴板变化
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkForChanges()
        }
    }
    
    // 停止监听剪贴板变化
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
    }
    
    // 检查剪贴板是否有变化
    private func checkForChanges() {
        let currentChangeCount = pasteboard.changeCount
        
        guard currentChangeCount != lastChangeCount else { return }
        
        lastChangeCount = currentChangeCount
        processClipboardContent()
    }
    
    // 处理剪贴板内容
    private func processClipboardContent() {
        // 检查是否有图片
        if let image = NSImage(pasteboard: pasteboard),
           let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let imageData = bitmapImage.representation(using: .png, properties: [:]) {
            saveClipboardItem(ClipboardItem(imageData: imageData))
            return
        }
        
        // 检查是否有URL
        if let url = pasteboard.string(forType: .URL),
           let nsurl = URL(string: url) {
            saveClipboardItem(ClipboardItem(content: url, type: .link))
            return
        }
        
        // 检查是否有文件URL
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
           let firstURL = fileURLs.first {
            saveClipboardItem(ClipboardItem(fileURL: firstURL))
            return
        }
        
        // 检查是否有文本
        if let string = pasteboard.string(forType: .string) {
            // 判断是否为代码
            if isCodeContent(string) {
                saveClipboardItem(ClipboardItem(content: string, type: .code))
            } else {
                saveClipboardItem(ClipboardItem(content: string, type: .text))
            }
            return
        }
    }
    
    // 简单判断内容是否为代码
    private func isCodeContent(_ content: String) -> Bool {
        // 简单判断，包含常见的编程语言关键字或符号
        let codePatterns = [
            "func ", "class ", "struct ", "enum ", "var ", "let ", "if ", "else ", "for ", "while ",
            "import ", "return ", "public ", "private ", "protected ", "static ", "void ", "int ",
            "function ", "def ", "{", "}", "();", "[]", "=>", "->"
        ]
        
        return codePatterns.contains { content.contains($0) }
    }
    
    // 保存剪贴板项目到数据库
    private func saveClipboardItem(_ item: ClipboardItem) {
        modelContext.insert(item)
        currentItem = item
        
        do {
            try modelContext.save()
        } catch {
            print("保存剪贴板项目失败: \(error)")
        }
    }
    
    // 复制项目到剪贴板
    func copyToClipboard(_ item: ClipboardItem) {
        pasteboard.clearContents()
        
        switch item.type {
        case .text, .code, .link:
            pasteboard.setString(item.content, forType: .string)
            
        case .image:
            if let imageData = item.imageData,
               let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }
            
        case .file:
            if let fileURL = item.fileURL {
                pasteboard.writeObjects([fileURL as NSURL])
            }
        }
    }
    
    // 删除剪贴板项目
    func deleteItem(_ item: ClipboardItem) {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            print("删除剪贴板项目失败: \(error)")
        }
    }
    
    // 更新剪贴板项目
    func updateItem(_ item: ClipboardItem) {
        do {
            try modelContext.save()
        } catch {
            print("更新剪贴板项目失败: \(error)")
        }
    }
}