import Foundation
import RetryOnFailure

enum NetworkError: Error {
    case connectionLost
}

// Non-async non-returning function.

@RetryOnFailure(retries: 3)
func sendData(data: String) throws {
    try networkCall(data: data)
}

func networkCall(data: String) throws {
    print("Performing network call...")
    let succeed = Bool.random()
    
    if succeed {
        print("\"\(data)\" sent")
    } else {
        throw NetworkError.connectionLost
    }
}

try sendData(data: "Hello there!")
print()

// Non-async returning function.

@RetryOnFailure(retries: 3)
func fetchData() throws -> String {
    try networkCallWithData()
}

func networkCallWithData() throws -> String {
    print("Performing network call...")
    let succeed = Bool.random()
    
    if succeed {
        print("Network call succeed")
        return "Hello, World!"
    } else {
        throw NetworkError.connectionLost
    }
}

let result = try fetchData()
print("Result is \"\(result)\"")
print()

// Async non-returning function.

@RetryOnFailure(retries: 3)
func asyncSendData() async throws {
    try await asyncNetworkCall()
}

func asyncNetworkCall() async throws {
    print("Performing async network call...")
    let succeed = Bool.random()
    
    if succeed {
        print("Network call succeed")
    } else {
        throw NetworkError.connectionLost
    }
}

try await asyncSendData()
print()

// Async returning function.

@RetryOnFailure(retries: 3)
func asyncFetchData() async throws -> String {
    try await asyncNetworkCallWithData()
}

func asyncNetworkCallWithData() throws -> String {
    print("Performing async network call...")
    let succeed = Bool.random()
    
    if succeed {
        print("Network call succeed")
        return "Async Hello, World!"
    } else {
        throw NetworkError.connectionLost
    }
}

let asyncResult = try await asyncFetchData()
print("Result is \"\(asyncResult)\"")
print()
