//
//  ContentView.swift
//  discord-feed
//
//  Created by Bennett on 23/04/2025.
//

import Foundation
import Combine
import SwiftUI

struct ContentView: View {
    @StateObject private var discord = DiscordBotHandler()
    
    @AppStorage("messageColumns") private var messageColumnsData: Data = Data()
    @AppStorage("botToken") var botToken = ""
    @AppStorage("showProfile") var showProfile: Bool = false
    
    @State private var messageColumns: [MessageColumn] = []
    @State private var selectedColumnForEdit: MessageColumn?
    
    @State private var tempToken: String = ""
    
    @State private var showDebugLog = false
    @State private var filterSheetOpen: Bool = false
    @State private var settingsSheetOpen: Bool = false
    @State private var addColumnSheetOpen: Bool = false
   
    private let bottomScrollID = "bottom-scroll-anchor"
    
    func filteredMessages(for column: MessageColumn) -> [DiscordMessage] {
        if column.selectedChannelIDs.isEmpty {
            return discord.messages
        } else {
            return discord.messages.filter { column.selectedChannelIDs.contains($0.channel_id) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if botToken == "" {
                    Spacer()
                    
                    Text("A Discord Bot Token is required to run this app.")
                        .font(.headline)
                        .multilineTextAlignment(.center)
                    
                    Text("The bot must be in a server, with 'Message Privileges' to work.")
                        .opacity(0.8)
                        .font(.footnote)
                        .padding(.top, 12)
                    
                    SecureField("Bot Token", text: $tempToken)
                        .padding()
                        .frame(minWidth: 128, idealWidth: 240, maxWidth: 256)
                        .textFieldStyle(.roundedBorder)
                        .safeAreaPadding(EdgeInsets(top: 12, leading: 10, bottom: 12, trailing: 10))
                        .onSubmit {
                            // Asign to a temporary variable, so if you type it out the field doesn't dissapear immediately.
                            botToken = tempToken
                        }
                    
                    Spacer()
                    
                    Text("Not Affiliated With Discord Inc.")
                        .opacity(0.75)
                        .font(.footnote)
                        .padding(.bottom, 24)
                } else if messageColumns.isEmpty {
                    Text("No columns added")
                        .foregroundColor(.gray)
                        .font(.title2)
                        .padding()
                    
                    Button("Create Column") {
                        addColumnSheetOpen = true
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    if messageColumns.count > 1 {
                        GeometryReader { geometry in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .top, spacing: 0) {
                                    ForEach(messageColumns) { column in
                                        columnView(for: column, totalWidth: geometry.size.width)
                                        Divider()
                                    }
                                }
                            }
                            .ignoreSafeAreaIf(ProcessInfo.processInfo.isMacCatalystApp, edges: .top)
                        }
                    } else {
                        // Alt-View for 1 column (removes the divider, and we can add functionality
                        // like showing original server/channel in the future)
                        
                        columnView(for: messageColumns.first!, totalWidth: .infinity)
                            .ignoreSafeAreaIf(ProcessInfo.processInfo.isMacCatalystApp, edges: .top)
                    }
                }
            }
            .onAppear {
                loadColumns()
                discord.start()
                discord.login(token: botToken)
            }
            .onChange(of: botToken) {
                discord.start()
                discord.login(token: botToken)
            }
            .sheet(isPresented: $filterSheetOpen, content: {
                if let column = selectedColumnForEdit {
                    NavigationView {
                        VStack {
                            if discord.guilds.isEmpty {
                                // Todo: Force load the servers / channels, rather than relying on the event to be sent
                                // and waiting for it.
                                
                                ProgressView()
                            } else {
                                ColumnFilterView(
                                    guilds: discord.guilds,
                                    selectedChannelIDs: Binding(
                                        get: {
                                            if let index = messageColumns.firstIndex(where: { $0.id == column.id }) {
                                                return messageColumns[index].selectedChannelIDs
                                            }
                                            return Set<String>()
                                        },
                                        set: { newSelection in
                                            if let index = messageColumns.firstIndex(where: { $0.id == column.id }) {
                                                messageColumns[index].selectedChannelIDs = newSelection
                                                saveColumns()
                                            }
                                        }
                                    )
                                )
                            }
                        }
                        .navigationTitle("Filter: \(column.title)")
                        #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                        #endif
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    filterSheetOpen = false
                                    selectedColumnForEdit = nil
                                }
                            }
                        }
                    }
                }
            })
            .sheet(isPresented: $addColumnSheetOpen, content: {
                NavigationView {
                    AddColumnView(
                        isEditing: selectedColumnForEdit != nil,
                        columnTitle: selectedColumnForEdit?.title ?? "New Column",
                        onSave: { title in
                            if let editColumn = selectedColumnForEdit {
                                // Edit existing column
                                if let index = messageColumns.firstIndex(where: { $0.id == editColumn.id }) {
                                    messageColumns[index].title = title
                                }
                            } else {
                                // Add new column
                                let newColumn = MessageColumn(selectedChannelIDs: Set<String>(), title: title)
                                messageColumns.append(newColumn)
                            }
                            saveColumns()
                            selectedColumnForEdit = nil
                        }
                    )
                    .navigationTitle(selectedColumnForEdit != nil ? "Edit Column" : "Add Column")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                addColumnSheetOpen = false
                                selectedColumnForEdit = nil
                            }
                        }
                    }
                }
            })
            .sheet(isPresented: $settingsSheetOpen, content: {
                NavigationView {
                    List {
                        Section("Account") {
                            HStack {
                                Text("Token")
                                    .opacity(0.8)
                                
                                Spacer()
                                
                                SecureField("Bot Token", text: $botToken)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        
                        Section("Appearance") {
                            Toggle("Display Profile Pictures", isOn: $showProfile)
                        }
                    }
                    .navigationTitle("Settings")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                settingsSheetOpen = false
                            }
                        }
                    }
                }
            })
        }
    }
    
    // Helper function to create column view with appropriate width
    @ViewBuilder
    private func columnView(for column: MessageColumn, totalWidth: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(column.title)
                    .font(.headline)
                    .padding(.leading, 4)
                
                Spacer()
                
                Menu {
                    Button("Edit Filters") {
                        selectedColumnForEdit = column
                        filterSheetOpen = true
                    }
                    
                    Button("Rename") {
                        selectedColumnForEdit = column
                        addColumnSheetOpen = true
                    }
                    
                    Button("Delete", role: .destructive) {
                        messageColumns.removeAll { $0.id == column.id }
                        saveColumns()
                    }
                    
                    Divider()
                    
                    Button("New Column", systemImage: "plus", action: {
                        addColumnSheetOpen = true
                    })
                    
                    Button("Settings", systemImage: "gearshape", action: {
                        settingsSheetOpen = true
                    })
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .padding(4)
                }
                .hoverEffect()
            }
            .padding(12)
            
            Divider()
            
            // Message list for this column
            VStack {
                if filteredMessages(for: column).isEmpty {
                    Spacer()
                    Text("No messages")
                        .foregroundColor(.gray)
                    Spacer()
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(filteredMessages(for: column)) { message in
                                MessageView(message: message)
                                    .id("\(column.id)-\(message.id)")
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(
                                        top: 8,
                                        leading: 20,
                                        bottom: 0,
                                        trailing: 20
                                    ))
                            }
                            
                            Color.clear
                                .frame(height: 0)
                                .id("\(column.id)-\(bottomScrollID)")
                                .listRowInsets(EdgeInsets())
                                .listRowSeparator(.hidden)
                        }
                        .listStyle(PlainListStyle())
                        .onChange(of: filteredMessages(for: column).count) {
                            withAnimation {
                                proxy.scrollTo("\(column.id)-\(bottomScrollID)", anchor: .bottom)
                            }
                        }
                        .onAppear {
                            if !filteredMessages(for: column).isEmpty {
                                proxy.scrollTo("\(column.id)-\(bottomScrollID)", anchor: .bottom)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: calculateColumnWidth(totalWidth: totalWidth))
    }

    private func calculateColumnWidth(totalWidth: CGFloat) -> CGFloat {
        if messageColumns.count <= 1 {
            return totalWidth
        } else if messageColumns.count == 2 {
            return totalWidth * 0.5
        } else if messageColumns.count == 3 {
            return totalWidth * 0.3333333 // temporary, 0.33 leaves noticeable gap
        } else {
            return 400 // todo: Make customizable?
        }
    }

    private func saveColumns() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(messageColumns)
            messageColumnsData = data
        } catch {
            print("Failed to save columns: \(error)")
        }
    }
    
    private func loadColumns() {
        guard !messageColumnsData.isEmpty else { return }
        
        do {
            let decoder = JSONDecoder()
            messageColumns = try decoder.decode([MessageColumn].self, from: messageColumnsData)
        } catch {
            print("Failed to load columns: \(error)")
        }
    }
}
