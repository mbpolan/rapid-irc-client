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
    
    func connect(status: @escaping(Result<Connection.State, Error>) -> Void) {
        let bootstrap = ClientBootstrap.init(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                self.handler = ClientHandler(self, channel)
                return channel.pipeline.addHandler(self.handler!)
            }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                status(.success(.connecting))
                
                self.channel = try bootstrap
                    .connect(host: self.server.host, port: self.server.port)
                    .wait()
                
                status(.success(.connected))
            } catch let error {
                status(.failure(error))
            }
        }
    }
    
    func disconnect(status: @escaping(Result<Connection.State, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.channel?.close().wait()
                status(.success(.disconnected))
            } catch let error {
                status(.failure(error))
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
        
        private var bufferedMessage: String?
        
        init(_ connection: ServerConnection, _ channel: Channel) {
            self.connection = connection
            self.channel = channel
        }
        
        func channelActive(context: ChannelHandlerContext) {
            print("connected")
            
            let nick = connection.server.nick
            let realName = connection.server.realName
            let username = connection.server.username
            
            send("NICK \(nick)", context: context)
            send("USER \(username) 0 * :\(realName)", context: context)
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buffer = unwrapInboundIn(data)
            let bytes = buffer.readableBytes
            
            if let received = buffer.readString(length: bytes) {
                // prepend any buffered data we received to the start of this message
                let data = (bufferedMessage ?? "") + received
                
                // split messages by crlf. if the data does not end in a crlf, that means we received a
                // partial message. in that case, buffer the remaining message until we receive more data
                // from the server.
                var lines = data.components(separatedBy: "\r\n")
                if let last = lines.last,
                    !last.hasSuffix("\r\n") {
                    
                    lines = lines.dropLast()
                    bufferedMessage = last
                }
                
                lines.forEach { line in
                    processMessage(line)
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
            let ircMessage = IRCMessage(from: message)
            
            switch ircMessage.command {
            case .join:
                handleJoin(ircMessage)
            case .part:
                handlePart(ircMessage)
            case .ping:
                handlePing(ircMessage)
            case .pong:
                handlePong(ircMessage)
            case .privateMessage:
                handlePrivateMessage(ircMessage)
            case .nameReply:
                handleNameReply(ircMessage)
            case .topicReply:
                handleTopicReply(ircMessage)
            case .topicChanged:
                handleTopicChanged(ircMessage)
            case .welcome:
                handleServerWelcome(ircMessage)
            case .quit:
                handleQuit(ircMessage)
            case .yourHost:
                handleHost(ircMessage)
            case.created,
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
                
            case .errorGeneral:
                handleGeneralError(ircMessage)
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
        
        private func handlePong(_ message: IRCMessage) {
            // expect one parameter
            if message.parameters.count < 1 {
                print("ERROR: no channel in PONG message: \(message)")
                return
            }
            
            // first parameter is the origin
            let server = message.parameters[1].dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .messageReceived(
                                                connection: self.connection.connection,
                                                channelName: Connection.serverChannel,
                                                message: ChannelMessage(
                                                    text: "PONG \(server)",
                                                    variant: .other))))
        }
        
        private func handleJoin(_ message: IRCMessage) {
            // expect a valid prefix
            guard let prefix = message.prefix else {
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
            
            // register this channel in our connection
            self.connection.store.dispatch(.network(
                                            .joinedChannel(
                                                connection: self.connection.connection,
                                                channelName: channel,
                                                identifier: prefix)))            
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
            
            // remaining parameters are an optional message
            let reason = message.parameters.count > 1 ? message.parameters[1...].joined(separator: " ").dropLeadingColon() : nil
            
            self.connection.store.dispatch(.network(
                                            .partedChannel(
                                                connection: self.connection.connection,
                                                channelName: channel,
                                                identifier: message.prefix!.raw,
                                                nick: message.prefix!.subject,
                                                reason: reason)))
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
                                                connection: self.connection.connection,
                                                identifier: message.prefix!.raw,
                                                nick: message.prefix!.subject,
                                                recipient: recipient,
                                                message: ChannelMessage(
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
            let users = message.parameters[2...].map { $0.dropLeadingColon() }
            
            self.connection.store.dispatch(.network(
                                            .usernamesReceived(
                                                connection: self.connection.connection,
                                                channelName: channel,
                                                usernames: users)))
        }
        
        private func handleTopicReply(_ message: IRCMessage) {// expect least two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in TOPIC reply: \(message)")
                return
            }
            
            // first parameter is the channel
            let channel = message.parameters[0]
            
            // remaining parameter is the topic text
            let topic = message.parameters[1...].joined(separator: " ").dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .channelTopicReceived(
                                                connection: self.connection.connection,
                                                channelName: channel,
                                                topic: topic)))
        }
        
        private func handleTopicChanged(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in TOPIC reply: \(message)")
                return
            }
            
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
                                            .channelTopicChanged(
                                                connection: self.connection.connection,
                                                channelName: channel,
                                                identifier: message.prefix!,
                                                topic: topic)))
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
                                                connection: self.connection.connection,
                                                identifier: identifier)))
        }
        
        private func handleQuit(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in QUIT command: \(message)")
            }
            
            // only parameter is the quit message, if one exists
            let reason = message.parameters.joined(separator: " ").dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .userQuit(
                                                connection: self.connection.connection,
                                                identifier: message.prefix!,
                                                reason: reason)))
        }
        
        private func handleHost(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in QUIT command: \(message)")
            }
            
            // note the hostname for the server
            self.connection.store.dispatch(.network(
                                            .hostnameReceived(
                                                connection: self.connection.connection,
                                                hostname: message.prefix!.subject)))
            
            // propagate this message to the user as well
            handleServerMessage(message)
        }
        
        private func handleServerMessage(_ message: IRCMessage) {
            // combine parameters into a single string message
            var text = message.parameters.joined(separator: " ")
            
            // drop leading colons
            if text.first == ":" {
                text = text.subString(from: 1)
            }
            
            connection.store.dispatch(.network(
                                        .messageReceived(
                                            connection: self.connection.connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: text,
                                                variant: .other))))
        }
        
        private func handleGeneralError(_ message: IRCMessage) {
            // concatenage all parameters into a single message
            let reason = message.parameters[0...].joined(separator: " ").dropLeadingColon()
            
            self.connection.store.dispatch(.network(
                                            .errorReceived(
                                                connection: self.connection.connection,
                                                message: ChannelMessage(
                                                    text: reason,
                                                    variant: .error))))
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
                                                connection: self.connection.connection,
                                                message: ChannelMessage(
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
                                                connection: self.connection.connection,
                                                message: ChannelMessage(
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
