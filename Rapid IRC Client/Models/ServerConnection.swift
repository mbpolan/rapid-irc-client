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
            let parts = message.split(separator: " ")
            
            switch parts.first?.lowercased() {
            case "ping":
                handlePing(parts)
            default:
                dispatchMessage(message)
            }
            
        }
        
        private func handlePing(_ parts: [String.SubSequence]) {
            if parts.count > 1 {
                let server = String(parts.last!)
                send("PONG \(server)")
            } else {
                send("PONG")
            }
        }
        
        private func dispatchMessage(_ message: String) {
            DispatchQueue.main.async {
                self.connection.store.dispatch(action: MessageReceivedAction(
                    connection: self.connection,
                    message: message))
            }
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
