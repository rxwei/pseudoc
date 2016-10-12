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
    case variable(String)
    case call(String, [Expression]) /// Side effects
    case arrayElement(atIndex: [Expression])
    case subarray(lowerBound: Expression, upperBound: Expression)
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
    static let functionName = Lexer.regex("[A-Z][a-zA-Z0-9]*")
    static let variableName = Lexer.regex("[a-zA-Z_][a-zA-Z0-9_]*")
}

enum ExpressionGrammar {
    static let integer = Lexer.signedInteger ^^ {Int($0)!} ^^ Expression.integer
    static let float = Lexer.signedDecimal ^^ {Float($0)!} ^^ Expression.float
    static let variable = Lexer.variableName ^^ Expression.variable
}
