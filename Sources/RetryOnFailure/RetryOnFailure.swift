import Foundation

@attached(body)
public macro RetryOnFailure(retries: Int = 3) = #externalMacro(
    module: "RetryOnFailureMacros",
    type: "RetryOnFailureMacro"
)
