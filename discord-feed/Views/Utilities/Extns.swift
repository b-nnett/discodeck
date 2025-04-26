//
//  Extns.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI

// Lets us manage safe areas in Mac Catalyst, which we can't do with typical in-line IFS

extension View {
    @ViewBuilder
    func ignoreSafeAreaIf(_ condition: Bool, edges: Edge.Set = .all) -> some View {
        if condition {
            self.ignoresSafeArea(edges: edges)
        } else {
            self
        }
    }
}
