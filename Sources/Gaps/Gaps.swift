/*
 * Gaps.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

internal let shortPrefix = "-"
internal let longPrefix = "--"
internal let fileOperand = "-"
internal let stopOperand = "--"
internal let assignmentOperand: Character = "="
internal var standardError = FileHandle.standardError
internal var baseName = (CommandLine.arguments[0] as NSString).lastPathComponent

internal struct Flag {
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
        
        init(flags: [String]) {
                guard flags.filter({ $0.hasShortPrefix || $0.hasLongPrefix }).count == 0 else {
                        flagError("flags cannot start with \(shortPrefix) or \(longPrefix), prefix should be ommited when specifying flags", flags)
                }
                
                guard flags.filter({ $0.count == 0 }).count == 0 else {
                        flagError("an option's flag cannot have zero length", flags)
                }
                
                let flags = flags.sorted { $0.count < $1.count }
                
                switch flags.count {
                case 1:
                        switch flags[0].count {
                        case 1:
                                short = shortPrefix + flags[0]
                        default:
                                long = longPrefix + flags[0]
                        }
                case 2:
                        guard flags[0].count == 1, flags[1].count > 1 else {
                                flagError("an option with 2 flags requires one short and one long flag", flags)
                        }
                        short = shortPrefix + flags[0]
                        long = longPrefix + flags[1]
                default:
                        flagError("an option requires either short, long, or short + long flags", flags)
                }
        }
}

internal extension String {
        var isNumerical: Bool {
                return CharacterSet(charactersIn: "0123456789.-").isSuperset(of: CharacterSet(charactersIn: self))
        }
        
        var hasShortPrefix: Bool {
                return self.hasPrefix(shortPrefix)
        }
        
        var hasLongPrefix: Bool {
                return self.hasPrefix(longPrefix)
        }
        
        func inSingleQuotes() -> String {
                return "'" + self + "'"
        }
        
        func padding(toLength length: Int) -> String {
                return self.padding(toLength: length, withPad: " ", startingAt: 0)
        }
}

internal extension FileHandle {
        func write(string: String, terminator: String = "\n") {
                guard let data = (string + terminator).data(using: .utf8) else {
                        return
                }                
                self.write(data)
        }
}

internal struct Flags {
        var short = [String]()
        var long = [String]()
}

public enum FileOptionError: Error {
        case pathNotSet(option: Option)
        case fileNotFound(path: String, option: Option)
        case isDirectory(path: String, option: Option)
        case isNotReadable(path: String, option: Option)
        case couldNotOpenForReading(path: String, option: Option)
        case isNotWritable(path: String, option: Option)
        case couldNotCreate(path: String, option: Option)
        case couldNotOpenForWriting(path: String, option: Option)
        public var string: String {
                switch self {
                case .pathNotSet(option: let option):
                        return "\(option.description) path not set"
                case .fileNotFound(path: let path, option: let option):
                        return "\(option.description) file not found at path \(path.inSingleQuotes())"
                case .isDirectory(path: let path, option: let option):
                        return "\(option.description) path \(path.inSingleQuotes()) is a directory"
                case .isNotReadable(path: let path, option: let option):
                        return "\(option.description) path \(path.inSingleQuotes()) is not readable"
                case .couldNotOpenForReading(path: let path, option: let option):
                        return "\(option.description) could not open file for reading at path \(path.inSingleQuotes())"
                case .isNotWritable(path: let path, option: let option):
                        return "\(option.description) path \(path.inSingleQuotes()) is not writable"
                case .couldNotCreate(path: let path, option: let option):
                        return "\(option.description) could not create file for writing at path \(path.inSingleQuotes())"
                case .couldNotOpenForWriting(path: let path, option: let option):
                        return "\(option.description) could not open file for writing at path \(path.inSingleQuotes())"
                }
        }
}

public enum ParserError: Error {
        case missingRequiredOption(Option)
        case missingRequiredValue(option: Option)
        case invalidUsage(option: Option)
        case invalidValue(option: Option, argument: String)
        case unparsedArgument(String)
        case unrecognizedCommand(String)
        case noInput
        public var string: String? {
                switch self {
                case .missingRequiredOption(let option):
                        return "missing required option \(option.description)"
                case .missingRequiredValue(option: let option):
                        return "option \(option.description) requires a value"
                case .invalidUsage(option: let option):
                        return "invalid use of \(option.description)"
                case .invalidValue(option: let option, argument: let argument):
                        return "invalid value \(argument.inSingleQuotes()) for option \(option.description)"
                case .unparsedArgument(let argument):
                        if argument.hasShortPrefix || argument.hasLongPrefix {
                                return "unrecognized option \(argument.inSingleQuotes())"
                        } else {
                                return "unparsed argument \(argument.inSingleQuotes())"
                        }
                case .unrecognizedCommand(let command):
                        return "unrecognized command \(command.inSingleQuotes())"
                case .noInput:
                        return nil
                }
        }
}

public enum ParserOption {
        case allowUnparsedOptions
        case ignoreSingleValue
        case throwsErrors
}
