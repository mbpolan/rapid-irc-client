// Generated using Sourcery 1.0.2 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT



extension NetworkAction {
    internal var connect: ServerInfo? {
        get {
            guard case let .connect(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .connect = self, let newValue = newValue else { return }
            self = .connect(newValue)
        }
    }

    internal var isConnect: Bool {
        self.connect != nil
    }

    internal var reconnect: Connection? {
        get {
            guard case let .reconnect(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .reconnect = self, let newValue = newValue else { return }
            self = .reconnect(newValue)
        }
    }

    internal var isReconnect: Bool {
        self.reconnect != nil
    }

    internal var disconnect: Connection? {
        get {
            guard case let .disconnect(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .disconnect = self, let newValue = newValue else { return }
            self = .disconnect(newValue)
        }
    }

    internal var isDisconnect: Bool {
        self.disconnect != nil
    }

    internal var messageSent: (IRCChannel, String)? {
        get {
            guard case let .messageSent(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .messageSent = self, let newValue = newValue else { return }
            self = .messageSent(newValue.0, newValue.1)
        }
    }

    internal var isMessageSent: Bool {
        self.messageSent != nil
    }

    internal var connectionAdded: (Connection, IRCChannel)? {
        get {
            guard case let .connectionAdded(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .connectionAdded = self, let newValue = newValue else { return }
            self = .connectionAdded(newValue.0, newValue.1)
        }
    }

    internal var isConnectionAdded: Bool {
        self.connectionAdded != nil
    }

    internal var connectionStateChanged: (Connection, Bool)? {
        get {
            guard case let .connectionStateChanged(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .connectionStateChanged = self, let newValue = newValue else { return }
            self = .connectionStateChanged(newValue.0, newValue.1)
        }
    }

    internal var isConnectionStateChanged: Bool {
        self.connectionStateChanged != nil
    }

    internal var welcomeReceived: (Connection, String)? {
        get {
            guard case let .welcomeReceived(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .welcomeReceived = self, let newValue = newValue else { return }
            self = .welcomeReceived(newValue.0, newValue.1)
        }
    }

    internal var isWelcomeReceived: Bool {
        self.welcomeReceived != nil
    }

    internal var messageReceived: (IRCChannel, ChannelMessage)? {
        get {
            guard case let .messageReceived(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .messageReceived = self, let newValue = newValue else { return }
            self = .messageReceived(newValue.0, newValue.1)
        }
    }

    internal var isMessageReceived: Bool {
        self.messageReceived != nil
    }

    internal var channelTopic: (Connection, String, String)? {
        get {
            guard case let .channelTopic(associatedValue0, associatedValue1, associatedValue2) = self else { return nil }
            return (associatedValue0, associatedValue1, associatedValue2)
        }
        set {
            guard case .channelTopic = self, let newValue = newValue else { return }
            self = .channelTopic(newValue.0, newValue.1, newValue.2)
        }
    }

    internal var isChannelTopic: Bool {
        self.channelTopic != nil
    }

    internal var usersInChannel: (Connection, String, [User])? {
        get {
            guard case let .usersInChannel(associatedValue0, associatedValue1, associatedValue2) = self else { return nil }
            return (associatedValue0, associatedValue1, associatedValue2)
        }
        set {
            guard case .usersInChannel = self, let newValue = newValue else { return }
            self = .usersInChannel(newValue.0, newValue.1, newValue.2)
        }
    }

    internal var isUsersInChannel: Bool {
        self.usersInChannel != nil
    }

    internal var joinedChannel: (Connection, String, String, String)? {
        get {
            guard case let .joinedChannel(associatedValue0, associatedValue1, associatedValue2, associatedValue3) = self else { return nil }
            return (associatedValue0, associatedValue1, associatedValue2, associatedValue3)
        }
        set {
            guard case .joinedChannel = self, let newValue = newValue else { return }
            self = .joinedChannel(newValue.0, newValue.1, newValue.2, newValue.3)
        }
    }

    internal var isJoinedChannel: Bool {
        self.joinedChannel != nil
    }

    internal var partedChannel: (Connection, String, String, String, String?)? {
        get {
            guard case let .partedChannel(associatedValue0, associatedValue1, associatedValue2, associatedValue3, associatedValue4) = self else { return nil }
            return (associatedValue0, associatedValue1, associatedValue2, associatedValue3, associatedValue4)
        }
        set {
            guard case .partedChannel = self, let newValue = newValue else { return }
            self = .partedChannel(newValue.0, newValue.1, newValue.2, newValue.3, newValue.4)
        }
    }

    internal var isPartedChannel: Bool {
        self.partedChannel != nil
    }

    internal var privateMessageReceived: (Connection, String, String, String, ChannelMessage)? {
        get {
            guard case let .privateMessageReceived(associatedValue0, associatedValue1, associatedValue2, associatedValue3, associatedValue4) = self else { return nil }
            return (associatedValue0, associatedValue1, associatedValue2, associatedValue3, associatedValue4)
        }
        set {
            guard case .privateMessageReceived = self, let newValue = newValue else { return }
            self = .privateMessageReceived(newValue.0, newValue.1, newValue.2, newValue.3, newValue.4)
        }
    }

    internal var isPrivateMessageReceived: Bool {
        self.privateMessageReceived != nil
    }

    internal var errorReceived: (Connection, ChannelMessage)? {
        get {
            guard case let .errorReceived(associatedValue0, associatedValue1) = self else { return nil }
            return (associatedValue0, associatedValue1)
        }
        set {
            guard case .errorReceived = self, let newValue = newValue else { return }
            self = .errorReceived(newValue.0, newValue.1)
        }
    }

    internal var isErrorReceived: Bool {
        self.errorReceived != nil
    }

}

extension UIAction {
    internal var toggleConnectSheet: Bool? {
        get {
            guard case let .toggleConnectSheet(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .toggleConnectSheet = self, let newValue = newValue else { return }
            self = .toggleConnectSheet(newValue)
        }
    }

    internal var isToggleConnectSheet: Bool {
        self.toggleConnectSheet != nil
    }

    internal var connectionAdded: Connection? {
        get {
            guard case let .connectionAdded(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .connectionAdded = self, let newValue = newValue else { return }
            self = .connectionAdded(newValue)
        }
    }

    internal var isConnectionAdded: Bool {
        self.connectionAdded != nil
    }

    internal var changeChannel: IRCChannel? {
        get {
            guard case let .changeChannel(associatedValue0) = self else { return nil }
            return (associatedValue0)
        }
        set {
            guard case .changeChannel = self, let newValue = newValue else { return }
            self = .changeChannel(newValue)
        }
    }

    internal var isChangeChannel: Bool {
        self.changeChannel != nil
    }

}
