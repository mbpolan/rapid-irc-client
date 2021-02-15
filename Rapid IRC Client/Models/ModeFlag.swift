//
//  ModeFlag.swift
//  Rapid IRC Client
//
//  Created by Mike Polan on 2/14/21.
//

import Foundation

enum ModeFlag: Character {
    case ban = "b"
    case clientLimit = "l"
    case exception = "e"
    case halfOperator = "h"
    case inviteException = "I"
    case inviteOnly = "i"
    case key = "k"
    case moderated = "m"
    case noExternalMessages = "n"
    case `operator` = "o"
    case protectedTopic = "t"
    case secret = "s"
    case voice = "v"
}

enum ModeFlagAction: Character {
    case add = "+"
    case remove = "-"
}
