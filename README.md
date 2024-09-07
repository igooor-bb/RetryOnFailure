# RetryOnFailure

**Retry On Failure** is a Swift macro that provides a simple way to retry functions that might throw an error, automatically attempting them a specified number of times under the hood.

Inspired by [Java's Aspect-Oriented Programming (AOP)](https://aspects.jcabi.com), this macro allows developers to avoid repetitive retry code and improve error handling in Swift.

```swift
@RetryOnFailure(retries: 3)
func fetchData() throws {
    try performNetworkRequest()
}
```

## Requirements

The only technical requirement is Swift 6.

The `BodyMacros` feature flag is enabled in the package to expose the macros. See ["Using Upcoming Feature Flags"](https://www.swift.org/blog/using-upcoming-feature-flags/) for more information.

> Keep in mind that the macro was created as an experiment when I saw [BodyMacros appear in Swift](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0415-function-body-macros.md), so the source code can be used as a sample use case for new functionality that may still undergo changes before the final Swift release.

## Macro Expansion

For a function annotated with the macro:

```swift
@RetryOnFailure(retries: 3)
func fetchData() throws {
    try performNetworkRequest()
}
```

The macro will generate the following code:

```swift
func fetchData() throws {
    func block() throws {
        try performNetworkRequest()
    }
    var attempts = 0
    while attempts < 3 {
        do {
            return try block()
        } catch {
            attempts += 1
            if attempts == 3 {
                throw error
            }
        }
    }
}
```

> The counter variable name and function name will be uniquely obfuscated within the current context.

An additional scope in the form of a block function is used to be able to return the value if required as well as exit the loop at the right time.

Macro also supports async/await:

```swift
@RetryOnFailure(retries: 3)
func fetchData() async throws {
    try await performNetworkRequest()
}
```

## Contribution

To contribute, use the follow "fork-and-pull" git workflow:

1. Fork the repository on github
2. Clone the project to your own machine
3. Commit changes to your own branch
4. Push your work back up to your fork
5. Submit a pull request so that I can review your changes

*NOTE: Be sure to merge the latest from "upstream" before making a pull request!*

## License

This project is licensed under the MIT License. See the LICENSE file for more details.
