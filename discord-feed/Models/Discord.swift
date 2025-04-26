//
//  Discord.swift
//  discord-feed
//
//  Created by Bennett on 23/04/2025.
//

import Foundation
import Combine
import SwiftUI

class DiscordBotHandler: ObservableObject {
    @Published var messages: [DiscordMessage] = []
    @Published var connectionStatus: String = "Disconnected"
    @Published var debugLog: [String] = []
    @Published var guilds: [DiscordGuild] = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    private var token: String?
    private var heartbeatTimer: Timer?
    private var sequence: Int? = nil
    private var sessionId: String? = nil
    private var hasIdentified = false
    private var isReconnecting = false
    
    private func log(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let timestamp = formatter.string(from: Date())
        let logMessage = "[\(timestamp)] \(message)"
        
        print(logMessage)
        DispatchQueue.main.async {
            self.debugLog.append(logMessage)
            // Keep log at a reasonable size
            if self.debugLog.count > 100 {
                self.debugLog.removeFirst()
            }
        }
    }

    func start() {
        // Don't start if already connected
        if webSocketTask != nil {
            log("Already connected, not starting a new connection")
            return
        }
        
        DispatchQueue.main.async {
            self.connectionStatus = "Connecting..."
        }
        log("Starting WebSocket connection")
        
        // Create a proper WebSocket URL
        let url = URL(string: "wss://gateway.discord.gg/?v=10&encoding=json")!
        
        // Create a session with proper configuration
        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: url)
        
        // Start receiving messages
        receiveMessage()
        
        // Start the connection
        webSocketTask?.resume()
        
