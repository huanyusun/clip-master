//
//  ClipboardItem.swift
//  clip-master
//
//  Created by 孙环宇 on 2025/3/6.
//

import Foundation
import SwiftData
import SwiftUI

enum ClipboardItemType: String, Codable {
    case text
    case image
    case link
    case code
    case file
    
    var icon: String {
        switch self {
        case .text:
            return "font"
        case .image:
            return "image"
        case .link:
            return "link"
        case .code:
            return "code"
        case .file:
            return "doc"
        }
    }
    
    var color: Color {
        switch self {
        case .text:
            return Color(hex: "0071e3") // 蓝色
        case .image:
            return Color(hex: "5ac8fa") // 浅蓝色
        case .link:
            return Color(hex: "ff9500") // 橙色
        case .code:
            return Color(hex: "af52de") // 紫色
        case .file:
            return Color(hex: "34c759") // 绿色
        }
    }
}

@Model
final class ClipboardItem {
    var content: String
    var type: ClipboardItemType
    var timestamp: Date
    var isPinned: Bool
    var tags: [String]
    var imageData: Data?
    var fileURL: URL?
    
    init(content: String, type: ClipboardItemType, timestamp: Date = Date(), isPinned: Bool = false, tags: [String] = []) {
        self.content = content
        self.type = type
        self.timestamp = timestamp
        self.isPinned = isPinned
        self.tags = tags
    }
    
    // 用于图片类型的初始化方法
    convenience init(imageData: Data, timestamp: Date = Date(), isPinned: Bool = false, tags: [String] = []) {
        self.init(content: "图片", type: .image, timestamp: timestamp, isPinned: isPinned, tags: tags)
        self.imageData = imageData
    }
    
    // 用于文件类型的初始化方法
    convenience init(fileURL: URL, timestamp: Date = Date(), isPinned: Bool = false, tags: [String] = []) {
        self.init(content: fileURL.lastPathComponent, type: .file, timestamp: timestamp, isPinned: isPinned, tags: tags)
        self.fileURL = fileURL
    }
}

// 用于颜色转换的扩展
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}