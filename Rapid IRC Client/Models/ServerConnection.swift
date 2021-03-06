//
//  ServerConnection.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import NIO
import NIOSSL
import SwiftUI

/// A connection to an IRC server.
///
/// This class maintains a handle for interacting and receiving data from a remote IRC server.
class ServerConnection {
    
    internal var connection: Connection!
    internal let server: ServerInfo
    internal let store: Store
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var handler: ClientHandler?
    private var channel: Channel?
    
    /// Prepares a connection to a server.
    ///
    /// The connection is not established until a call to `connect()` is done.
    ///
    /// - Parameter server: The server to connect to.
    /// - Parameter store: The redux store to associate with data.
    init(server: ServerInfo, store: Store) {
        self.server = server
        self.store = store
    }
    
    /// Attachs a `Connection` to this server connection.
    ///
    /// - Parameter connection: The actual connection to associate with this server.
    func withConnection(_ connection: Connection) {
        self.connection = connection
    }
    
    /// Attempts to connect to the remote server.
    ///
    /// The connection is done asynchronously, so this function will return immediately. To monitor status
    /// changes, pass a closure as the `status` parameter to be notified of updates.
    ///
    /// - Parameter status: Closure to invoke when the connection status changes.
    func connect(status: @escaping(Result<Connection.State, Error>) -> Void) {
        let bootstrap = ClientBootstrap.init(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                var handlers: [ChannelHandler] = []
                
                do {
                    // initialize our own irc protocol handler
                    let ourHandler = ClientHandler(self, channel)
                    self.handler = ourHandler
                    
                    // initialize a handler for securing the connection with tls, if requested
                    if self.server.secure {
                        var configuration = TLSConfiguration.forClient()
                        configuration.maximumTLSVersion = .tlsv12
                        
                        // configure the certificate verification strategy
                        switch self.server.sslVerificationMode {
                        case .full:
                            configuration.certificateVerification = .fullVerification
                        case .ignoreHostnames:
                            configuration.certificateVerification = .noHostnameVerification
                        case .disabled:
                            configuration.certificateVerification = .none
                        default:
                            break
                        }
                        
                        let sslContext = try NIOSSLContext(configuration: configuration)
                        let sslHandler = try NIOSSLClientHandler(
                            context: sslContext,
                            serverHostname: self.server.host
                        )
                        
                        handlers.append(sslHandler)
                    }
                    
                    handlers.append(ourHandler)
                } catch let error {
                    print("ERROR: failed to prepare SSL: \(error.localizedDescription)")
                    status(.failure(error))
                }
                
                return channel.pipeline.addHandlers(handlers)
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
    
    /// Disconnects from the remote server.
    ///
    /// The disconnec is done asynchronously, so this function will return immediately. To monitor status
    /// changes, pass a closure as the `status` parameter to be notified of updates.
    ///
    /// - Parameter status: Closure to invoke when the connection status changes.
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
    
    /// Immediately shuts down the connection and cleans up resources.
    ///
    /// You should only call this function when there is no more need for this particular server connection
    /// anymore.
    func terminate() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.group.syncShutdownGracefully()
            } catch let error {
                print(error)
            }
        }
    }
    
    /// Sends a raw message to the remote server.
    ///
    /// This function will not inspect the message for validity. The actual sending is done asynchrously,
    /// so this function will return immediately while the message is queued for sending.
    func sendMessage(_ message: String) {
        handler?.send(message)
    }
}

// MARK: - ServerConnection extensions
extension ServerConnection {
    
    /// Wrapper for the underlying network connection to a server.
    private class ClientHandler: ChannelInboundHandler {
        typealias InboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer
        
        private let connection: ServerConnection
        private let channel: Channel
        
        private var bufferedMessage: [UInt8] = []
        
        init(_ connection: ServerConnection, _ channel: Channel) {
            self.connection = connection
            self.channel = channel
        }
        
