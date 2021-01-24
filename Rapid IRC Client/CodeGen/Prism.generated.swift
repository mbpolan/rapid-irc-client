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

    internal var hostnameReceived: (connection: Connection, hostname: String)? {
        get {
            guard case let .hostnameReceived(connection, hostname) = self else { return nil }
            return (connection, hostname)
        }
        set {
            guard case .hostnameReceived = self, let newValue = newValue else { return }
            self = .hostnameReceived(connection: newValue.0, hostname: newValue.1)
        }
    }

    internal var isHostnameReceived: Bool {
        self.hostnameReceived != nil
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

    internal var channelTopicReceived: (connection: Connection, channelName: String, topic: String)? {
        get {
            guard case let .channelTopicReceived(connection, channelName, topic) = self else { return nil }
            return (connection, channelName, topic)
        }
        set {
            guard case .channelTopicReceived = self, let newValue = newValue else { return }
            self = .channelTopicReceived(connection: newValue.0, channelName: newValue.1, topic: newValue.2)
        }
    }

    internal var isChannelTopicReceived: Bool {
        self.channelTopicReceived != nil
    }

    internal var channelTopicChanged: (connection: Connection, channelName: String, identifier: IRCMessage.Prefix, topic: String)? {
        get {
            guard case let .channelTopicChanged(connection, channelName, identifier, topic) = self else { return nil }
            return (connection, channelName, identifier, topic)
        }
        set {
            guard case .channelTopicChanged = self, let newValue = newValue else { return }
            self = .channelTopicChanged(connection: newValue.0, channelName: newValue.1, identifier: newValue.2, topic: newValue.3)
        }
    }

    internal var isChannelTopicChanged: Bool {
        self.channelTopicChanged != nil
    }

    internal var channelTopicMetadataReceived: (connection: Connection, channelName: String, who: String, when: Date)? {
        get {
            guard case let .channelTopicMetadataReceived(connection, channelName, who, when) = self else { return nil }
            return (connection, channelName, who, when)
        }
        set {
            guard case .channelTopicMetadataReceived = self, let newValue = newValue else { return }
            self = .channelTopicMetadataReceived(connection: newValue.0, channelName: newValue.1, who: newValue.2, when: newValue.3)
        }
    }

    internal var isChannelTopicMetadataReceived: Bool {
        self.channelTopicMetadataReceived != nil
    }

    internal var updateChannelTopic: (connection: Connection, channelName: String, topic: String)? {
        get {
            guard case let .updateChannelTopic(connection, channelName, topic) = self else { return nil }
            return (connection, channelName, topic)
        }
        set {
            guard case .updateChannelTopic = self, let newValue = newValue else { return }
            self = .updateChannelTopic(connection: newValue.0, channelName: newValue.1, topic: newValue.2)
        }
    }

    internal var isUpdateChannelTopic: Bool {
        self.updateChannelTopic != nil
    }

    internal var updateChannelTopicMetadata: (connection: Connection, channelName: String, who: String, when: Date)? {
        get {
            guard case let .updateChannelTopicMetadata(connection, channelName, who, when) = self else { return nil }
            return (connection, channelName, who, when)
        }
        set {
            guard case .updateChannelTopicMetadata = self, let newValue = newValue else { return }
            self = .updateChannelTopicMetadata(connection: newValue.0, channelName: newValue.1, who: newValue.2, when: newValue.3)
        }
    }

    internal var isUpdateChannelTopicMetadata: Bool {
        self.updateChannelTopicMetadata != nil
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

    internal var allUsernamesReceived: (connection: Connection, channelName: String)? {
        get {
            guard case let .allUsernamesReceived(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .allUsernamesReceived = self, let newValue = newValue else { return }
            self = .allUsernamesReceived(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isAllUsernamesReceived: Bool {
        self.allUsernamesReceived != nil
    }

    internal var applyIncomingChannelUsers: (connection: Connection, channelName: String)? {
        get {
            guard case let .applyIncomingChannelUsers(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .applyIncomingChannelUsers = self, let newValue = newValue else { return }
            self = .applyIncomingChannelUsers(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isApplyIncomingChannelUsers: Bool {
        self.applyIncomingChannelUsers != nil
    }

    internal var addIncomingChannelUsers: (connection: Connection, channelName: String, users: Set<User>)? {
        get {
            guard case let .addIncomingChannelUsers(connection, channelName, users) = self else { return nil }
            return (connection, channelName, users)
        }
        set {
            guard case .addIncomingChannelUsers = self, let newValue = newValue else { return }
            self = .addIncomingChannelUsers(connection: newValue.0, channelName: newValue.1, users: newValue.2)
        }
    }

    internal var isAddIncomingChannelUsers: Bool {
        self.addIncomingChannelUsers != nil
    }

    internal var clearIncomingChannelUsers: (connection: Connection, channelName: String)? {
        get {
            guard case let .clearIncomingChannelUsers(connection, channelName) = self else { return nil }
            return (connection, channelName)
        }
        set {
            guard case .clearIncomingChannelUsers = self, let newValue = newValue else { return }
            self = .clearIncomingChannelUsers(connection: newValue.0, channelName: newValue.1)
        }
    }

    internal var isClearIncomingChannelUsers: Bool {
        self.clearIncomingChannelUsers != nil
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

    internal var userJoinedChannel: (connection: Connection, channelName: String, user: User)? {
        get {
            guard case let .userJoinedChannel(connection, channelName, user) = self else { return nil }
            return (connection, channelName, user)
        }
        set {
            guard case .userJoinedChannel = self, let newValue = newValue else { return }
            self = .userJoinedChannel(connection: newValue.0, channelName: newValue.1, user: newValue.2)
        }
    }

    internal var isUserJoinedChannel: Bool {
        self.userJoinedChannel != nil
    }

    internal var clientJoinedChannel: (connection: Connection, channelName: String, descriptor: IRCChannel.Descriptor)? {
        get {
            guard case let .clientJoinedChannel(connection, channelName, descriptor) = self else { return nil }
            return (connection, channelName, descriptor)
        }
        set {
            guard case .clientJoinedChannel = self, let newValue = newValue else { return }
            self = .clientJoinedChannel(connection: newValue.0, channelName: newValue.1, descriptor: newValue.2)
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

    internal var privateMessageReceived: (connection: Connection, identifier: IRCMessage.Prefix, recipient: String, message: ChannelMessage)? {
        get {
            guard case let .privateMessageReceived(connection, identifier, recipient, message) = self else { return nil }
            return (connection, identifier, recipient, message)
        }
        set {
            guard case .privateMessageReceived = self, let newValue = newValue else { return }
            self = .privateMessageReceived(connection: newValue.0, identifier: newValue.1, recipient: newValue.2, message: newValue.3)
        }
    }

    internal var isPrivateMessageReceived: Bool {
        self.privateMessageReceived != nil
    }

    internal var userQuit: (connection: Connection, identifier: IRCMessage.Prefix, reason: String)? {
        get {
            guard case let .userQuit(connection, identifier, reason) = self else { return nil }
            return (connection, identifier, reason)
        }
        set {
            guard case .userQuit = self, let newValue = newValue else { return }
            self = .userQuit(connection: newValue.0, identifier: newValue.1, reason: newValue.2)
        }
    }

    internal var isUserQuit: Bool {
        self.userQuit != nil
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

    internal var toggleChatTimestamps: Bool? {
        get {
            guard case let .toggleChatTimestamps(shown) = self else { return nil }
            return (shown)
        }
        set {
            guard case .toggleChatTimestamps = self, let newValue = newValue else { return }
            self = .toggleChatTimestamps(shown: newValue)
        }
    }

    internal var isToggleChatTimestamps: Bool {
        self.toggleChatTimestamps != nil
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

    internal var closeChannel: (connection: Connection, channelName: String, descriptor: IRCChannel.Descriptor)? {
        get {
            guard case let .closeChannel(connection, channelName, descriptor) = self else { return nil }
            return (connection, channelName, descriptor)
        }
        set {
            guard case .closeChannel = self, let newValue = newValue else { return }
            self = .closeChannel(connection: newValue.0, channelName: newValue.1, descriptor: newValue.2)
        }
    }

    internal var isCloseChannel: Bool {
        self.closeChannel != nil
    }

}
