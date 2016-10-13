//
//  AST.swift
//  Pseudoc
//
//  Created by Richard Wei on 10/12/16.
//
//

import Foundation

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
    case arrayElement(String, atIndex: [Expression])
    case arraySlice(String, lowerBound: Expression, upperBound: Expression)

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
