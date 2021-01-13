//
//  Actions.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 11/23/20.
//

// MARK: - Actions
enum UIAction {
    case toggleConnectSheet(Bool)
    case connectionAdded(Connection)
    case changeChannel(IRCChannel)
}

// MARK: - Action properties
extension UIAction {
    public var toggleConnectSheet: Bool? {
        get {
            guard case let .toggleConnectSheet(value) = self else { return nil }
            return value
        }
        set {
            guard case .toggleConnectSheet = self, let value = newValue else { return }
            self = .toggleConnectSheet(value)
        }
    }
    
    public var connectionAdded: Connection? {
        get {
            guard case let .connectionAdded(value) = self else { return nil }
            return value
        }
        set {
            guard case .connectionAdded = self, let value = newValue else { return }
            self = .connectionAdded(value)
        }
    }
    
    public var changeChannel: IRCChannel? {
        get {
            guard case let .changeChannel(value) = self else { return nil }
            return value
        }
        set {
            guard case .changeChannel = self, let value = newValue else { return }
            self = .changeChannel(value)
        }
    }
}
