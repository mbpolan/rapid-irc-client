// Generated using Sourcery 1.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT



extension NetworkAction {
    internal var connect: ServerInfo? {
        get {
            guard case let .connect(serverInfo) = self else { return nil }
            return (serverInfo)
        }
        set {
            guard case .connect = self, let newValue = newValue else { return }
            self = .connect(serverInfo: newValue)
        }
    }

    internal var isConnect: Bool {
        self.connect != nil
    }

    internal var reconnect: Connection? {
        get {
            guard case let .reconnect(connection) = self else { return nil }
            return (connection)
        }
        set {
            guard case .reconnect = self, let newValue = newValue else { return }
            self = .reconnect(connection: newValue)
        }
    }

    internal var isReconnect: Bool {
        self.reconnect != nil
    }

    internal var disconnect: Connection? {
        get {
            guard case let .disconnect(connection) = self else { return nil }
            return (connection)
        }
        set {
            guard case .disconnect = self, let newValue = newValue else { return }
            self = .disconnect(connection: newValue)
        }
    }

    internal var isDisconnect: Bool {
        self.disconnect != nil
    }

    internal var messageSent: (channel: IRCChannel, rawMessage: String)? {
        get {
            guard case let .messageSent(channel, rawMessage) = self else { return nil }
            return (channel, rawMessage)
        }
        set {
            guard case .messageSent = self, let newValue = newValue else { return }
            self = .messageSent(channel: newValue.0, rawMessage: newValue.1)
        }
    }

    internal var isMessageSent: Bool {
        self.messageSent != nil
    }

    internal var addChannelNotification: (connection: Connection, channelName: String, notification: IRCChannel.Notification)? {
        get {
            guard case let .addChannelNotification(connection, channelName, notification) = self else { return nil }
            return (connection, channelName, notification)
        }
        set {
            guard case .addChannelNotification = self, let newValue = newValue else { return }
            self = .addChannelNotification(connection: newValue.0, channelName: newValue.1, notification: newValue.2)
        }
    }

    internal var isAddChannelNotification: Bool {
        self.addChannelNotification != nil
    }

    internal var connectionAdded: (connection: Connection, serverChannel: IRCChannel)? {
        get {
            guard case let .connectionAdded(connection, serverChannel) = self else { return nil }
            return (connection, serverChannel)
        }
        set {
            guard case .connectionAdded = self, let newValue = newValue else { return }
            self = .connectionAdded(connection: newValue.0, serverChannel: newValue.1)
        }
    }

    internal var isConnectionAdded: Bool {
        self.connectionAdded != nil
    }

    internal var connectionStateChanged: (connection: Connection, connectionState: Connection.State)? {
        get {
            guard case let .connectionStateChanged(connection, connectionState) = self else { return nil }
            return (connection, connectionState)
        }
        set {
            guard case .connectionStateChanged = self, let newValue = newValue else { return }
            self = .connectionStateChanged(connection: newValue.0, connectionState: newValue.1)
        }
    }

    internal var isConnectionStateChanged: Bool {
        self.connectionStateChanged != nil
    }

    internal var welcomeReceived: (connection: Connection, identifier: String)? {
        get {
            guard case let .welcomeReceived(connection, identifier) = self else { return nil }
            return (connection, identifier)
        }
        set {
            guard case .welcomeReceived = self, let newValue = newValue else { return }
            self = .welcomeReceived(connection: newValue.0, identifier: newValue.1)
        }
    }

    internal var isWelcomeReceived: Bool {
        self.welcomeReceived != nil
    }

    internal var messageReceived: (connection: Connection, channelName: String, message: ChannelMessage)? {
        get {
            guard case let .messageReceived(connection, channelName, message) = self else { return nil }
            return (connection, channelName, message)
        }
        set {
            guard case .messageReceived = self, let newValue = newValue else { return }
            self = .messageReceived(connection: newValue.0, channelName: newValue.1, message: newValue.2)
        }
    }

    internal var isMessageReceived: Bool {
        self.messageReceived != nil
    }

    internal var channelTopic: (connection: Connection, channelName: String, topic: String)? {
        get {
            guard case let .channelTopic(connection, channelName, topic) = self else { return nil }
            return (connection, channelName, topic)
        }
        set {
            guard case .channelTopic = self, let newValue = newValue else { return }
            self = .channelTopic(connection: newValue.0, channelName: newValue.1, topic: newValue.2)
        }
    }

    internal var isChannelTopic: Bool {
        self.channelTopic != nil
    }

    internal var usernamesReceived: (connection: Connection, channelName: String, usernames: [String])? {
        get {
            guard case let .usernamesReceived(connection, channelName, usernames) = self else { return nil }
            return (connection, channelName, usernames)
        }
        set {
            guard case .usernamesReceived = self, let newValue = newValue else { return }
            self = .usernamesReceived(connection: newValue.0, channelName: newValue.1, usernames: newValue.2)
        }
    }

    internal var isUsernamesReceived: Bool {
        self.usernamesReceived != nil
    }

    internal var updateChannelUsers: (connection: Connection, channelName: String, users: [User])? {
        get {
            guard case let .updateChannelUsers(connection, channelName, users) = self else { return nil }
            return (connection, channelName, users)
        }
        set {
            guard case .updateChannelUsers = self, let newValue = newValue else { return }
            self = .updateChannelUsers(connection: newValue.0, channelName: newValue.1, users: newValue.2)
        }
    }

    internal var isUpdateChannelUsers: Bool {
        self.updateChannelUsers != nil
    }

