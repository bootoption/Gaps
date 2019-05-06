/*
 * CommandParser.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

open class CommandParser {
        private var commands: [Command]
        private var values = [String]()        
        private(set) public var parsedCommand: Command?
        
        open var invocationMessage: String {
                return "<command> [options]"
        }
        
        open var helpArgument: String? {
                return nil
        }
        
        open var versionArgument: String? {
                return nil
        }
        
        private func add(_ command: Command) {
                if values.contains(command.value) {
                        fatalError("non-unique command value '\(command.value)'")
                }
                commands.append(command)
        }
        
        public init(commands: [Command]) {
                self.commands = [Command]()
                for command in commands {
                        add(command)
                }
        }
        
        public convenience init(commands: Command ...) {
                var array = [Command]()
                for command in commands {
                        array.append(command)
                }
                self.init(commands: array)
        }
        
        public func parse(atIndex i: Int = 1) throws {
                do {
                        guard CommandLine.arguments.indices.contains(i) else {
                                throw ParserError.noInput
                        }
                        
                        let commandArgumentValue = CommandLine.arguments[i]
                        
                        if let helpArgument = helpArgument, commandArgumentValue == helpArgument {
                                print(usage())
                                exit(0)
                        }
                        
                        if let versionArgument = versionArgument, commandArgumentValue == versionArgument {
                                printVersion()
                                exit(0)
                        }
                        
                        for command in commands {
                                if command.value == commandArgumentValue {
                                        parsedCommand = command
                                }
                        }
                        
                        if parsedCommand == nil {
                                throw ParserError.unrecognizedCommand(commandArgumentValue)
                        }
                }
                
                catch let error as ParserError {
                        switch error {
                        case ParserError.noInput:
                                break
                        default:
                                FileHandle.standardError.write(string: "\(error)")
                        }
                        FileHandle.standardError.write(string: usage())
                        exit(1)
                }
                        
                catch {
                        throw error
                }
        }
        
        open func usage(errorMessage: String? = nil) -> String {
                var strings = [String]()
                
                if let errorMessage = errorMessage {
                        strings.append(errorMessage)
                }
                
                let title = String(format: "usage: %@ ", String.baseName)
                
                let invocationLines = invocationMessage.split(separator: "\n")
                
                for (i, line) in invocationLines.enumerated() {
                        switch i {
                        case 0:
                                strings.append(title + line)
                        default:
                                strings.append(String(repeating: " ", count: title.count) + line)
                        }
                }
                
                strings.append("")
                strings.append("available commands:")
                
                let filteredCommands = commands.filter { $0.helpMessage != nil }
                
                let length = filteredCommands.map( { $0.value.count } ).max() ?? 0
                
                for command in filteredCommands {
                        let value = command.value.padding(toLength: length + 3, withPad: " ", startingAt: 0)
                        strings.append("  " + value + command.helpMessage!)
                }
                
                strings.append("")
                
                return strings.joined(separator: "\n")
        }
        
        open func printVersion() {
                fatalError("printVersion() should be overriden by subclasses")
        }
}
