//
//  ClipboardGridView.swift
//  clip-master
//
//  Created by 孙环宇 on 2025/3/6.
//

import SwiftUI
import SwiftData

struct ClipboardGridView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ClipboardItem.timestamp, order: .reverse) private var items: [ClipboardItem]
    @ObservedObject var clipboardManager: ClipboardManager
    @State private var searchText = ""
    @State private var selectedItem: ClipboardItem?
    @State private var showingTagEditor = false
    @State private var newTag = ""
    
    var filteredItems: [ClipboardItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { item in
                item.content.localizedCaseInsensitiveContains(searchText) ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var pinnedItems: [ClipboardItem] {
        filteredItems.filter { $0.isPinned }
    }
    
    var unpinnedItems: [ClipboardItem] {
        filteredItems.filter { !$0.isPinned }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 搜索栏
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("搜索剪贴板内容...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color(.windowBackgroundColor))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            .padding(.top)
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    // 固定的项目
                    if !pinnedItems.isEmpty {
                        VStack(alignment: .leading) {
                            Text("固定项目")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                                ForEach(pinnedItems) { item in
                                    ClipboardItemView(item: item, clipboardManager: clipboardManager)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // 最近的项目
                    if !unpinnedItems.isEmpty {
                        VStack(alignment: .leading) {
                            Text("最近复制的内容")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180))], spacing: 16) {
                                ForEach(unpinnedItems) { item in
                                    ClipboardItemView(item: item, clipboardManager: clipboardManager)
                                        .onTapGesture {
                                            selectedItem = item
                                        }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    if filteredItems.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "clipboard")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            Text("没有找到剪贴板项目")
                                .font(.headline)
                            Text("复制一些内容或尝试不同的搜索条件")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 50)
                    }
                }
                .padding(.bottom)
            }
            
            // 状态栏
            HStack {
                Text("\(items.count) 个项目")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("上次更新: \(Date(), formatter: dateFormatter)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.windowBackgroundColor))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.secondary.opacity(0.2)),
                alignment: .top
            )
        }
        .sheet(item: $selectedItem) { item in
            ClipboardItemDetailView(item: item, clipboardManager: clipboardManager)
        }
        .onAppear {
            clipboardManager.startMonitoring()
        }
        .onDisappear {
            clipboardManager.stopMonitoring()
        }
    }
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let clipboardManager: ClipboardManager
    @State private var isHovering = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: item.type.icon)
                    .foregroundColor(item.type.color)
                Spacer()
                if isHovering {
                    HStack(spacing: 12) {
                        Button(action: {
                            clipboardManager.copyToClipboard(item)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(action: {
                            var updatedItem = item
                            updatedItem.isPinned.toggle()
                            clipboardManager.updateItem(updatedItem)
                        }) {
                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                .foregroundColor(item.isPinned ? .yellow : .secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            Group {
                switch item.type {
                case .image:
                    if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 80)
                    } else {
                        Text("图片")
                    }
                case .file:
                    HStack {
                        Image(systemName: "doc")
                        Text(item.content)
                            .lineLimit(1)
                    }
                default:
                    Text(item.content)
                        .lineLimit(3)
                        .font(.system(size: 14))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack {
                Text(item.timestamp, formatter: itemFormatter)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if !item.tags.isEmpty {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(height: 160)
        .background(Color(.windowBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .overlay(
            Rectangle()
                .frame(height: 4)
                .foregroundColor(item.type.color),
            alignment: .bottom
        )
        .onHover { hovering in
            isHovering = hovering
        }
        .contextMenu {
            Button(action: {
                clipboardManager.copyToClipboard(item)
            }) {
                Label("复制", systemImage: "doc.on.doc")
            }
            
            Button(action: {
                var updatedItem = item
                updatedItem.isPinned.toggle()
                clipboardManager.updateItem(updatedItem)
            }) {
                Label(item.isPinned ? "取消固定" : "固定", systemImage: item.isPinned ? "pin.slash" : "pin")
            }
            
            Divider()
            
            Button(action: {
                clipboardManager.deleteItem(item)
            }) {
                Label("删除", systemImage: "trash")
            }
        }
    }
    
    private let itemFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}

struct ClipboardItemDetailView: View {
    let item: ClipboardItem
    let clipboardManager: ClipboardManager
    @State private var newTag = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label(
                    title: { Text(typeTitle) },
                    icon: { Image(systemName: item.type.icon).foregroundColor(item.type.color) }
                )
                .font(.headline)
                
                Spacer()
                
                Text(item.timestamp, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Divider()
            
            // 内容预览
            Group {
                switch item.type {
                case .image:
                    if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                    }
                case .text, .code, .link:
                    ScrollView {
                        Text(item.content)
                            .font(item.type == .code ? .system(.body, design: .monospaced) : .body)
                            .textSelection(.enabled)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                    }
                case .file:
                    HStack {
                        Image(systemName: "doc")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(item.content)
                                .font(.headline)
                            if let url = item.fileURL {
                                Text(url.path)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                }
            }
            
            Divider()
            
            // 标签管理
            VStack(alignment: .leading, spacing: 10) {
                Text("标签")
                    .font(.headline)
                
                HStack {
                    TextField("添加新标签", text: $newTag)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button(action: addTag) {
                        Text("添加")
                    }
                    .disabled(newTag.isEmpty)
                }
                
                FlowLayout(spacing: 8) {
                    ForEach(item.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Button(action: { removeTag(tag) }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray))
                        .cornerRadius(15)
                    }
                }
            }
            
            Spacer()
            
            // 操作按钮
            HStack {
                Button(action: {
                    clipboardManager.copyToClipboard(item)
                    dismiss()
                }) {
                    Label("复制", systemImage: "doc.on.doc")
                }
                
                Spacer()
                
                Button(action: {
                    var updatedItem = item
                    updatedItem.isPinned.toggle()
                    clipboardManager.updateItem(updatedItem)
                }) {
                    Label(item.isPinned ? "取消固定" : "固定", systemImage: item.isPinned ? "pin.slash" : "pin")
                }
                
                Spacer()
                
                Button(action: {
                    clipboardManager.deleteItem(item)
                    dismiss()
                }) {
                    Label("删除", systemImage: "trash")
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .frame(width: 500, height: 600)
    }
    
    var typeTitle: String {
        switch item.type {
        case .text:
            return "文本内容"
        case .image:
            return "图片"
        case .link:
            return "链接"
        case .code:
            return "代码"
        case .file:
            return "文件"
        }
    }
    
    private func addTag() {
        guard !newTag.isEmpty else { return }
        
        var updatedItem = item
        if !updatedItem.tags.contains(newTag) {
            updatedItem.tags.append(newTag)
            clipboardManager.updateItem(updatedItem)
        }
        newTag = ""
    }
    
    private func removeTag(_ tag: String) {
        var updatedItem = item
        updatedItem.tags.removeAll { $0 == tag }
        clipboardManager.updateItem(updatedItem)
    }
}