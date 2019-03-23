/*
 * Command.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2017-2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

import Foundation

public class Command {
        internal var value: String
        private var closure: () throws -> ()
        internal let helpMessage: String
        
        public init(_ value: String, helpMessage: String, closure: @escaping () throws -> ()) {
                self.value = value
                self.helpMessage = helpMessage
                self.closure = closure
        }
        
        public func call() throws {
                try closure()
        }
}
