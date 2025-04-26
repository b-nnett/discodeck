//
//  EmbedView.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI

struct EmbedView: View {
    let embed: DiscordEmbed
    
    func groupFields(_ fields: [EmbedField]) -> [[EmbedField]] {
        var groups: [[EmbedField]] = []
        var currentGroup: [EmbedField] = []
        var lastInline: Bool? = nil
        
        for field in fields {
            if field.inline == lastInline {
                currentGroup.append(field)
            } else {
                if !currentGroup.isEmpty {
                    groups.append(currentGroup)
                }
                currentGroup = [field]
                lastInline = field.inline
            }
        }
        if !currentGroup.isEmpty {
            groups.append(currentGroup)
        }
        return groups
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Embed with colored border
            VStack(alignment: .leading, spacing: 8) {
                // Author
                if let author = embed.author {
                    HStack {
                        if let iconURL = author.icon_url, let url = URL(string: iconURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                        }
                        
                        Text(author.name)
                            .font(.footnote)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                }
                
                // Title
                if let title = embed.title {
                    if let url = embed.url, let embedURL = URL(string: url) {
                        Link(destination: embedURL) {
                            Text(title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    } else {
                        Text(title)
                            .font(.system(size: 14, weight: .medium))
                    }
                }
                
                // Description
                if let description = embed.description {
                    RichTextView(markdown: description)
//                    Text(description)
                        .opacity(0.8)
                        .font(.footnote)
                        .textSelection(.enabled)
                        .onTapGesture {
                            print("Description")
                        }
                }
                
                // Thumbnail
                if let thumbnail = embed.thumbnail, let thumbnailURL = URL(string: thumbnail.url) {
                    AsyncImage(url: thumbnailURL) { phase in
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
                    .frame(maxHeight: 100)
                }
                
                // Fields
                if let fields = embed.fields, !fields.isEmpty {
                    ForEach(Array(groupFields(fields).enumerated()), id: \.offset) { _, group in
                        if group.first?.inline == true {
                            HStack(alignment: .top, spacing: 16) {
                                ForEach(group) { field in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(field.name)
                                            .font(.footnote)
                                            .fontWeight(.bold)
                                        
                                        RichTextView(markdown: field.value)
                                            .font(.footnote)
                                            .textSelection(.enabled)
                                    }
                                    .padding(.vertical, 2)
                                }
                            }
                        } else {
                            ForEach(group) { field in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(field.name)
                                        .font(.footnote)
                                        .fontWeight(.bold)

                                    RichTextView(markdown: field.value)
                                        .font(.footnote)
                                        .textSelection(.enabled)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
                
                // Image
                if let image = embed.image, let imageURL = URL(string: image.url) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(height: 200)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(4)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    //                    .frame(minHeight: 200)
                    .frame(maxHeight: 200)
                }
                
                // Footer
                if let footer = embed.footer {
                    HStack {
                        if let iconURL = footer.icon_url, let url = URL(string: iconURL) {
                            AsyncImage(url: url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .foregroundColor(.gray.opacity(0.3))
                            }
                            .frame(width: 16, height: 16)
                            .clipShape(Circle())
                        }
                        
                        Text(footer.text)
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Spacer()
                        
                        // Timestamp
                        //                        if let timestamp = embed.timestamp {
                        //                            let formatter = ISO8601DateFormatter()
                        //                            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                        //                            if let date = formatter.date(from: timestamp) {
                        //                                let timeFormatter = DateFormatter()
                        //                                timeFormatter.dateStyle = .short
                        //                                timeFormatter.timeStyle = .short
                        //                                Text(timeFormatter.string(from: date))
                        //                                    .font(.caption)
                        //                                    .foregroundColor(.gray)
                        //                            }
                        //                        }
                    }
                }
            }
            .padding(16)
            .background {
                UnevenRoundedRectangle(topLeadingRadius: 4, bottomLeadingRadius: 4, bottomTrailingRadius: 8, topTrailingRadius: 8, style: .continuous)
                    .foregroundStyle(.gray.opacity(0.2))
            }
            .overlay(
                HStack {
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 8, bottomTrailingRadius: 0, topTrailingRadius: 0, style: .continuous)
                        .frame(width: 4)
                        .foregroundStyle(embed.swiftUIColor ?? .clear)
                        .padding(0)
                    
                    Spacer()
                }
            )
        }
    }
}

