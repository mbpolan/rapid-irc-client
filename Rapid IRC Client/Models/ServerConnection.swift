//
//  ServerConnection.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import NIO
import SwiftUI

class ServerConnection {
    
    internal var connection: Connection!
    internal let server: ServerInfo
    internal let store: Store
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var handler: ClientHandler?
    private var channel: Channel?
    
    init(server: ServerInfo, store: Store) {
        self.server = server
        self.store = store
    }
    
    func withConnection(_ connection: Connection) {
        self.connection = connection
    }
    
    func connect() {
        let bootstrap = ClientBootstrap.init(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                self.handler = ClientHandler(self, channel)
                return channel.pipeline.addHandler(self.handler!)
            }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.store.dispatch(.network(
                                        .connectionStateChanged(
                                            self.connection,
                                            .connecting)))
                
                self.channel = try bootstrap
                    .connect(host: self.server.host, port: self.server.port)
                    .wait()
                
                self.store.dispatch(.network(
                                        .connectionStateChanged(
                                            self.connection,
                                            .connected)))
            } catch let error {
                print(error)
            }
        }
    }
    
    func disconnect() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.channel?.close().wait()
                
                // dispatch an action to signal this connection is no longer active
                if let this = self {
                    this.store.dispatch(.network(
                                            .connectionStateChanged(
                                                this.connection,
                                                .disconnected)))
                }
            } catch let error {
                print(error)
            }
        }
    }
    
    func terminate() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.group.syncShutdownGracefully()
            } catch let error {
                print(error)
            }
        }
    }
    
    func sendMessage(_ message: String) {
        handler?.send(message)
    }
}

extension ServerConnection {
    private class ClientHandler: ChannelInboundHandler {
        typealias InboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer
        
        private let connection: ServerConnection
        private let channel: Channel
        
        init(_ connection: ServerConnection, _ channel: Channel) {
            self.connection = connection
            self.channel = channel
        }
        
        func channelActive(context: ChannelHandlerContext) {
            print("connected")
            
            let nick = connection.server.nick
            
            send("NICK \(nick)", context: context)
            send("USER guest 0 * :\(nick) \(nick)", context: context)
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buffer = unwrapInboundIn(data)
            let bytes = buffer.readableBytes
            
            if let received = buffer.readString(length: bytes) {
                let lines = received.split(separator: "\r\n")
                
                lines.forEach { line in
                    processMessage(String(line))
                }
            }
        }
        
        func errorCaught(context: ChannelHandlerContext, error: Error) {
            print(error)
        }
        
        func send(_ message: String) {
            send(message, context: nil)
        }
        
        private func processMessage(_ message: String) {
            let ircMessage = IRCMessage.parse(message)
            
            switch ircMessage.command {
            case .join:
                handleJoin(ircMessage)
            case .part:
                handlePart(ircMessage)
            case .ping:
                handlePing(ircMessage)
            case .privateMessage:
                handlePrivateMessage(ircMessage)
            case .nameReply:
                handleNameReply(ircMessage)
            case .topic:
                handleTopic(ircMessage)
            case .welcome:
                handleServerWelcome(ircMessage)
            case.created,
                .yourHost,
                .myInfo,
                .iSupport,
                .statsLine,
                .listUsers,
                .listUserChannels,
                .listUserMe,
                .localUsers,
                .globalUsers,
                .motd,
                .serverMotd,
                .endMotd:
                handleServerMessage(ircMessage)
                
            case .errorNickInUse:
                handleNickInUseError(ircMessage)
            case .errorNeedMoreParams:
                handleNotEnoughParamsError(ircMessage)
                
            default:
                print("Unknown message: \(message)")
            }
        }
        
        private func handlePing(_ message: IRCMessage) {
            let server = message.parameters.first
            if server != nil {
                send("PONG \(server!)")
            }
        }
        
        private func handleJoin(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in JOIN message: \(message)")
                return
            }
            
            // expect at least one parameter
            if message.parameters.count < 1 {
                print("ERROR: no channel in JOIN message: \(message)")
                return
            }
            
