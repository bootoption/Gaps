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
                
                let a = StringOption(short: "a")
                let b = StringOption(short: "b")
                let c = StringOption(short: "c")
                let boolOption = BooleanOption(long: "bool")
                
                let parser = OptionParser(a, b, c, boolOption, parserOptions: [.allowUnparsedOptions])
                
                /* A. only unparsed arguments */

                try? parser.parse(["GapsTests", "one", "two", "three"])
                
                unparsed = parser.unparsedArguments
                
                XCTAssertEqual(a.value, nil)
                XCTAssertEqual(b.value, nil)
                XCTAssertEqual(c.value, nil)
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertFalse(boolOption.value)
                
                /* B. mixed with options */
                
                try? parser.parse(["GapsTests", "-a", "string1", "one", "-b", "string2", "two", "-c", "string3", "three"])
                
                unparsed = parser.unparsedArguments
                
                XCTAssertEqual(a.value, "string1")
                XCTAssertEqual(b.value, "string2")
                XCTAssertEqual(c.value, "string3")
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertFalse(boolOption.value)
                
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
                XCTAssertFalse(boolOption.value)
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertEqual(unparsed[3], "-four")
                XCTAssertEqual(unparsed[4], "--five")
                XCTAssertEqual(unparsed[5], "---six")
                XCTAssertFalse(boolOption.value)
                
                /* D. options out of order and the bool option set */
                
                try? parser.parse(["GapsTests", "-c", "string3", "one", "--bool", "-b", "string2", "two", "-a", "string1", "three"])
                
                unparsed = parser.unparsedArguments
                
                XCTAssertEqual(a.value, "string1")
                XCTAssertEqual(b.value, "string2")
                XCTAssertEqual(c.value, "string3")
                XCTAssertEqual(unparsed[0], "one")
                XCTAssertEqual(unparsed[1], "two")
                XCTAssertEqual(unparsed[2], "three")
                XCTAssertTrue(boolOption.value)
        }
        
        func testArgumentExpansion() {
                let a = BooleanOption(short: "a")
                let b = BooleanOption(short: "b")
                let c = BooleanOption(short: "c")
                let d = BooleanOption(short: "d")
                
                let multiString = ArrayOption(long: "strings")
                let optionalString = OptionalStringOption(long: "optional")
        
                let parser = OptionParser(a, b, c, d, multiString, optionalString)
                
                try? parser.parse(["GapsTests", "-abcd", "--strings=first", "second", "third", "--optional", "-a", "-b"])
                
                XCTAssertTrue(a.value)
                XCTAssertTrue(b.value)
                XCTAssertTrue(c.value)
                XCTAssertTrue(d.value)
                
                XCTAssertEqual(["first", "second", "third"], multiString.value)
                
                XCTAssertEqual(nil, optionalString.value)
                XCTAssertTrue(optionalString.wasSet)
        }
        
        func testFlagBehavior() {
                let flagOption = BooleanOption(short: "f")
                let parser = OptionParser(flagOption)
                
                /* Boolean options can appear more than once */
                
                try? parser.parse(["GapsTests", "-fff", "-f"])
                
                XCTAssertTrue(flagOption.value)
                XCTAssertEqual(parser.unparsedArguments.count, 0)
        }
        
        func testErrorsAreThrown() {
                let stringOption = StringOption(short: "a")
                
                let parser = OptionParser(stringOption, parserOptions: [.throwsErrors])
                
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
                                case .invalidUsage(let option):
                                        usedTwice = option.description == stringOption.description
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
                                case .missingRequiredValue(let option):
                                        missingValue = option.description == stringOption.description
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
