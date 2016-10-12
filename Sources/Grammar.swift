//
//  Grammar.swift
//  Pseudoc
//
//  Created by Richard Wei on 10/12/16.
//
//

import Parsey

/// Expression
/// Everything returns a value
indirect enum Expression {
    case integer(Int)
    case float(Float)
    case bool(Bool)
    case variable(String)
    case additive(AdditiveOperator, Expression, Expression)
    case multiplicative(MultiplicativeOperator, Expression, Expression)
    case comparative(ComparativeOperator, Expression, Expression)
    case logical(LogicalOperator, Expression, Expression)
    case negation(Expression)
    case complement(Expression)
    case call(String, [Expression]) /// Side effects
    case arrayElement(atIndex: [Expression])
    case subarray(lowerBound: Expression, upperBound: Expression)

    enum ComparativeOperator {
        case lessThan, greaterThan, lessThanOrEqualTo, greaterThanOrEqualTo
    }

    enum AdditiveOperator {
        case plus, minus
    }

    enum MultiplicativeOperator {
        case times, division
    }

    enum LogicalOperator {
        case and, or
    }
}

/// Statement
/// Everything has side effects
indirect enum Statement {
    case nothing(Expression)
    case verbal(String)
    case assign(String, Expression)
    case `if`(condition: Expression, body: [Statement], `else`: [Statement])
    case `while`(condition: Expression, body: Expression)
    case `for`(iterator: String, lowerBound: Expression, upperBound: Expression)
}

/// Definition
/// Example:
/// ```
///   FunctionName(arg1, Arg2[A..n], arg3):
///     statement-1
///     statement-2
///     ...
/// ```
struct Definition {
    enum Argument {
        case array(dimensions: [(Int, Int)])
        case variable(String)
    }
    let name: String, arguments: [Argument]
    let body: [Statement]
}

/// Top Level Item
enum TopLevelItem {
    case definition(Definition)
    case statement(Statement)
}

extension Lexer {
    static let functionName = regex("[A-Z][a-zA-Z0-9]*")
    static let variableName = regex("[a-zA-Z_][a-zA-Z0-9_]*")
    static let conjunction = regex("and|∧|&{1-2}")
    static let disjunction = regex("or|∨|\\|{1-2}")
    static let negation = regex("not|[¬!]")
    static let comma = regex(",\\s+")
}

enum ExpressionGrammar {
    /// Primitives
    static let integer = Lexer.signedInteger ^^ {Int($0)!} ^^ Expression.integer
    static let float = Lexer.signedDecimal ^^ {Float($0)!} ^^ Expression.float
    static let bool = Lexer.token("True") ^^ { _ in Expression.bool(true) }
                    | Lexer.token("False") ^^ { _ in Expression.bool(false) }
    static let variable = Lexer.variableName ^^ Expression.variable

    /// Prefix operations
    static let negation = Lexer.negation ~~> expression ^^ Expression.negation
    static let complement = Lexer.character("-") ~~> expression ^^ Expression.complement

    /// Call
    static let call = Lexer.functionName ~~ expression.manyOrNone(separatedBy: Lexer.comma)
                   ^^ Expression.call

    /// Operator functions
    /// Precedence from lowest to highest
    static let logicalOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.conjunction ^^ { _ in { .logical(.and, $0, $1) } }
      | Lexer.disjunction ^^ { _ in { .logical(.or, $0, $1) } }

    static let comparativeOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.token(">") ^^ { _ in { .comparative(.greaterThan, $0, $1) } }
      | Lexer.token(">=") ^^ { _ in { .comparative(.greaterThan, $0, $1) } }
      | Lexer.token("<") ^^ { _ in { .comparative(.greaterThan, $0, $1) } }
      | Lexer.token("<=") ^^ { _ in { .comparative(.greaterThan, $0, $1) } }

    static let additiveOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.token("+") ^^ { _ in { .additive(.plus, $0, $1) } }
      | Lexer.token("-") ^^ { _ in { .additive(.minus, $0, $1) } }

    static let multiplicativeOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.token("*") ^^ { _ in { .multiplicative(.times, $0, $1) } }
      | Lexer.token("/") ^^ { _ in { .multiplicative(.division, $0, $1) } }

    static let nonLRExpression: Parser<Expression> =
        integer | float | bool | variable | negation | complement | call

    /// Set up infix expression precedence
    static let expression = nonLRExpression.infixedLeft(by: multiplicativeOperator)
                                           .infixedLeft(by: additiveOperator)
                                           .infixedLeft(by: comparativeOperator)
                                           .infixedLeft(by: logicalOperator)
}