        func channelActive(context: ChannelHandlerContext) {
            print("connected")
            
            let nick = connection.server.nick
            let realName = connection.server.realName
            
            // set a default username if none is given
            var username = connection.server.username
            if username.isEmptyOrWhitespace {
                username = NSUserName()
            }
            
            // if a password was given, send the PASS command
            if let password = connection.server.password, !password.isEmptyOrWhitespace {
                send("PASS \(password)")
            }
            
            send("NICK \(nick)", context: context)
            send("USER \(username) 0 * :\(realName)", context: context)
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buffer = unwrapInboundIn(data)
            let bytes = buffer.readableBytes
            
            if let received = buffer.readBytes(length: bytes) {
                // append the data to our ongoing buffer
                bufferedMessage.append(contentsOf: received)
                
                // find each complete message, ending in a CRLF
                while let crIndex = bufferedMessage.firstIndex(of: 0x0D),
                      crIndex < bufferedMessage.count - 1,
                      bufferedMessage[crIndex + 1] == 0x0A {
                   
                    if let decoded = String(bytes: bufferedMessage[0..<crIndex], encoding: .utf8) {
                        print("Incoming: \(decoded)")
                        processMessage(decoded)
                    } else {
                        print("ERROR: failed to decode message, dropping...")
                    }
                    
                    if crIndex + 2 < bufferedMessage.count {
                        bufferedMessage = Array(bufferedMessage[(crIndex + 2)...])
                    } else {
                        bufferedMessage = []
                    }
                }
            }
        }
        
        func errorCaught(context: ChannelHandlerContext, error: Error) {
            print(error)
            
            // take the default error description by default
            var text = error.localizedDescription
            
            // depending on the error, try to provide some more context to the user
            switch error {
            case let sslError as NIOSSLExtraError:
                switch sslError {
                case .failedToValidateHostname:
                    text = "SSL error: failed to validate the server hostname."
                    
                default:
                    text = "SSL error: an unknown problem prevented a secure connection from being established."
                }
                
                text = "\(text) Reason: \(sslError.description)"
            default:
                break
            }
            
            self.connection.store.dispatch(.network(
                                            .errorReceived(
                                                connection: self.connection.connection,
                                                message: ChannelMessage(
                                                    text: text,
                                                    variant: .error))))
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
                handlePrivateMessage(ircMessage, variant: .privateMessage)
            case .notice:
                handlePrivateMessage(ircMessage, variant: .notice)
            case .nameReply:
                handleNameReply(ircMessage)
            case .endOfNames:
                handleEndOfNamesReply(ircMessage)
            case .topicReply:
                handleTopicReply(ircMessage)
            case .topicChanged:
                handleTopicChanged(ircMessage)
            case .topicSetByWhen:
                handleTopicSetByWhen(ircMessage)
            case .welcome:
                handleServerWelcome(ircMessage)
            case .quit:
                handleQuit(ircMessage)
            case .yourHost:
                handleHost(ircMessage)
            case .nick:
                handleNick(ircMessage)
            case .kick:
                handleKick(ircMessage)
            case .mode:
                handleModeCommand(ircMessage)
            case .channelListStart:
                handleChannelListStart(ircMessage)
            case .channelList:
                handleChannelList(ircMessage)
            case .channelListEnd:
                handleChannelListEnd(ircMessage)
            case .channelModes:
                handleChannelModes(ircMessage)
            case .channelCreationTime:
                handleChannelCreationTime(ircMessage)
            case .userModeIs:
                handleUserModeIs(ircMessage)
            case .listOpsOnline,
                 .listUnknownConnections,
                 .listUserChannels:
                handleServerStatistic(ircMessage)
            case .tryAgain:
                handleTryAgain(ircMessage)
            case .userIsAway:
                handleUserAway(ircMessage)
            case .motd:
                handleMotd(ircMessage)
            case .inviting:
                handleInviting(ircMessage)
            case .who:
                handleWho(ircMessage)
            case.created,
                .myInfo,
                .iSupport,
                .statsCommands,
                .statsLinkInfo,
                .statsCLine,
                .statsNLine,
                .statsILine,
                .statsKLine,
                .statsYLine,
                .endOfStats,
                .statsLLine,
                .statsUptime,
                .statsOLine,
                .statsLine,
                .listUsers,
                .listUserMe,
                .adminMe,
                .adminLocation1,
                .adminLocation2,
                .adminEmail,
                .localUsers,
                .globalUsers,
                .userHost,
                .unAway,
                .nowAway,
                .info,
                .endOfInfo,
                .serverMotd,
                .endMotd,
                .endOfWho,
                .version,
                .youreOperator,
                .time:
                handleServerMessage(ircMessage)
            
            case .error,
                 .errorGeneral:
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
        
        private func handlePrivateMessage(_ message: IRCMessage, variant: ChannelMessage.Variant) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in PRIVMSG/NOTICE message: \(message)")
                return
            }
            
