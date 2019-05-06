/*
 * ParserError.swift
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

public enum ParserError: Error, CustomStringConvertible {
        case missingRequiredOption(optionDescription: String)
        case missingRequiredValue(optionDescription: String)
        case invalidValue(optionDescription: String, argument: String)
        case invalidUse(optionDescription: String)
        case unparsedArgument(String)
        case unrecognizedCommand(String)
        case noInput
        
        public var description: String {
                switch self {
                case .missingRequiredOption(optionDescription: let optionDescription):
                        return "missing required option '\(optionDescription)'"
                case .missingRequiredValue(optionDescription: let optionDescription):
                        return "option '\(optionDescription)' requires a value"
                case .invalidValue(optionDescription: let optionDescription, argument: let argument):
                        return "invalid value '\(argument)' for option '\(optionDescription)'"
                case .invalidUse(optionDescription: let optionDescription):
                        return "unparsed argument '\(optionDescription)'"
                case .unparsedArgument(let argument):
                        if argument.hasShortPrefix || argument.hasLongPrefix {
                                return "unrecognized option '\(argument)'"
                        } else {
                                return "unparsed argument '\(argument)'"
                        }
                case .unrecognizedCommand(let command):
                        return "unrecognized command '\(command)'"
                case .noInput:
                        return "no input"
                }
        }
}
