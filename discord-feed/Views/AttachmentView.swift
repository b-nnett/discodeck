//
//  AttachmentView.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI

struct AttachmentView: View {
    let attachment: DiscordAttachment
    
    var body: some View {
        VStack(alignment: .leading) {
            if attachment.isImage {
                AsyncImage(url: URL(string: attachment.url)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .cornerRadius(8)
                    case .failure:
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxHeight: 200)
            } else if attachment.isVideo {
                Link(destination: URL(string: attachment.url)!) {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                        
                        VStack(alignment: .leading) {
                            Text(attachment.filename)
                                .font(.headline)
                            
                            Text("Video • \(formatFileSize(attachment.size))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            } else {
                Link(destination: URL(string: attachment.url)!) {
                    HStack {
                        Image(systemName: "doc.fill")
                            .font(.largeTitle)
                        
                        VStack(alignment: .leading) {
                            Text(attachment.filename)
                                .font(.headline)
                            
                            Text("File • \(formatFileSize(attachment.size))")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
    }
    
    private func formatFileSize(_ size: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(size))
    }
}
