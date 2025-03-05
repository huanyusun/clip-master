//
//  FlowLayout.swift
//  clip-master
//
//  Created by 孙环宇 on 2025/3/6.
//

import SwiftUI

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let content: () -> Content
    
    init(spacing: CGFloat = 8, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            FlowLayoutHelper(
                width: geometry.size.width,
                spacing: spacing,
                content: content
            )
        }
    }
    
    private struct FlowLayoutHelper<Content: View>: View {
        let width: CGFloat
        let spacing: CGFloat
        let content: () -> Content
        
        @State private var elementsSize: [CGSize] = []
        
        var body: some View {
            VStack(alignment: .leading, spacing: spacing) {
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .frame(height: 1)
                    
                    layoutView()
                }
            }
        }
        
        private func layoutView() -> some View {
            let childViews = content()
            return childViews.background(
                GeometryReader { geometry in
                    Color.clear.onAppear {
                        elementsSize.append(geometry.size)
                    }
                }
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .position(elementPosition(index: elementsSize.count))
        }
        
        private func elementPosition(index: Int) -> CGPoint {
            guard index > 0 else { return .zero }
            
            let sizes = elementsSize[0..<index]
            var rowX: CGFloat = 0
            var rowY: CGFloat = 0
            var rowMaxY: CGFloat = 0
            
            for size in sizes {
                if rowX + size.width > width {
                    rowX = 0
                    rowY = rowMaxY + spacing
                }
                
                rowX += size.width + spacing
                rowMaxY = max(rowMaxY, rowY + size.height)
            }
            
            return CGPoint(x: rowX - spacing / 2, y: rowY + elementsSize[index - 1].height / 2)
        }
    }
}