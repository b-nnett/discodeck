//
//  RichTextView.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI

struct RichTextView: View {
    let markdown: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(parseMarkdownBlocks(markdown), id: \.self) { block in
                switch block {
                case .code(let code):
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(code)
                            .font(.system(.footnote, design: .monospaced))
                            .padding(6)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }
                case .text(let text):
                    if let attributed = try? AttributedString(markdown: text) {
                        Text(attributed)
                            .font(.subheadline)
                            .accentColor(.blue)
                            .fontWeight(.light)
                    } else {
                        Text(text)
                            .font(.subheadline)
                            .fontWeight(.light)
                    }
                }
            }
        }
    }
    
    enum Block: Hashable {
        case text(String)
        case code(String)
    }
    
    // Simple parser for code blocks (there's no way this is versatile enough)
    
    func parseMarkdownBlocks(_ markdown: String) -> [Block] {
        // Preserve line breaks by returning each line as a separate block
        return markdown.components(separatedBy: "\n").map { .text($0) }
    }
}
