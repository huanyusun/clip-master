//
//  ContentView.swift
//  clip-master
//
//  Created by 孙环宇 on 2025/3/6.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var clipboardManager: ClipboardManager?
    
    var body: some View {
        Group {
            if let manager = clipboardManager {
                ClipboardGridView(clipboardManager: manager)
            } else {
                ProgressView("正在初始化...")
                    .onAppear {
                        clipboardManager = ClipboardManager(modelContext: modelContext)
                    }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ClipboardItem.self, inMemory: true)
}
