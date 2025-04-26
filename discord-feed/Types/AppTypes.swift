//
//  AppTypes.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import Foundation

struct MessageColumn: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var selectedChannelIDs: Set<String>
    var title: String = "Column"
}