            // expect at least one parameter
            if message.parameters.count < 1 {
                print("ERROR: no channel in PRIVMSG/NOTICE message: \(message)")
                return
            }
            
            // first parameter is the intended channel or user
            let recipient = message.parameters[0]
            
            // remaining parameters are the message content
            let text = message.parameters[1...].joined(separator: " ").dropLeadingColon()
            
            // a ctcp message is prefixed by ascii character 0x01; handle these separately
            // otherwise, this is just a standard private message or notice by irc protocol standards
            if text.first?.asciiValue == 0x01 {
                // trim the leading (and possibly) trailing control characters
                var ctcpText = text.dropFirst()
                if ctcpText.last?.asciiValue == 0x01 {
                    ctcpText = ctcpText.dropLast()
                }
                
                handleCTCPMessage(message, recipient: recipient, ctcpText: String(ctcpText))
            } else {
                self.connection.store.dispatch(.network(
                                                .privateMessageReceived(
                                                    connection: self.connection.connection,
                                                    identifier: message.prefix!,
                                                    recipient: recipient,
                                                    message: ChannelMessage(
                                                        sender: message.prefix!.subject,
                                                        text: text,
                                                        variant: variant))))
            }
        }
        
        private func handleNameReply(_ message: IRCMessage) {
            // at least three parameters are expected
            if message.parameters.count < 3 {
                print("ERROR: not enough params in NAMES reply: \(message)")
                return
            }
            
            // first parameter is the channel type
            _ = IRCChannel.AccessType(rawValue: message.parameters[0])
            
            // second parameter is the channel name, or asterisk for server users
            let target = message.parameters[1]
            let channelName = target == "*" ? Connection.serverChannel : target
            
            // remaining parameters are a list of usernames
            let users = message.parameters[2...].map { $0.dropLeadingColon() }
            
            self.connection.store.dispatch(.network(
                                            .usernamesReceived(
                                                connection: self.connection.connection,
                                                channelName: channelName,
                                                usernames: users)))
        }
        
        private func handleEndOfNamesReply(_ message: IRCMessage) {
            // at least one parameter is expected
            if message.parameters.count < 1 {
                print("ERROR: not enough params in ENDOFNAMES reply: \(message)")
                return
            }
            
            // first parameter is the channel name, or asterisk for server users
            let channel = message.parameters[0]
            let channelName = channel == "*" ? Connection.serverChannel : channel
            
            self.connection.store.dispatch(.network(
                                            .allUsernamesReceived(
                                                connection: self.connection.connection,
                                                channelName: channelName)))
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
        
        private func handleTopicSetByWhen(_ message: IRCMessage) {
            // expect least three parameters
            if message.parameters.count < 3 {
                print("ERROR: not enough params in TOPICWHOTIME reply: \(message)")
                return
            }
            
            // first parameter is the channel name
            let channelName = message.parameters[0]
            
            // second parameter is the user who set the topic
            let who = message.parameters[1]
            
            // third parameter is the unix timestamp for when the topic was set
            guard let timestamp = Double(message.parameters[2]) else {
                print("ERROR: invalid timestamp for TOPICWHOTIME: \(message.parameters[3])")
                return
            }
            
            let date = Date(timeIntervalSince1970: timestamp)
            
            self.connection.store.dispatch(.network(
                                            .channelTopicMetadataReceived(
                                                connection: self.connection.connection,
                                                channelName: channelName,
                                                who: who,
                                                when: date)))
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
        
        private func handleNick(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in NICK command: \(message)")
            }
            
            // expect one parameter
            if message.parameters.count < 1 {
                print("ERROR: not enough params in NICK command: \(message)")
                return
            }
            
            // first parameter is the new nick
            let nick = message.parameters[0].dropLeadingColon()
            
            // note the hostname for the server
            self.connection.store.dispatch(.network(
                                            .nickReceived(
                                                connection: self.connection.connection,
                                                identifier: message.prefix!,
                                                nick: nick)))
        }
        
        private func handleKick(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in KICK command: \(message)")
            }
            
            // expect at least two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in KICK command: \(message)")
                return
            }
            
