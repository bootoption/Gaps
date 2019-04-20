import XCTest
import Foundation
@testable import Gaps

final class GapsTests: XCTestCase {
        static var allTests = [
                ("testUnparsedArgumentPosition", testUnparsedArgumentPosition),
                ("testArgumentExpansion", testArgumentExpansion),
                ("testFlagBehavior", testFlagBehavior),
                ("testErrorsAreThrown", testErrorsAreThrown)
        ]
        
        func testUnparsedArgumentPosition() {
                var unparsed: [String]
                
                let a = StringOption(flags: "a")
                let b = StringOption(flags: "b")
                let c = StringOption(flags: "c")
                let flagOption = FlagOption(flags: "bool")
                
                let parser = OptionParser(a, b, c, flagOption, settings: [.allowUnparsedOptions])
                
                /* A. only unparsed arguments */

                try? parser.parse(["GapsTests", "one", "two", "three"])
                
                unparsed = parser.unparsedArguments
                
                XCTAssertEqual(a.value, nil)
                XCTAssertEqual(b.value, nil)
                XCTAssertEqual(c.value, nil)
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertFalse(flagOption.boolValue)
                
                /* B. mixed with options */
                
                try? parser.parse(["GapsTests", "-a", "string1", "one", "-b", "string2", "two", "-c", "string3", "three"])
                
                unparsed = parser.unparsedArguments
                
                XCTAssertEqual(a.value, "string1")
                XCTAssertEqual(b.value, "string2")
                XCTAssertEqual(c.value, "string3")
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertFalse(flagOption.boolValue)
                
                /*
                 *  C. with stop operand -- the order of
                 *  the set options should not be affecting
                 *  the order of the unparsed arguments...
                 */
                
                try? parser.parse(["GapsTests", "one", "-c", "string", "two", "three", "--", "-four", "--five", "---six"])
                
                unparsed = parser.unparsedArguments
                
                XCTAssertEqual(a.value, nil)
                XCTAssertEqual(b.value, nil)
                XCTAssertEqual(c.value, "string")
                XCTAssertTrue(unparsed.contains("one"))
                XCTAssertTrue(unparsed.contains("two"))
                XCTAssertTrue(unparsed.contains("three"))
                XCTAssertFalse(flagOption.boolValue)
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertEqual(unparsed[3], "-four")
                XCTAssertEqual(unparsed[4], "--five")
                XCTAssertEqual(unparsed[5], "---six")
                XCTAssertFalse(flagOption.boolValue)
                
                /* D. options out of order and the bool option set */
                
                try? parser.parse(["GapsTests", "-c", "string3", "one", "--bool", "-b", "string2", "two", "-a", "string1", "three"])
                
                unparsed = parser.unparsedArguments
                
                XCTAssertEqual(a.value, "string1")
                XCTAssertEqual(b.value, "string2")
                XCTAssertEqual(c.value, "string3")
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertTrue(flagOption.boolValue)
        }
        
        func testArgumentExpansion() {
                let a = FlagOption(flags: "a")
                let b = FlagOption(flags: "b")
                let c = FlagOption(flags: "c")
                let d = FlagOption(flags: "d")
                
                let multiString = ArrayOption<String>(flags: "strings")
                let optionalString = StringOption(flags: "optional", valueIsOptional: true)
        
                let parser = OptionParser(a, b, c, d, multiString, optionalString)
                
                try? parser.parse(["GapsTests", "-abcd", "--strings=first", "second", "third", "--optional", "-a", "-b"])
                
                XCTAssertTrue(a.boolValue)
                XCTAssertTrue(b.boolValue)
                XCTAssertTrue(c.boolValue)
                XCTAssertTrue(d.boolValue)
                
                XCTAssertEqual(["first", "second", "third"], multiString.value)
                
                XCTAssertEqual(nil, optionalString.value)
                XCTAssertTrue(optionalString.wasSet)
        }
        
        func testFlagBehavior() {
                let flagOption = FlagOption(flags: "f")
                let parser = OptionParser(flagOption)
                
                /* Flag options can be used more than once */
                
                try? parser.parse(["GapsTests", "-fff", "-ff"])
                
                XCTAssertTrue(flagOption.boolValue)
                XCTAssertEqual(flagOption.count, 5)
                XCTAssertEqual(parser.unparsedArguments.count, 0)
        }
        
        func testErrorsAreThrown() {
                let stringOption = StringOption(flags: "a")
                
                let parser = OptionParser(stringOption, settings: [.throwsErrors])
                
                /* A. unparsed argument */
                
                var unparsed = false
                do {
                        try parser.parse(["GapsTests", "unparsed"])
                } catch {
                        if let gapsError = error as? ParserError {
                                switch gapsError {
                                case .unparsedArgument(let argument):
                                        unparsed = argument == "unparsed"
                                default:
                                        break
                                }
                        }
                }
                XCTAssertTrue(unparsed)
                
                /* B. option used twice */
                
                var usedTwice = false
                do {
                        try parser.parse(["GapsTests", "-a", "first", "-a", "second"])
                } catch {
                        if let gapsError = error as? ParserError {
                                switch gapsError {
                                case .invalidUse(let optionDescription):
                                        usedTwice = optionDescription == stringOption.description
                                default:
                                        break
                                }
                        }
                }
                XCTAssertTrue(usedTwice)
                
                /* C. missing required value */
                
                var missingValue = false
                do {
                        try parser.parse(["GapsTests", "-a"])
                } catch {
                        if let gapsError = error as? ParserError {
                                switch gapsError {
                                case .missingRequiredValue(optionDescription: let optionDescription):
                                        missingValue = optionDescription == stringOption.description
                                default:
                                        break
                                }
                        }
                }
                XCTAssertTrue(missingValue)
                
                /* D. no input */
                
                var noInput = false
                do {
                        try parser.parse(["GapsTests"])
                } catch {
                        if let gapsError = error as? ParserError {
                                switch gapsError {
                                case .noInput:
                                        noInput = true
                                default:
                                        break
                                }
                        }
                }
                XCTAssertTrue(noInput)
        }
}