    internal var joinedChannel: (connection: Connection, channelName: String, identifier: IRCMessage.Prefix)? {
        get {
            guard case let .joinedChannel(connection, channelName, identifier) = self else { return nil }
            return (connection, channelName, identifier)
        }
        set {
            guard case .joinedChannel = self, let newValue = newValue else { return }
            self = .joinedChannel(connection: newValue.0, channelName: newValue.1, identifier: newValue.2)
        }
    }

    internal var isJoinedChannel: Bool {
        self.joinedChannel != nil
    }

    internal var partedChannel: (connection: Connection, channelName: String, identifier: String, nick: String, reason: String?)? {
        get {
            guard case let .partedChannel(connection, channelName, identifier, nick, reason) = self else { return nil }
            return (connection, channelName, identifier, nick, reason)
        }
        set {
            guard case .partedChannel = self, let newValue = newValue else { return }
            self = .partedChannel(connection: newValue.0, channelName: newValue.1, identifier: newValue.2, nick: newValue.3, reason: newValue.4)
        }
    }

    internal var isPartedChannel: Bool {
        self.partedChannel != nil
    }

    internal var channelStateChanged: (connection: Connection, channelName: String, channelState: IRCChannel.State)? {
        get {
            guard case let .channelStateChanged(connection, channelName, channelState) = self else { return nil }
            return (connection, channelName, channelState)
        }
        set {
            guard case .channelStateChanged = self, let newValue = newValue else { return }
            self = .channelStateChanged(connection: newValue.0, channelName: newValue.1, channelState: newValue.2)
        }
    }

    internal var isChannelStateChanged: Bool {
        self.channelStateChanged != nil
    }

    internal var clientJoinedChannel: (connection: Connection, channelName: String)? {
        get {
            guard case let .clientJoinedChannel(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .clientJoinedChannel = self, let newValue = newValue else { return }
            self = .clientJoinedChannel(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isClientJoinedChannel: Bool {
        self.clientJoinedChannel != nil
    }

    internal var clientLeftChannel: (connection: Connection, channelName: String)? {
        get {
            guard case let .clientLeftChannel(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .clientLeftChannel = self, let newValue = newValue else { return }
            self = .clientLeftChannel(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isClientLeftChannel: Bool {
        self.clientLeftChannel != nil
    }

    internal var userLeftChannel: (conn: Connection, channelName: String, user: User)? {
        get {
            guard case let .userLeftChannel(conn, channelName, user) = self else { return nil }
            return (conn, channelName, user)
        }
        set {
            guard case .userLeftChannel = self, let newValue = newValue else { return }
            self = .userLeftChannel(conn: newValue.0, channelName: newValue.1, user: newValue.2)
        }
    }

    internal var isUserLeftChannel: Bool {
        self.userLeftChannel != nil
    }

    internal var removeChannel: (connection: Connection, channelName: String)? {
        get {
            guard case let .removeChannel(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .removeChannel = self, let newValue = newValue else { return }
            self = .removeChannel(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isRemoveChannel: Bool {
        self.removeChannel != nil
    }

    internal var privateMessageReceived: (connection: Connection, identifier: String, nick: String, recipient: String, message: ChannelMessage)? {
        get {
            guard case let .privateMessageReceived(connection, identifier, nick, recipient, message) = self else { return nil }
            return (connection, identifier, nick, recipient, message)
        }
        set {
            guard case .privateMessageReceived = self, let newValue = newValue else { return }
            self = .privateMessageReceived(connection: newValue.0, identifier: newValue.1, nick: newValue.2, recipient: newValue.3, message: newValue.4)
        }
    }

    internal var isPrivateMessageReceived: Bool {
        self.privateMessageReceived != nil
    }

    internal var errorReceived: (connection: Connection, message: ChannelMessage)? {
        get {
            guard case let .errorReceived(connection, message) = self else { return nil }
            return (connection, message)
        }
        set {
            guard case .errorReceived = self, let newValue = newValue else { return }
            self = .errorReceived(connection: newValue.0, message: newValue.1)
        }
    }

    internal var isErrorReceived: Bool {
        self.errorReceived != nil
    }

}

extension UIAction {
    internal var toggleConnectSheet: Bool? {
        get {
            guard case let .toggleConnectSheet(shown) = self else { return nil }
            return (shown)
        }
        set {
            guard case .toggleConnectSheet = self, let newValue = newValue else { return }
            self = .toggleConnectSheet(shown: newValue)
        }
    }

    internal var isToggleConnectSheet: Bool {
        self.toggleConnectSheet != nil
    }

    internal var connectionAdded: Connection? {
        get {
            guard case let .connectionAdded(connection) = self else { return nil }
            return (connection)
        }
        set {
            guard case .connectionAdded = self, let newValue = newValue else { return }
            self = .connectionAdded(connection: newValue)
        }
    }

    internal var isConnectionAdded: Bool {
        self.connectionAdded != nil
    }

    internal var changeChannel: (connection: Connection, channelName: String)? {
        get {
            guard case let .changeChannel(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .changeChannel = self, let newValue = newValue else { return }
            self = .changeChannel(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isChangeChannel: Bool {
        self.changeChannel != nil
    }

    internal var closeChannel: (connection: Connection, channelName: String)? {
        get {
            guard case let .closeChannel(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .closeChannel = self, let newValue = newValue else { return }
            self = .closeChannel(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isCloseChannel: Bool {
        self.closeChannel != nil
    }

}
