/*
 * Option.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

open class Option<T> {
        final public let flag: Flag
        final public var helpMessage: String?
        final public var isRequired: Bool
        final public var valueIsOptional: Bool
        final public var wasSet = false
        final public weak var parser: OptionParser?
        
        final public var description: String {
                return flag.values.joined(separator: ", ")
        }
        
        final public func setParser(_ parser: OptionParser) {
                self.parser = parser
        }
        
        public init(flags: String ..., helpMessage: String? = nil, required: Bool = false, valueIsOptional: Bool = false, defaultValue: T? = nil) {
                flag = Flag(strings: flags)
                self.helpMessage = helpMessage
                self.isRequired = required
                self.valueIsOptional = valueIsOptional
                self.defaultValue = defaultValue
                value = defaultValue
        }
        
        open var value: T? {
                didSet {
                        wasSet = true
                }
        }
        
        open var defaultValue: T?

        
        open func claimValue() throws {
                guard !wasSet else {
                        throw ParserError.invalidUse(optionDescription: self.description)
                }
                
                guard valueIsOptional else {
                        throw ParserError.missingRequiredValue(optionDescription: self.description)
                }
                
                value = nil
        }
        
        open func reset() {
                value = defaultValue
                wasSet = false
        }
}

open class StringConvertibleOption<T>: Option<T> where T: LosslessStringConvertible {
        open func claimValue(argument: String) throws {
                guard !wasSet else {
                        throw ParserError.unparsedArgument(argument)
                }
                
                guard let newValue = T.init(argument) else {
                        throw ParserError.invalidValue(optionDescription: self.description, argument: argument)
                }
                
                value = newValue
        }
}

open class StringConvertibleCollectionOption<T>: Option<T> where T: RangeReplaceableCollection, T.Element: LosslessStringConvertible {
        override open func claimValue() throws {
                guard !wasSet else {
                        throw ParserError.invalidUse(optionDescription: self.description)
                }
                
                guard valueIsOptional else {
                        throw ParserError.missingRequiredValue(optionDescription: self.description)
                }
                
                value = T.init()
        }
        
        open func claimValue(argument: String) throws {
                guard let element = T.Element(argument) else {
                        throw ParserError.invalidValue(optionDescription: self.description, argument: argument)
                }
                
                if value == nil {
                        value = [T.Element]() as? T
                }
                
                value!.append(element)
        }
}

public class FlagOption: Option<Int>, OptionProtocol {
        override public var defaultValue: Int? {
                get {
                        return 0
                }
                set {
                }
        }
        
        public var boolValue: Bool {
                return count > 0
        }
        
        public var count: Int {
                return value ?? 0
        }
        
        private func increment() {
                if let intValue = value {
                        value = intValue + 1
                } else {
                        value = 1
                }
        }
        
        override public func claimValue() throws {
                increment()
        }
        
        public func claimValue(argument: String) throws {
                increment()
                throw ParserError.unparsedArgument(argument)
        }
}

public class EnumOption<T>: Option<T>, OptionProtocol where T: RawRepresentable, T.RawValue: LosslessStringConvertible {
        public func claimValue(argument: String) throws {
                guard !wasSet else {
                        throw ParserError.invalidUse(optionDescription: self.description)
                }
                
                guard let rawValue = T.RawValue(argument), let rawRepresentable = T.init(rawValue: rawValue) else {
                        throw ParserError.invalidValue(optionDescription: self.description, argument: argument)
                }
                
                value = rawRepresentable
        }
}

public class StringOption: StringConvertibleOption<String>, OptionProtocol { }

public class DoubleOption: StringConvertibleOption<Double>, OptionProtocol { }

public class IntegerOption: StringConvertibleOption<Int>, OptionProtocol { }

public class ArrayOption<T>: StringConvertibleCollectionOption<Array<T>>, OptionProtocol where T: LosslessStringConvertible { }
