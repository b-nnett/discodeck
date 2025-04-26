//
//  DiscordMessages.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI
import Foundation

struct ColumnFilterView: View {
    let guilds: [DiscordGuild]
    @Binding var selectedChannelIDs: Set<String>
    
    var body: some View {
        List {
            ForEach(guilds, id: \.id) { guild in
                ForEach(guild.channels, id: \.id) { channel in
                    Toggle(isOn: Binding(
                        get: { selectedChannelIDs.contains(channel.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedChannelIDs.insert(channel.id)
                            } else {
                                selectedChannelIDs.remove(channel.id)
                            }
                        }
                    )) {
                        Text(channel.name)
                    }
                }
            }
        }
    }
}
