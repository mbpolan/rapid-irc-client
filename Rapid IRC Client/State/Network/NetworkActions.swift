//
//  Actions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 10/28/20.
//

// MARK: - Actions
enum NetworkAction {
    case connect(ServerInfo)
    case messageSent(IRCChannel, String)
    
    case connectionAdded(Connection, IRCChannel)
    case welcomeReceived(Connection, String)
    case messageReceived(IRCChannel, ChannelMessage)
    case channelTopic(Connection, String, String)
    case usersInChannel(Connection, String, [User])
    case joinedChannel(Connection, String, String, String)
    case partedChannel(Connection, String, String, String, String?)
    case privateMessageReceived(Connection, String, String, String, ChannelMessage)
    
    case errorReceived(Connection, ChannelMessage)
}

// MARK: - Action properties
extension NetworkAction {
    public var connect: ServerInfo? {
        get {
            guard case let .connect(value) = self else { return nil }
            return value
        }
        set {
            guard case .connect = self, let value = newValue else { return }
            self = .connect(value)
        }
    }
    
    public var messageSent: (IRCChannel, String)? {
        get {
            guard case let .messageSent(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .messageSent = self, let (value1, value2) = newValue else { return }
            self = .messageSent(value1, value2)
        }
    }
    
    public var connectionAdded: (Connection, IRCChannel)? {
        get {
            guard case let .connectionAdded(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .connectionAdded = self, let (value1, value2) = newValue else { return }
            self = .connectionAdded(value1, value2)
        }
    }
    
    public var welcomeReceived: (Connection, String)? {
        get {
            guard case let .welcomeReceived(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .welcomeReceived = self, let (value1, value2) = newValue else { return }
            self = .welcomeReceived(value1, value2)
        }
    }
    
    public var messageReceived: (IRCChannel, ChannelMessage)? {
        get {
            guard case let .messageReceived(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .messageReceived = self, let (value1, value2) = newValue else { return }
            self = .messageReceived(value1, value2)
        }
    }
    
    public var channelTopic: (Connection, String, String)? {
        get {
            guard case let .channelTopic(value1, value2, value3) = self else { return nil }
            return (value1, value2, value3)
        }
        set {
            guard case .channelTopic = self, let (value1, value2, value3) = newValue else { return }
            self = .channelTopic(value1, value2, value3)
        }
    }
    
    public var usersInChannel: (Connection, String, [User])? {
        get {
            guard case let .usersInChannel(value1, value2, value3) = self else { return nil }
            return (value1, value2, value3)
        }
        set {
            guard case .usersInChannel = self, let (value1, value2, value3) = newValue else { return }
            self = .usersInChannel(value1, value2, value3)
        }
    }
    
    public var joinedChannel: (Connection, String, String, String)? {
        get {
            guard case let .joinedChannel(value1, value2, value3, value4) = self else { return nil }
            return (value1, value2, value3, value4)
        }
        set {
            guard case .joinedChannel = self, let (value1, value2, value3, value4) = newValue else { return }
            self = .joinedChannel(value1, value2, value3, value4)
        }
    }
    
    public var partedChannel: (Connection, String, String, String, String?)? {
        get {
            guard case let .partedChannel(value1, value2, value3, value4, value5) = self else { return nil }
            return (value1, value2, value3, value4, value5)
        }
        set {
            guard case .partedChannel = self, let (value1, value2, value3, value4, value5) = newValue else { return }
            self = .partedChannel(value1, value2, value3, value4, value5)
        }
    }
    
    public var privateMessageReceived: (Connection, String, String, String, ChannelMessage)? {
        get {
            guard case let .privateMessageReceived(value1, value2, value3, value4, value5) = self else { return nil }
            return (value1, value2, value3, value4, value5)
        }
        set {
            guard case .privateMessageReceived = self, let (value1, value2, value3, value4, value5) = newValue else { return }
            self = .privateMessageReceived(value1, value2, value3, value4, value5)
        }
    }
    
    public var errorReceived: (Connection, ChannelMessage)? {
        get {
            guard case let .errorReceived(value1, value2) = self else { return nil }
            return (value1, value2)
        }
        set {
            guard case .errorReceived = self, let (value1, value2) = newValue else { return }
            self = .errorReceived(value1, value2)
        }
    }
}
