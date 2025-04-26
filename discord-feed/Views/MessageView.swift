//
//  MessageView.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI

struct MessageView: View {
    @AppStorage("showProfile") var showProfile: Bool = false
    
    let message: DiscordMessage
    
    var body: some View {
        HStack(alignment: .top) {
            if showProfile {
                if let avatarURL = message.author.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .foregroundColor(.gray.opacity(0.3))
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .foregroundColor(.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(message.author.username)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Text(message.formattedTime)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if !message.content.isEmpty {
                    RichTextView(markdown: message.content)
                        .font(.subheadline)
                        .textSelection(.enabled)
                }
                
                if let embeds = message.embeds, !embeds.isEmpty {
                    ForEach(embeds) { embed in
                        EmbedView(embed: embed)
                    }
                }

                if let attachments = message.attachments, !attachments.isEmpty {
                    ForEach(attachments) { attachment in
                        AttachmentView(attachment: attachment)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}
