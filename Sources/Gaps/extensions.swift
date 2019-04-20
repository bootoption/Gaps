/*
 * extensions.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

internal extension String {
        var isNumerical: Bool {
                return CharacterSet(charactersIn: "0123456789.-").isSuperset(of: CharacterSet(charactersIn: self))
        }
        
        var hasShortPrefix: Bool {
                return self.hasPrefix(.shortPrefix)
        }
        
        var hasLongPrefix: Bool {
                return self.hasPrefix(.longPrefix)
        }
        
        var isOption: Bool {
                return !self.isNumerical && (self.hasShortPrefix || self.hasLongPrefix)
        }
        
        func inSingleQuotes() -> String {
                return "'" + self + "'"
        }
        
        func padding(toLength length: Int) -> String {
                return self.padding(toLength: length, withPad: " ", startingAt: 0)
        }
        
        static var baseName: String {
                return (CommandLine.arguments[0] as NSString).lastPathComponent
        }
        
        static let shortPrefix = "-"
        static let longPrefix = "--"
        static let fileOperand = "-"
        static let stopOperand = "--"
}

internal extension Character {
        static let assignmentOperand: Character = "="
}

internal extension FileHandle {
        func write(string: String, terminator: String = "\n") {
                guard let data = (string + terminator).data(using: .utf8) else {
                        return
                }
                self.write(data)
        }
}
