////
////  ConnectionManager.swift
////  Rapid IRC Client
////
////  Created by Mike Polan on 10/24/20.
////
//
//import SwiftUI
//import NIO
//import Combine
//
//protocol ConnectionService {
//
//    func addConnection(info: AppState.ServerConnection.ServerInfo)
//}
//
//struct DefaultConnectionService: ConnectionService {
//
//    let appState: Store<AppState>
//
//    init(appState: Store<AppState>) {
//        self.appState = appState
//    }
//
//    func addConnection(info: AppState.ServerConnection.ServerInfo) {
//        let connection = AppState.ServerConnection(
//            info: info,
//            serverChannel: AppState.ServerConnection.IRCChannel())
//
//        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
//
//        let bootstrap = ClientBootstrap.init(group: group)
//            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
//            .channelInitializer { channel in
////                connection.channel = channel
//                return channel.pipeline.addHandler(ClientHandler(connection))
//        }
//
////        store.connections.append(connection)
////        store.currentConnection = connection.id
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            do {
//                try bootstrap.connect(host: info.server, port: info.port).wait()
//            } catch let error {
//                print(error)
//            }
//        }
//    }
//
//
//}
//
//extension DefaultConnectionService {
//    private class ClientHandler: ChannelInboundHandler {
//        typealias InboundIn = ByteBuffer
//        typealias OutboundOut = ByteBuffer
//
//        private let connection: AppState.ServerConnection
//
//        init(_ connection: AppState.ServerConnection) {
//            self.connection = connection
//        }
//
//        func channelActive(context: ChannelHandlerContext) {
//            print("connected")
//            let nick = connection.info.nick
//
//            send("NICK \(nick)", context: context)
//            send("USER guest 0 * :\(nick) \(nick)", context: context)
//        }
//
//        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
//            var buffer = unwrapInboundIn(data)
//            let bytes = buffer.readableBytes
//
//            if let received = buffer.readString(length: bytes) {
//                DispatchQueue.main.async {
////                    self.connection.serverChannel.messages.append(received)
//                }
//            }
//        }
//
//        func errorCaught(context: ChannelHandlerContext, error: Error) {
//            print(error)
//        }
//
//        private func send(_ message: String, context: ChannelHandlerContext) {
//            // each message must end with a carriage return/line feed sequence
//            let fullMessage = message + "\r\n"
//
//            // convert the message into ascii characters and write it into a new buffer
//            let data = fullMessage.compactMap { $0.asciiValue }
//            var buffer = context.channel.allocator.buffer(capacity: data.count)
//            buffer.writeBytes(data)
//
//            self.connection.channel!.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
//        }
//    }
//}
//
//struct StubConnectionService: ConnectionService {
//
//    func addConnection(info: AppState.ServerConnection.ServerInfo) {
//    }
//}
