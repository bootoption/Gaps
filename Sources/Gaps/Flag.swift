/*
 * Flag.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

public struct Flag {
        var short: String? = nil
        
        var long: String? = nil
        
        var values: [String] {
                switch (short, long) {
                case (.some, .some):
                        return [short!, long!]
                case (.some, .none):
                        return [short!]
                case (.none, .some):
                        return [long!]
                default:
                        return []
                }
        }
        
        private func flagError(_ message: String, _ flags: [String]) -> Never {
                let message = "(flags: " + String(describing: flags) + ")\n" + message
                fatalError(message)
        }
        
        init(strings: [String]) {
                guard strings.filter({ $0.hasShortPrefix || $0.hasLongPrefix }).count == 0 else {
                        flagError("flags cannot start with \(String.shortPrefix) or \(String.longPrefix), prefix should be ommited when specifying flags", strings)
                }
                
                guard strings.filter({ $0.count == 0 }).count == 0 else {
                        flagError("an option's flag cannot have zero length", strings)
                }
                
                let flags = strings.sorted { $0.count < $1.count }
                
                switch flags.count {
                case 1:
                        switch flags[0].count {
                        case 1:
                                short = String.shortPrefix + flags[0]
                        default:
                                long = String.longPrefix + flags[0]
                        }
                case 2:
                        guard flags[0].count == 1, flags[1].count > 1 else {
                                flagError("an option with 2 flags requires one short and one long flag", flags)
                        }
                        short = String.shortPrefix + flags[0]
                        long = String.longPrefix + flags[1]
                default:
                        flagError("an option requires either short, long, or short + long flags", flags)
                }
        }
}
