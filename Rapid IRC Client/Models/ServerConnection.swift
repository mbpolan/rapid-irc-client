//
//  ServerConnection.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

import NIO
import SwiftUI

class ServerConnection {

    internal let server: ServerInfo
    internal let store: Store
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    private var handler: ClientHandler?

    init(server: ServerInfo, store: Store) {
        self.server = server
        self.store = store
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
                try bootstrap.connect(host: self.server.host, port: self.server.port).wait()
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
//            connection.store.dispatch(action: JoinedChannelAction(
//                connection: self.connection,
//                channel: Connection.serverChannel))

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
            case .nameReply:
                handleNameReply(ircMessage)

            case .welcome,
                 .created,
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
            var channel = message.parameters.first
            if channel == nil {
                print("ERROR: no channel in JOIN message: \(message)")
                return
            }

            channel = channel!.first == ":" ? channel!.subString(from: 1) : channel

            self.connection.store.dispatch(action: JoinedChannelAction(
                connection: self.connection,
                channel: channel!))
        }

        private func handlePart(_ message: IRCMessage) {
            let channel = message.parameters.first
            if channel == nil {
                print("ERROR: no channel in PART message: \(message)")
                return
            }

            self.connection.store.dispatch(action: PartChannelAction(
                connection: self.connection,
                channel: channel!))
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
            
            self.connection.store.dispatch(action: UsersInChannelAction(
                connection: self.connection,
                users: users,
                channel: channel))
        }

        private func handleServerMessage(_ message: IRCMessage) {
            // combine parameters into a single string message
            var text = message.parameters.joined(separator: " ")

            // drop leading colons
            if text.first == ":" {
                text = text.subString(from: 1)
            }

            self.connection.store.dispatch(action: MessageReceivedAction(
                connection: self.connection,
                message: text,
                channel: Connection.serverChannel))
        }

        private func dispatchMessage(_ message: IRCMessage) {
            self.connection.store.dispatch(action: MessageReceivedAction(
                connection: self.connection,
                message: message.raw,
                channel: Connection.serverChannel))
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