        log("WebSocket connection started")
        hasIdentified = false
    }
    
    func stop() {
        log("Stopping WebSocket connection")
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil
        
        // Cancel the WebSocket task
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        
        DispatchQueue.main.async {
            self.connectionStatus = "Disconnected"
        }
        
        hasIdentified = false
    }

    func login(token: String) {
        self.token = token
        log("Token set, ready to identify (\(token))")
        // Don't automatically identify - wait for HELLO
    }
    
    private func reconnect() {
        guard !isReconnecting else {
            log("Already reconnecting, skipping duplicate reconnect")
            return
        }
        
        isReconnecting = true
        log("Reconnecting...")
        stop()
        
        // Wait longer between reconnect attempts
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            self.isReconnecting = false
            self.start()
        }
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    // Only log the first part of the message to avoid cluttering the log
                    let previewLength = min(1024, text.count)
                    let preview = text.prefix(previewLength)
                    self.log("Received: \(preview)...")
                    
                    self.handleGatewayPayload(text)
                    
                    // Continue receiving messages
                    self.receiveMessage()
                    
                case .data(let data):
                    self.log("Received binary data: \(data.count) bytes")
                    self.receiveMessage()
                    
                @unknown default:
                    self.log("Received unknown message type")
                    self.receiveMessage()
                }
                
            case .failure(let error):
                self.log("WebSocket receive error: \(error)")
                
                // Only reconnect if not already reconnecting
                if !self.isReconnecting {
                    DispatchQueue.main.async {
                        self.connectionStatus = "Connection error: \(error.localizedDescription)"
                        self.reconnect()
                    }
                }
            }
        }
    }

    private func handleGatewayPayload(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        
        do {
            guard let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                log("Failed to parse payload as JSON")
                return
            }
            
            // Update sequence if present
            if let s = payload["s"] as? Int {
                sequence = s
            }
            
            if let op = payload["op"] as? Int {
                switch op {
                case 0: // Dispatch
                    if let t = payload["t"] as? String {
                        log("Received event: \(t)")
                        
                        if t == "READY" {
                            // Store session ID for resuming
                            if let d = payload["d"] as? [String: Any],
                               let sid = d["session_id"] as? String {
                                sessionId = sid
                                log("Session ID: \(sid)")
                                
                                DispatchQueue.main.async {
                                    self.connectionStatus = "Ready"
                                }
                            }
                        } else if t == "GUILD_CREATE" {
                            if let d = payload["d"] as? [String: Any] {
                                // Parse guild info
                                if let jsonData = try? JSONSerialization.data(withJSONObject: d) {
                                    do {
                                        let decoder = JSONDecoder()
                                        let guild = try decoder.decode(DiscordGuild.self, from: jsonData)
                                        DispatchQueue.main.async {
                                            // Avoid duplicates
                                            if !self.guilds.contains(where: { $0.id == guild.id }) {
                                                self.guilds.append(guild)
                                                self.log("Added guild: \(guild.name) with \(guild.channels.count) channels")
                                            }
                                        }
                                    } catch {
                                        log("Failed to decode guild: \(error)")
                                    }
                                }
                            }
                        } else if t == "MESSAGE_CREATE" {
                            if let d = payload["d"] as? [String: Any] {
                                // Try to parse the message
                                
                                print(d)
                                
                                if let jsonData = try? JSONSerialization.data(withJSONObject: d) {
                                    do {
                                        let decoder = JSONDecoder()
                                        let message = try decoder.decode(DiscordMessage.self, from: jsonData)
                                        
                                        DispatchQueue.main.async {
                                            self.messages.append(message)
                                            self.log("New message: \(message.content) from \(message.author.username)")
                                            print(message)
                                        }
                                    } catch {
                                        log("Failed to decode message: \(error)")
                                        
                                        // Log the raw message data for debugging
                                        if let jsonString = String(data: jsonData, encoding: .utf8) {
                                            log("Raw message data: \(jsonString)")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                case 9: // Invalid Session
                    log("Invalid Session")
                    hasIdentified = false
                    
                    // Wait a bit before reconnecting
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
                        self?.reconnect()
                    }
                    
                case 10: // HELLO
                    log("Received HELLO")
                    DispatchQueue.main.async {
                        self.connectionStatus = "Connected"
                    }
                    
                    // Set up heartbeat
                    if let d = payload["d"] as? [String: Any],
                       let heartbeatInterval = d["heartbeat_interval"] as? Int {
                        setupHeartbeat(interval: Double(heartbeatInterval) / 1000.0)
                    }
                    
                    // Only identify if we haven't already
                    if !hasIdentified {
                        sendIdentify()
                        hasIdentified = true
                    }
                    
                case 11: // HEARTBEAT_ACK
                    log("Received HEARTBEAT_ACK")
                    
                default:
                    log("Received op code: \(op)")
                }
            }
        } catch {
            log("Error parsing payload: \(error)")
        }
    }
    
    private func setupHeartbeat(interval: TimeInterval) {
        log("Setting up heartbeat with interval: \(interval) seconds")
        
        // Clear any existing timer
        heartbeatTimer?.invalidate()
        
        // Create a new timer on the main thread
        DispatchQueue.main.async {
            self.heartbeatTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
                self?.sendHeartbeat()
            }
        }
    }
    
    private func sendHeartbeat() {
        log("Sending heartbeat with sequence: \(sequence as Any)")
        let heartbeatPayload: [String: Any] = [
            "op": 1,
            "d": sequence as Any
        ]
        
        sendJSON(heartbeatPayload)
    }

    private func sendIdentify() {
        guard let token = token else {
            log("Cannot identify: No token provided")
            return
        }
        
        log("Sending IDENTIFY")
        
        // Define specific intents
        let intents = (1 << 0) |  // GUILDS
                     (1 << 9) |  // GUILD_MESSAGES
                     (1 << 15);  // MESSAGE_CONTENT
        
        let identifyPayload: [String: Any] = [
            "op": 2,
            "d": [
                "token": token,
                "intents": intents, // ALL INTENTS (for testing)
                "properties": [
                    "$os": "iOS",
                    "$browser": "Discord iOS App",
                    "$device": "iPhone"
                ],
                "compress": false,
                "presence": [
                  "status": "dnd",
                  "since": Date().timeIntervalSince1970,
                  "afk": false
                ],
            ]
        ]
        
        sendJSON(identifyPayload)
    }
    
    private func sendJSON(_ json: [String: Any]) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json)
            if let jsonString = String(data: data, encoding: .utf8) {
                sendMessage(jsonString)
            }
        } catch {
            log("Error serializing JSON: \(error)")
        }
    }
    
    private func sendMessage(_ text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { [weak self] error in
            if let error = error {
                self?.log("WebSocket send error: \(error)")
                
                // Only reconnect if not already reconnecting
                if !(self?.isReconnecting ?? true) {
                    self?.reconnect()
                }
            }
        }
    }
}
