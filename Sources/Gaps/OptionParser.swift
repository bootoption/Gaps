/*
 * OptionParser.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

open class OptionParser {
        open var helpName: String?
        public var parserOptions: [ParserOption]
        private var _invocationMessage: String?
        private(set) public var unclaimedArguments = [String]()
        private(set) public var unparsedArguments = [String]()
        private(set) public var stoppedArguments = [String]()
        private var requiredOptions = [Option]()
        private var flags = Flags()
        private(set) public var options = [Option]()
        
        open var invocationMessage: String {
                return _invocationMessage ?? autoInvocationMessage()
        }
        
        open func usage() -> String {
                var strings = [String]()
                
                let title = helpName == nil ? String(format: "usage: %@ ", baseName) : String(format: "usage: %@ %@ ", baseName, helpName!)
                
                for (i, string) in invocationMessage.split(separator: "\n").enumerated() {
                        switch i {
                        case 0:
                                strings.append(title + string)
                        default:
                                strings.append(String(repeating: " ", count: title.count) + string)
                        }
                }
                
                let filteredOptions = options.filter { $0.helpMessage != nil }

                let lengths: (Int, Int) = (
                        filteredOptions.map({ $0.flag.short?.count ?? 0 }).max() ?? 0,
                        filteredOptions.map({ $0.flag.long?.count ?? 0 }).max() ?? 0
                )
                
                filteredOptions.forEach {
                        let shortFlagLabel = ($0.flag.short ?? "").padding(toLength: lengths.0)
                        let longFlagLabel = ($0.flag.long ?? "").padding(toLength: lengths.1)
                        let optionHelp = String(format: "  %@ %@   %@", shortFlagLabel, longFlagLabel, $0.helpMessage!)
                        strings.append(optionHelp)
                }
                
                return strings.joined(separator: "\n")
        }
        
        private init(options: [Option], helpName: String?, invocation: String?, parserOptions: [ParserOption]) {
                self.parserOptions = parserOptions
                self.helpName = helpName
                self._invocationMessage = invocation
                setOptions(options)
        }
        
        public convenience init(_ options: Option ..., helpName: String, invocation: String? = nil, parserOptions: [ParserOption] = []) {
                self.init(options: options, helpName: helpName, invocation: invocation, parserOptions: parserOptions)
        }
        
        public convenience init(_ options: Option ..., invocation: String? = nil, parserOptions: [ParserOption] = []) {
                self.init(options: options, helpName: nil, invocation: invocation, parserOptions: parserOptions)
        }        
        
        public convenience init(_ options: Option ..., parserOptions: [ParserOption] = []) {
                self.init(options: options, helpName: nil, invocation: nil, parserOptions: parserOptions)
        }
        
        public func setOptions(_ options: [Option]) {
                self.options.removeAll()
                self.requiredOptions.removeAll()
                self.flags = Flags()
                for option in options {
                        if let flag = option.flag.short {
                                guard !flags.short.contains(flag) else {
                                        fatalError("non-unique short flag \(flag.inSingleQuotes())")
                                }
                                flags.short.append(flag)
                        }
                        
                        if let flag = option.flag.long {
                                guard !flags.long.contains(flag) else {
                                        fatalError("non-unique short flag \(flag.inSingleQuotes())")
                                }
                                flags.long.append(flag)
                        }
                        option.reset()
                        option.parser = self
                        self.options.append(option)
                }
        }
        
        public func setInvocationMessage(_ newValue: String?) {
                _invocationMessage = newValue
        }
        
        private func autoInvocationMessage() -> String {
                var flags = [String]()
                for option in options {
                        var flag = option.flag.short ?? option.flag.long ?? ""
                        if flag.isEmpty {
                                continue
                        }
                        flag = option.isRequired ? flag : "[\(flag)]"
                        flags.append(flag)
                }
                return flags.joined(separator: " ")
        }
        
        private func expandedArguments(arguments: [String]? = nil, fromIndex: Int = 1) -> [String] {
                var arguments: [String] = arguments ?? CommandLine.arguments
                
                for _ in 0..<fromIndex {
                        if arguments.first != nil {
                                arguments.removeFirst()
                        }
                }
                
                var expandedArguments = [String]()
                var stopped = false
                
                for argument in arguments {
                        if stopped {
                                expandedArguments.append(argument)
                                continue
                        }
                        
                        if argument.isEmpty {
                                continue
                        }
                        
                        if argument == stopOperand {
                                expandedArguments.append(argument)
                                stopped = true
                                continue
                        }
                        
                        if argument == fileOperand || argument == shortPrefix || argument == longPrefix {
                                expandedArguments.append(argument)
                                continue
                        }
                        
                        if argument.hasLongPrefix {
                                let arguments = argument.split(separator: assignmentOperand, maxSplits: 1)
                                expandedArguments.append(contentsOf: arguments.map { String($0) })
                                continue
                        }
                        
                        if argument.hasShortPrefix {
                                if argument.isNumerical {
                                        expandedArguments.append(argument)
                                        continue
                                }
                                
                                var argument = argument
                                argument.removeFirst()
                                expandedArguments.append(contentsOf: argument.map { shortPrefix + String($0) })
                                continue
                        }
                        
                        expandedArguments.append(argument)
                }
                
                return expandedArguments
        }
        
        private func reset(arguments: [String]? = nil, fromIndex: Int = 1) throws {
                unparsedArguments.removeAll()
                stoppedArguments.removeAll()
                requiredOptions.removeAll()
                
                for option in options {
                        option.reset()
                        if option.isRequired {
                                requiredOptions.append(option)
                        }
                }
                
                unclaimedArguments = expandedArguments(arguments: arguments, fromIndex: fromIndex)
                
                if unclaimedArguments.count == 0 {
                        throw ParserError.noInput
                }
        }
        
        public final func parse(_ arguments: [String], fromIndex: Int = 1) throws {
                try parse(arguments: arguments, fromIndex: fromIndex)
        }
        
        public final func parse(fromIndex: Int = 1) throws {
                try parse(arguments: nil, fromIndex: fromIndex)
        }
        
        private func parse(arguments: [String]? = nil, fromIndex: Int = 1) throws {
                do {
                        try reset(arguments: arguments, fromIndex: fromIndex)
                        
                        if let stopIndex = unclaimedArguments.firstIndex(of: stopOperand) {
                                unclaimedArguments.remove(at: stopIndex)
                                for _ in 0..<unclaimedArguments.count - stopIndex {
                                        stoppedArguments.append(unclaimedArguments.remove(at: stopIndex))
                                }
                        }
                        
                        for option in options {
                                var optionIndicies = [Int]()
                                var claimedValueIndicies = [Int]()
                                
                                for (index, argument) in unclaimedArguments.enumerated() where option.flag.values.contains(argument) {
                                        optionIndicies.append(index)
                                }
                                
                                if optionIndicies.isEmpty {
                                        continue
                                }
                                
                                if optionIndicies.count > 1, option.singleValue, !parserOptions.contains(.ignoreSingleValue) {
                                        throw ParserError.invalidUsage(option: option)
                                }
                                
                                for optionIndex in optionIndicies {
                                        let last = unclaimedArguments.count - 1
                                        
                                        if optionIndex == last {
                                                try option.claimValue(nil)
                                                continue
                                        }
                                        
                                        let start = optionIndex + 1
                                        
                                        for argumentIndex in start...last {
                                                let value = unclaimedArguments[argumentIndex]
                                                
                                                if !value.isNumerical && (value.hasShortPrefix || value.hasLongPrefix) {
                                                        if argumentIndex == start {
                                                                try option.claimValue(nil)
                                                        }
                                                        break
                                                }
                                                
                                                do {
                                                        try option.claimValue(value)
                                                        claimedValueIndicies.append(argumentIndex)
                                                }
                                                
                                                catch let error as ParserError {
                                                        switch error {
                                                        case .unparsedArgument:
                                                                break
                                                        default:
                                                                throw error
                                                        }
                                                }
                                        }
                                }
                                
                                Set(optionIndicies + claimedValueIndicies).sorted(by: { $0 > $1 }).forEach {
                                        unclaimedArguments.remove(at: $0)
                                }
                        }
                        
                        unparsedArguments.append(contentsOf: unclaimedArguments + stoppedArguments)
                        
                        try requiredOptions.forEach {
                                if !$0.wasSet {
                                        throw ParserError.missingRequiredOption($0)
                                }
                        }
                        
                        if !parserOptions.contains(.allowUnparsedOptions), !unparsedArguments.isEmpty {
                                throw ParserError.unparsedArgument(unparsedArguments.first!)
                        }
                }
                        
                catch let error as ParserError {
                        if parserOptions.contains(.throwsErrors) {
                                throw error
                        }                        
                        if let message = error.string {
                                standardError.write(string: (helpName ?? baseName) + ": " + message)
                        }
                        standardError.write(string: usage())
                        exit(1)
                }
                
                catch {
                        throw error
                }
        }
}
