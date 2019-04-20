/*
 * FileOptionError.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

public enum FileOptionError: Error {
        case pathNotSet(optionDescription: String)
        case fileNotFound(path: String, optionDescription: String)
        case isDirectory(path: String, optionDescription: String)
        case isNotReadable(path: String, optionDescription: String)
        case couldNotOpenForReading(path: String, optionDescription: String)
        case isNotWritable(path: String, optionDescription: String)
        case couldNotCreate(path: String, optionDescription: String)
        case couldNotOpenForWriting(path: String, optionDescription: String)
        public var string: String {
                switch self {
                case .pathNotSet(optionDescription: let optionDescription):
                        return "\(optionDescription) path not set"
                case .fileNotFound(path: let path, optionDescription: let optionDescription):
                        return "\(optionDescription) file not found at path \(path.inSingleQuotes())"
                case .isDirectory(path: let path, optionDescription: let optionDescription):
                        return "\(optionDescription) path \(path.inSingleQuotes()) is a directory"
                case .isNotReadable(path: let path, optionDescription: let optionDescription):
                        return "\(optionDescription) path \(path.inSingleQuotes()) is not readable"
                case .couldNotOpenForReading(path: let path, optionDescription: let optionDescription):
                        return "\(optionDescription) could not open file for reading at path \(path.inSingleQuotes())"
                case .isNotWritable(path: let path, optionDescription: let optionDescription):
                        return "\(optionDescription) path \(path.inSingleQuotes()) is not writable"
                case .couldNotCreate(path: let path, optionDescription: let optionDescription):
                        return "\(optionDescription) could not create file for writing at path \(path.inSingleQuotes())"
                case .couldNotOpenForWriting(path: let path, optionDescription: let optionDescription):
                        return "\(optionDescription) could not open file for writing at path \(path.inSingleQuotes())"
                }
        }
}

