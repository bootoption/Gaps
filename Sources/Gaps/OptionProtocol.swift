/*
 * OptionProtocol.swift
 * Copyright © 2014 Ben Gollmer
 * Copyright © 2019 vulgo
 * SPDX-License-Identifier: Apache-2.0
 */

public protocol OptionProtocol {
        var flag: Flag {
                get
        }        
        
        var parser: OptionParser? {
                get
        }
       
        var helpMessage: String? {
                get set
        }
        
        var isRequired: Bool {
                get set
        }
        
        var wasSet: Bool {
                get set
        }
        
        var description: String {
                get
        }
        
        func claimValue() throws
        
        func claimValue(argument: String) throws
        
        func reset()
        
        func setParser(_ parser: OptionParser)
}
