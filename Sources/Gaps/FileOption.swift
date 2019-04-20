/*
 * FileOption.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public class FileOption: Option<String> {
        final public var wasValidated: Bool = false
        
        final override public var value: String? {
                willSet {
                        wasValidated = false
                }
                
                didSet {
                        wasSet = true
                }
        }
        
        open func validatePath() throws {
                fatalError("validatePath() must be overridden by subclasses")
        }
        
        final public func claimValue(argument: String) throws {
                guard !wasSet else {
                        throw ParserError.invalidUse(optionDescription: self.description)
                }
                
                value = argument
                
                try validatePath()
        }
        
        final override public func reset() {
                wasValidated = false
                super.reset()
        }
}

final public class FileForReadingOption: FileOption, OptionProtocol {
        final public func data() throws -> Data? {
                let file = try fileHandle()
                let data = file.readDataToEndOfFile()
                file.closeFile()
                return data
        }
        
        final public func fileHandle() throws -> FileHandle {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(optionDescription: self.description)
                }
                
                if value == String.fileOperand {
                        return FileHandle(fileDescriptor: FileHandle.standardInput.fileDescriptor, closeOnDealloc: true)
                }
                
                if !wasValidated {
                        try validatePath()
                }
                
                guard let fileHandle = FileHandle.init(forReadingAtPath: value) else {
                        throw FileOptionError.couldNotOpenForReading(path: value, optionDescription: self.description)
                }
                
                return fileHandle
        }
        
        final override public func validatePath() throws {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(optionDescription: self.description)
                }
                
                if value == String.fileOperand {
                        return
                }
                
                var isDirectory = ObjCBool(true)
                
                guard FileManager.default.fileExists(atPath: value, isDirectory: &isDirectory) else {
                        throw FileOptionError.fileNotFound(path: value, optionDescription: self.description)
                }
                
                guard !isDirectory.boolValue else {
                        throw FileOptionError.isDirectory(path: value, optionDescription: self.description)
                }
                
                guard FileManager.default.isReadableFile(atPath: value) else {
                        throw FileOptionError.isNotReadable(path: value, optionDescription: self.description)
                }
                
                wasValidated = true
        }
}

final public class FileForWritingOption: FileOption, OptionProtocol {
        final public func write(data: Data) throws {
                let file = try fileHandle()
                file.write(data)
                file.closeFile()
        }
        
        final public func fileHandle() throws -> FileHandle {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(optionDescription: self.description)
                }
                
                if value == String.fileOperand {
                        return FileHandle(fileDescriptor: FileHandle.standardOutput.fileDescriptor, closeOnDealloc: true)
                }
                
                if !wasValidated {
                        try validatePath()
                }
                
                if !FileManager.default.fileExists(atPath: value) {
                        guard FileManager.default.createFile(atPath: value, contents: nil, attributes: nil) else {
                                throw FileOptionError.couldNotCreate(path: value, optionDescription: self.description)
                        }
                }
                
                guard let fileHandle = FileHandle.init(forWritingAtPath: value) else {
                        throw FileOptionError.couldNotOpenForWriting(path: value, optionDescription: self.description)
                }
                
                return fileHandle
        }
        
        final override public func validatePath() throws {
                guard let value = value else {
                        throw FileOptionError.pathNotSet(optionDescription: self.description)
                }
                
                if value == String.fileOperand {
                        return
                }
                
                if value == "/" {
                        throw FileOptionError.isNotWritable(path: value, optionDescription: self.description)
                }
                
                var isDirectory = ObjCBool(true)
                
                if FileManager.default.fileExists(atPath: value, isDirectory: &isDirectory) {
                        guard isDirectory.boolValue == false else {
                                throw FileOptionError.isDirectory(path: value, optionDescription: self.description)
                        }
                        
                        guard FileManager.default.isWritableFile(atPath: value) else {
                                throw FileOptionError.isNotWritable(path: value, optionDescription: self.description)
                        }
                        
                        wasValidated = true
                } else {
                        let pathToDirectory = NSString(string: value).deletingLastPathComponent
                        
                        var isDirectory = ObjCBool(true)
                        
                        guard FileManager.default.fileExists(atPath: pathToDirectory, isDirectory: &isDirectory) else {
                                throw FileOptionError.isNotWritable(path: value, optionDescription: self.description)
                        }
                        
                        guard isDirectory.boolValue == true else {
                                throw FileOptionError.isNotWritable(path: value, optionDescription: self.description)
                        }
                        
                        guard FileManager.default.isWritableFile(atPath: pathToDirectory) else {
                                throw FileOptionError.isNotWritable(path: value, optionDescription: self.description)
                        }
                        
                        wasValidated = true
                }
        }
}