            // first parameter is the channel
            let channelName = message.parameters[0]
            
            // second parameter is the nick
            let nick = message.parameters[1]
            
            // remaining parameters, if any, are the kick message
            let reason = message.parameters[2...].joined(separator: " ").dropLeadingColon()
            
            // note the hostname for the server
            self.connection.store.dispatch(.network(
                                            .kickReceived(
                                                connection: self.connection.connection,
                                                identifier: message.prefix!,
                                                channelName: channelName,
                                                nick: nick,
                                                reason: reason)))
        }
        
        private func handleChannelListStart(_ message: IRCMessage) {
            // expect at least three parameters
            if message.parameters.count < 3 {
                print("ERROR: not enough params in LISTSTART reply: \(message)")
                return
            }
            
            // first parameter is the channel name header
            let channelName = message.parameters[0]
            
            // second parameter is the user count header
            let users = message.parameters[1].dropLeadingColon()
            
            // third parameter is the channel topic header
            let topic = message.parameters[2]
            
            let text = "\(channelName) \(users) \(topic)"
            
            self.connection.store.dispatch(.network(
                                            .messageReceived(
                                                connection: self.connection.connection,
                                                channelName: Connection.serverChannel,
                                                message: ChannelMessage(
                                                    text: text,
                                                    variant: .other))))
        }
        
        private func handleChannelList(_ message: IRCMessage) {
            // expect at least three parameters
            if message.parameters.count < 3 {
                print("ERROR: not enough params in LIST reply: \(message)")
                return
            }
            
            // first parameter is the channel name
            let channelName = message.parameters[0]
            
            // second parameter is the user count
            let users = message.parameters[1]
            
            // third parameter is the channel topic
            let topic = message.parameters[2...].joined(separator: " ").dropLeadingColon()
            
            let realTopic = topic.isEmptyOrWhitespace ? "(no topic)" : "'\(topic)'"
            let text = "\(channelName) \(users) \(realTopic)"
            
            self.connection.store.dispatch(.network(
                                            .messageReceived(
                                                connection: self.connection.connection,
                                                channelName: Connection.serverChannel,
                                                message: ChannelMessage(
                                                    text: text,
                                                    variant: .other))))
        }
        
        private func handleChannelListEnd(_ message: IRCMessage) {
            self.connection.store.dispatch(.network(
                                            .messageReceived(
                                                connection: self.connection.connection,
                                                channelName: Connection.serverChannel,
                                                message: ChannelMessage(
                                                    text: "End of channel list",
                                                    variant: .other))))
        }
        
        private func handleModeCommand(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in MODE command: \(message)")
                return
            }
            
            // expect at least two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in MODE command: \(message)")
                return
            }
            
            // first parameter is the target
            let target = message.parameters[0]
            
            // second parameter is the mode string
            let modeString = message.parameters[1].dropLeadingColon()
            
            // remaining parameters, if any, are mode parameters
            var modeArgs = Array(message.parameters[2...])
            if let first = modeArgs.first {
                modeArgs[0] = first.dropLeadingColon()
            }
            
            self.connection.store.dispatch(.network(
                                            .modeReceived(
                                                connection: self.connection.connection,
                                                identifier: message.prefix!,
                                                target: target,
                                                modeString: modeString,
                                                modeArgs: modeArgs)))
        }
        
        private func handleChannelModes(_ message: IRCMessage) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in CHANNELMODES reply: \(message)")
                return
            }
            
            // expect at least two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in CHANNELMODES reply: \(message)")
                return
            }
            
            // first parameter is the channel name
            let channelName = message.parameters[0]
            
            // second parameter is the mode string
            let modeString = message.parameters[1]
            
            // remaining parameters, if present, are mode arguments
            var modeArgs = Array(message.parameters[2...])
            if let first = modeArgs.first {
                modeArgs[0] = first.dropLeadingColon()
            }
            
            self.connection.store.dispatch(.network(
                                            .channelModeReceived(
                                                connection: self.connection.connection,
                                                channelName: channelName,
                                                modeString: modeString,
                                                modeArgs: modeArgs)))
        }
        
        private func handleChannelCreationTime(_ message: IRCMessage) {
            // expect at least two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in CREATIONTIME reply: \(message)")
                return
            }
            
            // first parameter is the channel name
            let channelName = message.parameters[0]
            
            // second parameter is a unix timestamp representing the channel creation time
            guard let timestamp = Double(message.parameters[1]) else {
                print("ERROR: invalid timestamp in CREATIONTIME reply: \(message)")
                return
            }
            
            let creationTime = Date(timeIntervalSince1970: timestamp)
            let text = "Channel created on \(DateFormatter.displayDateFormatter.string(from: creationTime))"
            
            self.connection.store.dispatch(.network(
                                            .messageReceived(
                                                connection: self.connection.connection,
                                                channelName: channelName,
                                                message: ChannelMessage(
                                                    text: text,
                                                    variant: .other))))
        }
        
        private func handleUserModeIs(_ message: IRCMessage) {
            // expect at least one parameters
            if message.parameters.count < 1 {
                print("ERROR: not enough params in UMODEIS reply: \(message)")
                return
            }
            
            // first parameter is the current user mode
            let modeString = message.parameters[0]

            let text = "Current user mode is \(modeString)"
            
            self.connection.store.dispatch(.network(
                                            .messageReceived(
                                                connection: self.connection.connection,
                                                channelName: Connection.serverChannel,
                                                message: ChannelMessage(
                                                    text: text,
                                                    variant: .modeEvent))))
        }
        
        private func handleServerStatistic(_ message: IRCMessage) {
            // expect two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in statistic reply: \(message)")
                return
            }
            
            // first parameter is a numeric
            let number = message.parameters[0]
            
            // remaining parameters are the message
            let text = message.parameters[1...].joined(separator: " ").dropLeadingColon()
            
            connection.store.dispatch(.network(
                                        .messageReceived(
                                            connection: self.connection.connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: "\(number) \(text)",
                                                variant: .other))))
        }
        
        private func handleTryAgain(_ message: IRCMessage) {
            // expect at least one parameter
            if message.parameters.count < 1 {
                print("ERROR: not enough params in TRYAGAIN reply: \(message)")
                return
            }
            
            // if the first parameter starts with a colon, then assume the entire parameter list is an error message
            // otherwise, try to break out the command from the error message itself
            var text: String
            if message.parameters[0].first == ":" {
                text = message.parameters[0...].joined(separator: " ").dropLeadingColon()
            } else {
                // first parameter is the command
                let command = message.parameters[0]
                
                // remaining parameters are the error/retry message
                let reason = message.parameters[1...].joined(separator: " ").dropLeadingColon()
                
                text = "\(command) - \(reason)"
            }
            
            connection.store.dispatch(.network(
                                        .messageReceived(
                                            connection: self.connection.connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: text,
                                                variant: .error))))
        }
        
        private func handleUserAway(_ message: IRCMessage) {
            // expect at least one parameter
            if message.parameters.count < 1 {
                print("ERROR: not enough params in USERISAWAY reply: \(message)")
                return
            }
            
            // first parameter is the nick
            let nick = message.parameters[0]
            
            // remaining parameters are the away message
            let text = message.parameters[1...].joined(separator: " ").dropLeadingColon()
            
            connection.store.dispatch(.network(
                                        .userAwayReceived(
                                            connection: self.connection.connection,
                                            nick: nick,
                                            message: ChannelMessage(
                                                sender: nick,
                                                text: text,
                                                variant: .userAway))))
        }
        
        private func handleMotd(_ message: IRCMessage) {
            // expect at least one parameter
            if message.parameters.count < 1 {
                print("ERROR: not enough params in MOTD reply: \(message)")
                return
            }
            
            // all parameters are the message
            let text = message.parameters[0...].joined(separator: " ").dropLeadingColon()
            
            connection.store.dispatch(.network(
                                        .messageReceived(
                                            connection: self.connection.connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: text,
                                                variant: .motd))))
        }
        
        private func handleInviting(_ message: IRCMessage) {
            // expect at least two parameters
            if message.parameters.count < 2 {
                print("ERROR: not enough params in INVITING reply: \(message)")
                return
            }
            
            // first parameter is the nick of the invited user
            let nick = message.parameters[0]
            
            // second parameter is the channel name
            let channelName = message.parameters[1]
            
            connection.store.dispatch(.network(
                                        .inviteConfirmed(
                                            connection: self.connection.connection,
                                            channelName: channelName,
                                            nick: nick)))
        }
        
        private func handleWho(_ message: IRCMessage) {
            // expect at least five parameters
            if message.parameters.count < 5 {
                print("ERROR: not enough params in WHO reply: \(message)")
                return
            }
            
            // first parameter is the channel name the user is part of (or asterisk)
            let channelName = message.parameters[0]
            
            // second parameter is the username of the user
            let username = message.parameters[1]
            
            // third parameter is the hostname of the user
            let hostname = message.parameters[2]
            
            // fourth parameter is the server the user connected to
            let server = message.parameters[3]
            
            // fifth parameter is the user's nick
            let nick = message.parameters[4]
            
            // form a message and push it to the server channel
            let text = "\(channelName) - \(nick) (\(username)@\(hostname)) \(server)"
            
            connection.store.dispatch(.network(
                                        .messageReceived(
                                            connection: self.connection.connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: text,
                                                variant: .other))))
        }
        
        private func handleServerMessage(_ message: IRCMessage) {
            // combine parameters into a single string message
            let text = message.parameters.joined(separator: " ").dropLeadingColon()
            
            connection.store.dispatch(.network(
                                        .messageReceived(
                                            connection: self.connection.connection,
                                            channelName: Connection.serverChannel,
                                            message: ChannelMessage(
                                                text: text,
                                                variant: .other))))
        }
        
        private func handleCTCPMessage(_ message: IRCMessage, recipient: String, ctcpText: String) {
            let ctcpComponents = ctcpText.components(separatedBy: " ")
            guard let commandName = ctcpComponents.first else { return }
            let ctcpParameters = Array(ctcpComponents.dropFirst())
            
            switch CTCPCommand.fromString(name: commandName) {
            case .action:
                handleCTCPAction(message, recipient: recipient, ctcpParameters: ctcpParameters)
            case .version:
                handleCTCPVersion(message, recipient: recipient, ctcpParameters: ctcpParameters)
            default:
                break
            }
        }
        
        private func handleCTCPAction(_ message: IRCMessage, recipient: String, ctcpParameters: [String]) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in CTCP ACTION command: \(message)")
            }
            
            // all parameters are an action message, and are optional
            let text = ctcpParameters.joined(separator: " ")
            
            self.connection.store.dispatch(.network(
                                            .messageReceived(
                                                connection: self.connection.connection,
                                                channelName: recipient,
                                                message: ChannelMessage(
                                                    sender: message.prefix!.subject,
                                                    text: text,
                                                    variant: .action))))
        }
        
        private func handleCTCPVersion(_ message: IRCMessage, recipient: String, ctcpParameters: [String]) {
            // expect a valid prefix
            if message.prefix == nil {
                print("ERROR: no prefix in CTCP VERSION command: \(message)")
            }
            
            // format the client name with version
            var response = "Rapid IRC Client"
            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                response = "\(response) \(version)"
            }
            
            send("NOTICE \(message.prefix!.subject) :\u{01}\(response)\u{01}")
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
