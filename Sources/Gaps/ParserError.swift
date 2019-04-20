/*
 * ParserError.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

public enum ParserError: Error {
        case missingRequiredOption(optionDescription: String)
        case missingRequiredValue(optionDescription: String)
        case invalidValue(optionDescription: String, argument: String)
        case invalidUse(optionDescription: String)
        case unparsedArgument(String)
        case unrecognizedCommand(String)
        case noInput
        public var string: String? {
                switch self {
                case .missingRequiredOption(optionDescription: let optionDescription):
                        return "missing required option \(optionDescription.inSingleQuotes())"
                case .missingRequiredValue(optionDescription: let optionDescription):
                        return "option \(optionDescription.inSingleQuotes()) requires a value"
                case .invalidValue(optionDescription: let optionDescription, argument: let argument):
                        return "invalid value \(argument.inSingleQuotes()) for option \(optionDescription.inSingleQuotes())"
                case .invalidUse(optionDescription: let optionDescription):
                        return "unparsed argument \(optionDescription.inSingleQuotes())"
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
