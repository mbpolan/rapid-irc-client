//
//  ConnectionManager.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/24/20.
//

import SwiftUI
import NIO

protocol ConnectionService {

    func addConnection(info: ServerInfo)
}

struct DefaultConnectionService: ConnectionService {

    private let store: ConnectionsStore
    
    init(store: ConnectionsStore) {
        self.store = store
    }

    func addConnection(info: ServerInfo) {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let bootstrap = ClientBootstrap.init(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in
                channel.pipeline.addHandler(ClientHandler(info: info, channel: channel))
            }
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let channel = try bootstrap.connect(host: info.server, port: info.port).wait()
                
                store.connections.append(ServerConnection(info: info, channel: channel))
            } catch let error {
                print(error)
            }
        }
    }
}

extension DefaultConnectionService {
    private class ClientHandler: ChannelInboundHandler {
        typealias InboundIn = ByteBuffer
        typealias OutboundOut = ByteBuffer
        
        private let channel: Channel
        private let info: ServerInfo
        
        init(info: ServerInfo, channel: Channel) {
            self.channel = channel
            self.info = info
        }
        
        func channelActive(context: ChannelHandlerContext) {
            print("connected")
            
            send("NICK \(info.nick)", context: context)
            send("USER guest 0 * :\(info.nick) \(info.nick)", context: context)
        }
        
        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            var buffer = unwrapInboundIn(data)
            let bytes = buffer.readableBytes
            
            if let received = buffer.readString(length: bytes) {
                print(received)
            }
        }
        
        func errorCaught(context: ChannelHandlerContext, error: Error) {
            print(error)
        }
        
        private func send(_ message: String, context: ChannelHandlerContext) {
            // each message must end with a carriage return/line feed sequence
            let fullMessage = message + "\r\n"
            
            // convert the message into ascii characters and write it into a new buffer
            let data = fullMessage.compactMap { $0.asciiValue }
            var buffer = context.channel.allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)
            
            channel.writeAndFlush(wrapOutboundOut(buffer), promise: nil)
        }
    }
}

struct StubConnectionService: ConnectionService {

    func addConnection(info: ServerInfo) {
    }
}
