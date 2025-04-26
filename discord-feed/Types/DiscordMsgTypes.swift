//
//  DiscordMessages.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI

struct DiscordGuild: Identifiable, Codable {
    let id: String
    let name: String
    let channels: [DiscordChannel]
}

struct DiscordChannel: Identifiable, Codable {
    let id: String
    let name: String
    let type: Int
}

struct DiscordMessage: Codable, Identifiable {
    let id: String
    let content: String
    let channel_id: String
    let timestamp: String
    let author: DiscordUser
    let embeds: [DiscordEmbed]?
    let attachments: [DiscordAttachment]?
    let mentions: [DiscordUser]?
    let mention_roles: [String]?
    let mention_everyone: Bool?
    let type: Int
    
    var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: timestamp) {
            let timeFormatter = DateFormatter()
            timeFormatter.dateStyle = .none
            timeFormatter.timeStyle = .short
            return timeFormatter.string(from: date)
        }
        return ""
    }
    
    var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: timestamp) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            return dateFormatter.string(from: date)
        }
        return ""
    }
    
    var hasContent: Bool {
        return !content.isEmpty ||
               (embeds?.isEmpty == false) ||
               (attachments?.isEmpty == false)
    }
}

struct DiscordUser: Codable, Identifiable {
    let id: String
    let username: String
    let discriminator: String?
    let avatar: String?
    let bot: Bool?
    
    var avatarURL: URL? {
        if let avatar = avatar {
            return URL(string: "https://cdn.discordapp.com/avatars/\(id)/\(avatar).png")
        }
        return nil
    }
}

struct EmbedField: Codable, Identifiable {
    var id: UUID { UUID() }
    let name: String
    let value: String
    let inline: Bool?
}

struct DiscordEmbed: Codable, Identifiable {
    var id: UUID { UUID() }
    let title: String?
    let description: String?
    let url: String?
    let timestamp: String?
    let color: Int?
    let footer: EmbedFooter?
    let image: EmbedImage?
    let thumbnail: EmbedThumbnail?
    let author: EmbedAuthor?
    let fields: [EmbedField]?
        

    // Convert color integer to SwiftUI Color
    var swiftUIColor: Color? {
        if let color = color {
            let red = Double((color >> 16) & 0xFF) / 255.0
            let green = Double((color >> 8) & 0xFF) / 255.0
            let blue = Double(color & 0xFF) / 255.0
            return Color(red: red, green: green, blue: blue)
        }
        return nil
    }
}

struct EmbedFooter: Codable {
    let text: String
    let icon_url: String?
}

struct EmbedImage: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

struct EmbedThumbnail: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

struct EmbedAuthor: Codable {
    let name: String
    let url: String?
    let icon_url: String?
}

struct DiscordAttachment: Codable, Identifiable {
    let id: String
    let filename: String
    let size: Int
    let url: String
    let proxy_url: String
    let width: Int?
    let height: Int?
    let content_type: String?
    
    var isImage: Bool {
        return content_type?.starts(with: "image/") ?? false
    }
    
    var isVideo: Bool {
        return content_type?.starts(with: "video/") ?? false
    }
}
