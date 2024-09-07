import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum MacroExpansionError: Error, CustomStringConvertible {
    case message(String)
    
    public var description: String {
        switch self {
        case .message(let message):
            return message
        }
    }
}

public struct RetryOnFailureMacro: BodyMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingBodyFor declaration: some SwiftSyntax.DeclSyntaxProtocol & SwiftSyntax.WithOptionalCodeBlockSyntax, 
        in context: some MacroExpansionContext
    ) throws -> [CodeBlockItemSyntax] {
        guard
            let argumentList = node.arguments?.as(LabeledExprListSyntax.self),
            let retriesArgument = argumentList.first,
            let retriesLiteral = retriesArgument.expression.as(IntegerLiteralExprSyntax.self)
        else {
            throw MacroExpansionError.message("Missing or invalid 'retries' parameter")
        }
        
        let retries = retriesLiteral.literal.text
        
        guard
            let retriesCount = Int(retries),
            retriesCount > 0
        else {
            throw MacroExpansionError.message("Retries count must be positive")
        }
        
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw MacroExpansionError.message("Macro can only be applied to function declarations")
        }
        
        guard funcDecl.signature.effectSpecifiers?.throwsClause?.throwsSpecifier != nil else {
            throw MacroExpansionError.message("Macro can only be applied to throwing functions")
        }
        
        guard funcDecl.body != nil else {
            throw MacroExpansionError.message("Function must have a body to apply retry logic")
        }

        let isFunctionAsync = funcDecl.signature.effectSpecifiers?.asyncSpecifier != nil
        let attemptsName = context.makeUniqueName("attempts")
        let helperFunctionName = context.makeUniqueName("block")
        
        let catchClauseBlock = CatchClauseSyntax("catch") {
            CodeBlockItemSyntax(item: .expr("\(attemptsName) += 1"))
            IfExprSyntax(
                conditions: ConditionElementListSyntax {
                    ConditionElementSyntax(
                        condition: .expression("\(attemptsName) == \(raw: retries)")
                    )
                },
                body: CodeBlockSyntax(
                    statementsBuilder: {
                        ThrowStmtSyntax(expression: ExprSyntax("error"))
                    }
                )
            )
        }
        
        let helperFuncDecl = funcDecl
            .with(\.name, helperFunctionName)
            .with(\.attributes, [])
            .with(\.signature.parameterClause.parameters, [])
        
        let functionCallBlock = FunctionCallExprSyntax(
            calledExpression: ExprSyntax("\(helperFunctionName)"),
            leftParen: .leftParenToken(),
            arguments: [],
            rightParen: .rightParenToken()
        )
        
        let tryBlock: TryExprSyntax
        if isFunctionAsync {
            tryBlock = TryExprSyntax(
                expression: AwaitExprSyntax(
                    expression: functionCallBlock
                )
            )
        } else {
            tryBlock = TryExprSyntax(expression: functionCallBlock)
        }

        let doBlock = DoStmtSyntax(
            body: CodeBlockSyntax(
                statementsBuilder: {
                    ReturnStmtSyntax(
                        expression: tryBlock
                    )
                }
            ),
            catchClauses: CatchClauseListSyntax {
                catchClauseBlock
            }
        )
        
        let whileBlock = WhileStmtSyntax(
            conditions: ConditionElementListSyntax {
                ConditionElementSyntax(
                    condition: .expression("\(attemptsName) < \(raw: retries)")
                )
            },
            body: CodeBlockSyntax {
                doBlock
            }
        )
        
        let codeBlock = CodeBlockItemListSyntax {
            helperFuncDecl
            CodeBlockItemSyntax(item: .decl("var \(attemptsName) = 0"))
            whileBlock
            
            // This will never be reached, but the compiler needs to know
            // that all paths are accounted for:
            CodeBlockItemSyntax(item: .expr("fatalError(\"Unknown Error\")"))
        }
        
        return Array(codeBlock)
    }
}

@main
struct RetryOnFailurePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        RetryOnFailureMacro.self,
    ]
}
