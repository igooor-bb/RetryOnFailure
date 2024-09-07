import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module
// is not available when cross-compiling. Cross-compiled tests may still
// make use of the macro itself in end-to-end tests.

#if canImport(RetryOnFailureMacros)
import RetryOnFailureMacros

let testMacros: [String: Macro.Type] = [
    "RetryOnFailure": RetryOnFailureMacro.self,
]
#endif

final class RetryOnFailureExpansionTests: XCTestCase {
    
    private let helperFuncName = "__macro_local_5blockfMu_"
    private let attemptsDeclName = "__macro_local_8attemptsfMu_"
    
    func testRetryOnFailureExpansion_withValidThrowingFunction() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 3)
            func fetchData() throws {
                try networkCall()
            }
            """,
            expandedSource: """
            func fetchData() throws {
                func \(helperFuncName)() throws {
                    try networkCall()
                }
                var \(attemptsDeclName) = 0
                while \(attemptsDeclName) < 3 {
                    do {
                        return try \(helperFuncName)()
                    } catch {
                        \(attemptsDeclName) += 1
                        if \(attemptsDeclName) == 3 {
                            throw error
                        }
                    }
                }
                fatalError("Unknown Error")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRetryOnFailureExpansion_withNonThrowingFunction() {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 3)
            func nonThrowingFunction() {
                print("This function does not throw")
            }
            """,
            expandedSource: """
            func nonThrowingFunction() {
                print("This function does not throw")
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Macro can only be applied to throwing functions",
                    line: 1,
                    column: 1
                )
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRetryOnFailureExpansion_withMultipleStatementsInBody() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 2)
            func fetchData() throws {
                print("Attempting to fetch data")
                try networkCall()
                print("Data fetched successfully")
            }
            """,
            expandedSource: """
            func fetchData() throws {
                func \(helperFuncName)() throws {
                    print("Attempting to fetch data")
                    try networkCall()
                    print("Data fetched successfully")
                }
                var \(attemptsDeclName) = 0
                while \(attemptsDeclName) < 2 {
                    do {
                        return try \(helperFuncName)()
                    } catch {
                        \(attemptsDeclName) += 1
                        if \(attemptsDeclName) == 2 {
                            throw error
                        }
                    }
                }
                fatalError("Unknown Error")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRetryOnFailureExpansion_withInvalidRetriesParameter() {
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: "invalid")
            func fetchData() throws {
                try networkCall()
            }
            """,
            expandedSource: """
            func fetchData() throws {
                try networkCall()
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Missing or invalid 'retries' parameter", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testRetryOnFailureExpansion_withNonPositiveRetriesParameter() {
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 0)
            func fetchData() throws {
                try networkCall()
            }
            """,
            expandedSource: """
            func fetchData() throws {
                try networkCall()
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Retries count must be positive", line: 1, column: 1)
            ],
            macros: testMacros
        )
    }
    
    func testRetryOnFailureExpansion_withoutFunctionBody() {
        assertMacroExpansion(
            """
            protocol MyProtocol {
                @RetryOnFailure(retries: 3)
                func fetchData() throws
            }
            """,
            expandedSource: """
            protocol MyProtocol {
                func fetchData() throws
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Function must have a body to apply retry logic", line: 2, column: 5)
            ],
            macros: testMacros
        )
    }
    
    func testRetryOnFailureExpansion_withAsyncFunction() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 4)
            func fetchData() async throws {
                await networkCall()
            }
            """,
            expandedSource: """
            func fetchData() async throws {
                func \(helperFuncName)() async throws {
                    await networkCall()
                }
                var \(attemptsDeclName) = 0
                while \(attemptsDeclName) < 4 {
                    do {
                        return try await \(helperFuncName)()
                    } catch {
                        \(attemptsDeclName) += 1
                        if \(attemptsDeclName) == 4 {
                            throw error
                        }
                    }
                }
                fatalError("Unknown Error")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRetryOnFailureExpansion_withReturnValueAndParameters() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 3)
            func processData(id: Int) throws -> String {
                return try fetchDataById(id: id)
            }
            """,
            expandedSource: """
            func processData(id: Int) throws -> String {
                func \(helperFuncName)() throws -> String {
                    return try fetchDataById(id: id)
                }
                var \(attemptsDeclName) = 0
                while \(attemptsDeclName) < 3 {
                    do {
                        return try \(helperFuncName)()
                    } catch {
                        \(attemptsDeclName) += 1
                        if \(attemptsDeclName) == 3 {
                            throw error
                        }
                    }
                }
                fatalError("Unknown Error")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRetryOnFailureExpansion_withAsyncReturnValueAndParameters() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 2)
            func processAsyncData(id: Int) async throws -> String {
                return try await fetchDataByIdAsync(id: id)
            }
            """,
            expandedSource: """
            func processAsyncData(id: Int) async throws -> String {
                func \(helperFuncName)() async throws -> String {
                    return try await fetchDataByIdAsync(id: id)
                }
                var \(attemptsDeclName) = 0
                while \(attemptsDeclName) < 2 {
                    do {
                        return try await \(helperFuncName)()
                    } catch {
                        \(attemptsDeclName) += 1
                        if \(attemptsDeclName) == 2 {
                            throw error
                        }
                    }
                }
                fatalError("Unknown Error")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRetryOnFailureExpansion_withVoidReturnType() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 3)
            func performOperation() throws {
                try someOperation()
            }
            """,
            expandedSource: """
            func performOperation() throws {
                func \(helperFuncName)() throws {
                    try someOperation()
                }
                var \(attemptsDeclName) = 0
                while \(attemptsDeclName) < 3 {
                    do {
                        return try \(helperFuncName)()
                    } catch {
                        \(attemptsDeclName) += 1
                        if \(attemptsDeclName) == 3 {
                            throw error
                        }
                    }
                }
                fatalError("Unknown Error")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testRetryOnFailureExpansion_withNonThrowingAsyncFunction() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 2)
            func nonThrowingAsyncFunction() async {
                await someAsyncOperation()
            }
            """,
            expandedSource: """
            func nonThrowingAsyncFunction() async {
                await someAsyncOperation()
            }
            """,
            diagnostics: [
                DiagnosticSpec(message: "Macro can only be applied to throwing functions", line: 1, column: 1)
            ],
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

    func testRetryOnFailureExpansion_withNoErrorThrown() throws {
        #if canImport(RetryOnFailureMacros)
        assertMacroExpansion(
            """
            @RetryOnFailure(retries: 3)
            func fetchData() throws {
                print("Data fetched without error")
            }
            """,
            expandedSource: """
            func fetchData() throws {
                func \(helperFuncName)() throws {
                    print("Data fetched without error")
                }
                var \(attemptsDeclName) = 0
                while \(attemptsDeclName) < 3 {
                    do {
                        return try \(helperFuncName)()
                    } catch {
                        \(attemptsDeclName) += 1
                        if \(attemptsDeclName) == 3 {
                            throw error
                        }
                    }
                }
                fatalError("Unknown Error")
            }
            """,
            macros: testMacros
        )
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}
