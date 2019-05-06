/*
 * OptionParser.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

open class OptionParser {
        open var helpName: String?
        public var parserSettings: [ParserSetting]
        private(set) public var unparsedArguments = [String]()
        private var _invocationMessage: String?
        private var _options = [OptionProtocol]()
        
        public var options: [OptionProtocol] {
                get {
                        return _options
                }
                
                set(optionArray) {
                        _options.removeAll()
                        var usedShortFlags = Set<String>()
                        var usedLongFlags = Set<String>()
                        optionArray.forEach {
                                validateFlag($0.flag.short, usedFlags: &usedShortFlags)
                                validateFlag($0.flag.long, usedFlags: &usedLongFlags)
                                $0.reset()
                                $0.setParser(self)
                                _options.append($0)
                        }
                }
        }
        
        open var invocationMessage: String {
                return _invocationMessage ?? autoInvocationMessage()
        }        
        
        private func validateFlag(_ newFlag: String?, usedFlags: inout Set<String>) {
                guard newFlag != nil else {
                        return
                }
                
                guard !usedFlags.contains(newFlag!) else {
                        fatalError("non-unique flag \(newFlag!.inSingleQuotes())")
                }
                
                usedFlags.insert(newFlag!)
        }
        
        public func setInvocationMessage(_ newValue: String?) {
                _invocationMessage = newValue
        }
        
        private func autoInvocationMessage() -> String {
                let flags: [String] = options.map {
                        let flag = $0.flag.short ?? $0.flag.long!
                        return $0.isRequired ? flag : "[" + flag + "]"
                }
                
                return flags.joined(separator: " ")
        }
        
        open func usage() -> String {
                var strings = [String]()
                
                var title: String
                
                if helpName == nil {
                        title = String(format: "usage: %@ ", String.baseName)
                } else {
                        title = String(format: "usage: %@ %@ ", String.baseName, helpName!)
                }
                
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
        
        private init(options: [OptionProtocol], helpName: String?, invocation: String?, settings: [ParserSetting]) {
                self.parserSettings = settings
                self.helpName = helpName
                self._invocationMessage = invocation
                self.options = options
        }
        
        public convenience init(_ options: OptionProtocol ..., helpName: String, invocation: String? = nil, settings: [ParserSetting] = []) {
                self.init(options: options, helpName: helpName, invocation: invocation, settings: settings)
        }
        
        public convenience init(_ options: OptionProtocol ..., invocation: String? = nil, settings: [ParserSetting] = []) {
                self.init(options: options, helpName: nil, invocation: invocation, settings: settings)
        }        
        
        public convenience init(_ options: OptionProtocol ..., settings: [ParserSetting] = []) {
                self.init(options: options, helpName: nil, invocation: nil, settings: settings)
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
                        
                        if argument == String.stopOperand {
                                expandedArguments.append(argument)
                                stopped = true
                                continue
                        }
                        
                        if argument == String.fileOperand || argument == String.shortPrefix || argument == String.longPrefix {
                                expandedArguments.append(argument)
                                continue
                        }
                        
                        if argument.hasLongPrefix {
                                let arguments = argument.split(separator: Character.assignmentOperand, maxSplits: 1)
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
                                expandedArguments.append(contentsOf: argument.map { String.shortPrefix + String($0) })
                                continue
                        }
                        
                        expandedArguments.append(argument)
                }
                
                return expandedArguments
        }
        
        public final func parse(_ arguments: [String], fromIndex: Int = 1) throws {
                try parse(arguments: arguments, fromIndex: fromIndex)
        }
        
        public final func parse(fromIndex: Int = 1) throws {
                try parse(arguments: nil, fromIndex: fromIndex)
        }
        
        private func parse(arguments: [String]? = nil, fromIndex: Int = 1) throws {
                do {
                        unparsedArguments.removeAll()
                        
                        options.forEach {
                                $0.reset()
                        }
                        
                        var unclaimedArguments = expandedArguments(arguments: arguments, fromIndex: fromIndex)
                        
                        if unclaimedArguments.count == 0, !parserSettings.contains(.ignoreNoInput) {
                                throw ParserError.noInput
                        }
                        
                        var stoppedArguments = [String]()
                        
                        if let stopIndex = unclaimedArguments.firstIndex(of: String.stopOperand) {
                                unclaimedArguments.remove(at: stopIndex)
                                for _ in 0..<unclaimedArguments.count - stopIndex {
                                        stoppedArguments.append(unclaimedArguments.remove(at: stopIndex))
                                }
                        }
                        
                        var claimedIndices = Set<Int>()
                        
                        for option in options {
                                var optionIndices = [Int]()
                                var claimedValueIndices = [Int]()
                                
                                for (index, argument) in unclaimedArguments.enumerated() where option.flag.values.contains(argument) {
                                        optionIndices.append(index)
                                }
                                
                                if optionIndices.isEmpty {
                                        continue
                                }
                                
                                for optionIndex in optionIndices {                                        
                                        var range = optionIndex + 1..<unclaimedArguments.count
                                        
                                        for i in range {
                                                if unclaimedArguments[i].isOption {
                                                        range = range.lowerBound..<i
                                                        break
                                                }
                                        }
                                        
                                        if range.isEmpty {
                                                try option.claimValue()
                                                continue
                                        }
                                        
                                        try range.forEach {
                                                do {
                                                        try option.claimValue(argument: unclaimedArguments[$0])
                                                        claimedValueIndices.append($0)
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
                                
                                claimedIndices = Set(claimedIndices + optionIndices + claimedValueIndices)
                        }
                        
                        claimedIndices.sorted(by: { $0 > $1 }).forEach {
                                unclaimedArguments.remove(at: $0)
                        }
                        
                        unparsedArguments.append(contentsOf: unclaimedArguments + stoppedArguments)
                        
                        for option in options where option.isRequired {
                                if !option.wasSet {
                                        throw ParserError.missingRequiredOption(optionDescription: option.description)
                                }
                        }
                        
                        if !parserSettings.contains(.allowUnparsedOptions), !unparsedArguments.isEmpty {
                                throw ParserError.unparsedArgument(unparsedArguments.first!)
                        }
                }
                        
                catch let error as ParserError {
                        if parserSettings.contains(.throwsErrors) {
                                throw error
                        }
                        
                        switch error {
                        case ParserError.noInput:
                                break
                        default:
                                FileHandle.standardError.write(string: (helpName ?? String.baseName) + ": \(error)")
                        }
                        
                        FileHandle.standardError.write(string: usage())
                        exit(1)
                }
                
                catch {
                        throw error
                }
        }
}
