/*
 * Option.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

open class Option {
        internal let flag: Flag
        public var helpMessage: String?
        public var isRequired: Bool
        public var wasSet = false
        public var invalidValue: String?
        public weak var parser: OptionParser?
        
        public var description: String {
                return flag.values.joined(separator: ", ").inSingleQuotes()
        }
        
        public init(_ flags: [String], _ helpMessage: String?, _ required: Bool) {
                flag = Flag(flags: flags)
                self.helpMessage = helpMessage
                self.isRequired = required
        }
        
        open func claimValue(_ argument: String?) throws {
                fatalError("claimValue() must be overridden by subclasses")
        }
        
        open func reset() {
                fatalError("reset() must be overridden by subclasses")
        }
        
        open var singleValue: Bool {
                return false
        }
}

public class ArrayOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: [String]? = nil {
                didSet {
                        wasSet = true
                }
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        throw ParserError.missingRequiredValue(option: self)
                case .some:
                        if value == nil {
                                value = [String]()
                        }
                        value!.append(argument!)
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

public class StringOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: String? = nil {
                didSet {
                        wasSet = true
                }
        }
        
        override public var singleValue: Bool {
                return true
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        throw ParserError.missingRequiredValue(option: self)
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        value = argument!
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

public class OptionalStringOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: String? {
                didSet {
                        wasSet = true
                }
        }
        
        override public var singleValue: Bool {
                return true
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        wasSet = true
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        value = argument!
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

public class IntegerOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: Int? {
                didSet {
                        wasSet = true
                }
        }
        
        override public var singleValue: Bool {
                return true
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        throw ParserError.missingRequiredValue(option: self)
                case .some:
                        guard let newValue = Int(argument!) else {
                                invalidValue = argument!
                                throw ParserError.invalidValue(option: self, argument: argument!)
                        }
                        value = newValue
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

public class DoubleOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: Double? {
                didSet {
                        wasSet = true
                }
        }
        
        override public var singleValue: Bool {
                return true
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        throw ParserError.missingRequiredValue(option: self)
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        guard let newValue = Double(argument!) else {
                                invalidValue = argument!
                                throw ParserError.invalidValue(option: self, argument: argument!)
                        }
                        value = newValue
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
        }
}

public class BooleanOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: Bool = false {
                didSet {
                        wasSet = true
                }
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        value = true
                case .some:
                        value = true
                        throw ParserError.unparsedArgument(argument!)
                }
        }
        
        override public func reset() {
                value = false
                wasSet = false
        }
}

public class FileForReadingOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: String? = nil {
                willSet {
                        wasValidated = false
                }
                
                didSet {
                        wasSet = true
                }
        }
        
        private var wasValidated: Bool = false
        
        override public var singleValue: Bool {
                return true
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        throw ParserError.missingRequiredValue(option: self)
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        value = argument!
                        try validatePathForReading()
                }
        }
        
        public func data() throws -> Data? {
                let handle = try fileHandle()
                let data = handle.readDataToEndOfFile()
                handle.closeFile()
                return data
        }
        
        public func fileHandle() throws -> FileHandle {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(option: self)
                }
                
                if value == fileOperand {
                        return FileHandle(fileDescriptor: FileHandle.standardInput.fileDescriptor, closeOnDealloc: true)
                }

                if !wasValidated {
                        try validatePathForReading()
                }
                
                guard let fileHandle = FileHandle.init(forReadingAtPath: value) else {
                        throw FileOptionError.couldNotOpenForReading(path: value, option: self)
                }
                
                return fileHandle
        }
        
        private func validatePathForReading() throws {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(option: self)
                }
                
                if value == fileOperand {
                        return
                }
                
                var isDirectory = ObjCBool(true)
                
                guard FileManager.default.fileExists(atPath: value, isDirectory: &isDirectory) else {
                        throw FileOptionError.fileNotFound(path: value, option: self)
                }
                
                guard !isDirectory.boolValue else {
                        throw FileOptionError.isDirectory(path: value, option: self)
                }
                
                guard FileManager.default.isReadableFile(atPath: value) else {
                        throw FileOptionError.isNotReadable(path: value, option: self)
                }
                
                wasValidated = true
        }
        
        override public func reset() {
                value = nil
                wasSet = false
                wasValidated = false
        }
}

public class FileForWritingOption: Option {
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false) {
                super.init(flags, helpMessage, required)
        }
        
        private(set) public var value: String? = nil {
                willSet {
                        wasValidated = false
                }
                
                didSet {
                        wasSet = true
                }
        }
        
        private var wasValidated: Bool = false
        
        override public var singleValue: Bool {
                return true
        }
        
        override public func claimValue(_ argument: String?) throws {
                switch argument {
                case .none:
                        throw ParserError.missingRequiredValue(option: self)
                case .some:
                        guard value == nil else {
                                throw ParserError.unparsedArgument(argument!)
                        }
                        value = argument!
                        try validatePathForWriting()
                }
        }
        
        public func write(data: Data) throws {
                let handle = try fileHandle()
                handle.write(data)
                handle.closeFile()
        }
        
        public func fileHandle() throws -> FileHandle {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(option: self)
                }
                
                if value == fileOperand {
                        return FileHandle(fileDescriptor: FileHandle.standardOutput.fileDescriptor, closeOnDealloc: true)
                }

                if !wasValidated {
                        try validatePathForWriting()
                }
                
                if !FileManager.default.fileExists(atPath: value) {
                        guard FileManager.default.createFile(atPath: value, contents: nil, attributes: nil) else {
                                throw FileOptionError.couldNotCreate(path: value, option: self)
                        }
                }
                
                guard let fileHandle = FileHandle.init(forWritingAtPath: value) else {
                        throw FileOptionError.couldNotOpenForWriting(path: value, option: self)
                }
                
                return fileHandle
        }        
        
        private func validatePathForWriting() throws {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(option: self)
                }
                
                if value == fileOperand {
                        return
                }
                
                if value == "/" {
                        throw FileOptionError.isNotWritable(path: value, option: self)
                }
                
                var isDirectory = ObjCBool(true)
                
                if FileManager.default.fileExists(atPath: value, isDirectory: &isDirectory) {
                        guard isDirectory.boolValue == false else {
                                throw FileOptionError.isDirectory(path: value, option: self)
                        }
                        
                        guard FileManager.default.isWritableFile(atPath: value) else {
                                throw FileOptionError.isNotWritable(path: value, option: self)
                        }
                        
                        wasValidated = true
                } else {
                        let pathToDirectory = NSString(string: value).deletingLastPathComponent
                        
                        var isDirectory = ObjCBool(true)
                        
                        guard FileManager.default.fileExists(atPath: pathToDirectory, isDirectory: &isDirectory) else {
                                throw FileOptionError.isNotWritable(path: value, option: self)
                        }
                        
                        guard isDirectory.boolValue == true else {
                                throw FileOptionError.isNotWritable(path: value, option: self)
                        }
                        
                        guard FileManager.default.isWritableFile(atPath: pathToDirectory) else {
                                throw FileOptionError.isNotWritable(path: value, option: self)
                        }
                        
                        wasValidated = true
                }
        }
        
        override public func reset() {
                value = nil
                wasSet = false
                wasValidated = false
        }
}