            // first parameter is the channel
            let channel = message.parameters[0].dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .joinedChannel(
                                                self.connection.connection,
                                                channel,
                                                message.prefix!.raw,
                                                message.prefix!.subject)))
            
            // set this to be the active chanel
            self.connection.store.dispatch(.ui(
                                            .changeChannel(
                                                self.connection.connection,
                                                channel)))
        }
        
        private func handlePart(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in PART message: \(message)")
                return
            }
            
            // expect at least one parameter
            if message.parameters.count < 1 {
                print("ERROR: no channel in PART message: \(message)")
                return
            }
            
            // first parameter is the channel
            let channel = message.parameters[0]
            
            // second parameter is an optional message
            let reason = message.parameters.count > 1 ? message.parameters[1].dropLeadingColon() : nil
            
            self.connection.store.dispatch(.network(
                                            .partedChannel(
                                                self.connection.connection,
                                                channel,
                                                message.prefix!.raw,
                                                message.prefix!.subject,
                                                reason)))
        }
        
        private func handlePrivateMessage(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in PART message: \(message)")
                return
            }
            
            // expect at least one parameter
            if message.parameters.count < 1 {
                print("ERROR: no channel in PART message: \(message)")
                return
            }
            
            // first parameter is the intended channel or user
            let recipient = message.parameters[0]
            
            // remaining parameters aree the message content
            let text = message.parameters[1...].joined(separator: " ").dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .privateMessageReceived(
                                                self.connection.connection,
                                                message.prefix!.raw,
                                                message.prefix!.subject,
                                                recipient,
                                                ChannelMessage(
                                                    sender: message.prefix!.subject,
                                                    text: text,
                                                    variant: .privateMessage))))
        }
        
        private func handleNameReply(_ message: IRCMessage) {
            // at least three parameters are expected
            if message.parameters.count < 3 {
                print("ERROR: not enough params in NAMES reply: \(message)")
                return
            }
            
            // first parameter is the channel type
            let type = IRCChannel.AccessType(rawValue: message.parameters[0])
            
            // second parameter is the channel name
            let channel = message.parameters[1]
            
            // remaining parameters are a list of usernames
            let users = message.parameters[2...].map { nick -> User in
                // drop leading colons
                var nickname = nick.first == ":" ? String(nick.dropFirst()) : nick
                
                // does this user have elevated privileges in this channel? if so, parse the prefix and remove it
                // from the nick itself
                let privilege = User.ChannelPrivilege(rawValue: nickname.first!)
                if privilege != nil {
                    nickname = String(nickname.dropFirst())
                }
                
                return User(name: nickname, privilege: privilege)
            }
            
            self.connection.store.dispatch(.network(
                                            .usersInChannel(
                                                self.connection.connection,
                                                channel,
                                                users)))
        }
        
        private func handleTopic(_ message: IRCMessage) {
            // expect least two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in TOPIC reply: \(message)")
                return
            }
            
            // first parameter is the channel
            let channel = message.parameters[0]
            
            // remaining parameter is the topic text
            let topic = message.parameters[1...].joined(separator: " ").dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .channelTopic(
                                                self.connection.connection,
                                                channel,
                                                topic)))
        }
        
        private func handleServerWelcome(_ message: IRCMessage) {
            // expect least one parameter
            if message.parameters.count < 1 {
                print("ERROR: not enough params in WELCOME reply: \(message)")
                return
            }
            
            // take the last element of the parameter list and assume it's the client identifier
            let identifier = message.parameters.last!
            
            self.connection.store.dispatch(.network(
                                            .welcomeReceived(
                                                self.connection.connection,
                                                identifier)))
        }
        
        private func handleServerMessage(_ message: IRCMessage) {
            // combine parameters into a single string message
            var text = message.parameters.joined(separator: " ")
            
            // drop leading colons
            if text.first == ":" {
                text = text.subString(from: 1)
            }
            
            if let channel = connection.connection?.channels.first(where: { $0.name == Connection.serverChannel }) {
                connection.store.dispatch(.network(
                                            .messageReceived(
                                                channel,
                                                ChannelMessage(
                                                    text: text,
                                                    variant: .other))))
            }
        }
        
        private func handleNickInUseError(_ message: IRCMessage) {
            // expect two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in error nick in use reply: \(message)")
                return
            }
            
            // first parameter is the nick
            let nick = message.parameters[0]
            
            // second parameter is the reason
            let reason = message.parameters[1...].joined(separator: " ").dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .errorReceived(
                                                self.connection.connection,
                                                ChannelMessage(
                                                    text: "\(nick) \(reason)",
                                                    variant: .error))))
        }
        
        private func handleNotEnoughParamsError(_ message: IRCMessage) {
            // expect at least three parameters
            if message.parameters.count < 3 {
                print("ERROR: not enough params in parameters error reply: \(message)")
                return
            }
            
            // first parameter is the nick
            let nick = message.parameters[0]
            
            // second parameter is the command
            let command = message.parameters[1]
            
            // remaining parameters are the reason message
            let reason = message.parameters[2...].joined(separator: " ").dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .errorReceived(
                                                self.connection.connection,
                                                ChannelMessage(
                                                    text: "\(nick) \(command) \(reason)",
                                                    variant: .error))))
        }
        
        private func send(_ message: String, context: ChannelHandlerContext?) {
            // each message must end with a carriage return/line feed sequence
            let fullMessage = message + "\r\n"
            
            // convert the message into ascii characters and write it into a new buffer
            let data = fullMessage.compactMap { $0.asciiValue }
            var buffer = (context == nil ? channel.allocator : context!.channel.allocator).buffer(capacity: data.count)
            buffer.writeBytes(data)
            
            print("Sent: \(message)")
            channel.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
        }
    }
}
