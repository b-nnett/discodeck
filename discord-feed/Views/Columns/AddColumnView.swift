//
//  AddColumnView.swift
//  discord-feed
//
//  Created by Bennett on 24/04/2025.
//

import SwiftUI

struct AddColumnView: View {
    @Environment(\.dismiss) var dismiss
    
    let isEditing: Bool
    @State private var title: String
    let onSave: (String) -> Void
    
    init(isEditing: Bool, columnTitle: String, onSave: @escaping (String) -> Void) {
        self.isEditing = isEditing
        self._title = State(initialValue: columnTitle)
        self.onSave = onSave
    }
    
    var body: some View {
        Form {
            Section("Column Name") {
                TextField("Title", text: $title)
            }
            
            Section {
                Button("Save") {
                    onSave(title)
                    
                    dismiss()
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}
