//
//  Grammar.swift
//  Pseudoc
//
//  Created by Richard Wei on 10/12/16.
//
//

import Funky
import Parsey

extension Lexer {
    static let functionName = regex("[A-Z][a-zA-Z0-9]*")
    static let variableName = regex("[a-zA-Z_][a-zA-Z0-9_]*")
    static let arrayName = regex("[A-Z][a-zA-Z0-9]*")
    static let comma = regex("\\s*,\\s*")
}

enum ExpressionGrammar {
    /// Primitives
    private static let integer = Lexer.signedInteger ^^ {Int($0)!} ^^ Expression.integer
    private static let float = Lexer.signedDecimal ^^ {Float($0)!} ^^ Expression.float
    private static let bool = Lexer.token("True") ^^ { _ in Expression.bool(true) }
                            | Lexer.token("False") ^^ { _ in Expression.bool(false) }
    private static let variable = Lexer.variableName ^^ Expression.variable

    /// Prefix operations
    private static let negation = Lexer.regex("not\\s|[¬!]") ~~> expression.! ^^ Expression.negation
    private static let complement = Lexer.character("-") ~~> expression.! ^^ Expression.complement
    
    /// Array addressing
    private static let arrayElement = Lexer.arrayName ~~
        expression.manyOrNone(separatedBy: Lexer.comma).between("[", "]") ^^ Expression.arrayElement

    private static let arraySlice = Lexer.arrayName <~~ "[" ^^ curry(Expression.arraySlice)
         ** expression.! ** (".." ~~> expression.!) <~~ "]"

    /// Call
    private static let functionCall = Lexer.functionName ~~
        expression.manyOrNone(separatedBy: Lexer.comma).between("(", ")") ^^ Expression.call

    /// Parenthesized
    private static let parenthesized = (expression.!).between("(", ")")

    /// Operator functions
    /// Precedence from lowest to highest
    private static let logicalOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.regex("\\s*(and|∧|&&?)\\s*")    ^^ { _ in { .logical(.and, $0, $1) } }
      | Lexer.regex("\\s*(or|∨|\\|\\|?)\\s*") ^^ { _ in { .logical(.or, $0, $1) } }
    
    private static let comparativeOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.regex("\\s?>\\s?")  ^^ { _ in { .comparative(.greaterThan, $0, $1) } }
      | Lexer.regex("\\s?>=\\s?") ^^ { _ in { .comparative(.greaterThanOrEqualTo, $0, $1) } }
      | Lexer.regex("\\s?<\\s?")  ^^ { _ in { .comparative(.lessThan, $0, $1) } }
      | Lexer.regex("\\s?<=\\s?") ^^ { _ in { .comparative(.lessThanOrEqualTo, $0, $1) } }

    private static let additiveOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.regex("\\s?\\+\\s?") ^^ { _ in { .additive(.plus, $0, $1) } }
      | Lexer.regex("\\s?\\-\\s?") ^^ { _ in { .additive(.minus, $0, $1) } }

    private static let multiplicativeOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.regex("\\s?\\*\\s?") ^^ { _ in { .multiplicative(.times, $0, $1) } }
      | Lexer.regex("\\s?/\\s?")   ^^ { _ in { .multiplicative(.division, $0, $1) } }

    /// Non-left-recursive expression parser
    private static let simpleExpression: Parser<Expression> =
        integer | float | bool                   /// Primitives
      | negation | complement                    /// Prefix operation
      | arrayElement | arraySlice | functionCall /// Array indexing and dispatch
      | variable                                 /// Simple variable
      | parenthesized                            /// Expression in parentheses

    /// Full expression parser with infix expression precedence
    static let expression = simpleExpression.infixedLeft(by: multiplicativeOperator)
                                            .infixedLeft(by: additiveOperator)
                                            .infixedLeft(by: comparativeOperator)
                                            .infixedLeft(by: logicalOperator)
                                            .tagged("an expression")
}
