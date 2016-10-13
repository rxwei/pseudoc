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
    static let variableName = regex("[a-zA-Z][a-zA-Z0-9_]*")
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
    private static let negation = Lexer.regex("not\\s|[¬!]") ~~> rawExpression.! ^^ Expression.negation
    private static let complement = Lexer.character("-") ~~> rawExpression.! ^^ Expression.complement
    
    /// Array addressing
    private static let arrayElement = Lexer.arrayName ~~
        rawExpression.manyOrNone(separatedBy: Lexer.comma).between("[", "]") ^^ Expression.arrayElement

    private static let arraySlice = Lexer.arrayName <~~ "[" ^^ curry(Expression.arraySlice)
         ** rawExpression.! ** (".." ~~> rawExpression.!) <~~ "]"

    /// Call
    private static let functionCall = Lexer.functionName ~~
        rawExpression.manyOrNone(separatedBy: Lexer.comma).between("(", ")") ^^ Expression.call

    /// Parenthesized
    private static let parenthesized = (rawExpression.!).between("(", ")")

    /// Operator functions
    /// Precedence from lowest to highest
    private static let logicalOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.regex("\\s*(and|∧|&&?)\\s*")    ^^ { _ in { .logical(.and, $0, $1) } }
      | Lexer.regex("\\s*(or|∨|\\|\\|?)\\s*") ^^ { _ in { .logical(.or, $0, $1) } }
    
    private static let comparativeOperator: Parser<(Expression, Expression) -> Expression> =
        Lexer.regex("\\s?\\>\\=\\s?") ^^ { _ in { .comparative(.greaterThanOrEqualTo, $0, $1) } }
      | Lexer.regex("\\s?\\<\\=\\s?") ^^ { _ in { .comparative(.lessThanOrEqualTo, $0, $1) } }
      | Lexer.regex("\\s?>\\s?")  ^^ { _ in { .comparative(.greaterThan, $0, $1) } }
      | Lexer.regex("\\s?<\\s?")  ^^ { _ in { .comparative(.lessThan, $0, $1) } }
      | Lexer.regex("\\s?=\\s?") ^^ { _ in { .comparative(.equalTo, $0, $1) } }

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
    fileprivate static let rawExpression = simpleExpression.infixedLeft(by: multiplicativeOperator)
                                               .infixedLeft(by: additiveOperator)
                                               .infixedLeft(by: comparativeOperator)
                                               .infixedLeft(by: logicalOperator)
                                               .tagged("an expression")
    static let expression = rawExpression.amid(Lexer.whitespaces.?)
}

enum StatementGrammar {

    private static let bareExpression = Lexer.character("_") ~~> Lexer.regex("\\s*<-\\s*") ~~>
        ExpressionGrammar.rawExpression.! ^^ Statement.bareExpression

    private static let assignment = Lexer.variableName <~~ Lexer.regex("\\s*<-\\s*") ~~
        ExpressionGrammar.rawExpression.! ^^ Statement.assignment

    private static let ifStatement =
        Lexer.regex("if\\s+") ~~> ExpressionGrammar.rawExpression.! ^^ curry(Statement.if)
            <~~ Lexer.regex("\\s*\n\\s*")
            ** statement.many(separatedBy: Lexer.regex("\\s*\n\\s*"))
            <~~ Lexer.regex("\n\\s*else\\s*\n\\s*").!
            ** statement.many(separatedBy: Lexer.regex("\\s*\n\\s*"))
            <~~ Lexer.regex("\\s*\n\\s*end")

    private static let whileStatement =
        Lexer.regex("while\\s+") ~~> ExpressionGrammar.rawExpression.! ^^ curry(Statement.while)
            <~~ Lexer.regex("\\s*\n\\s*")
            ** statement.many(separatedBy: Lexer.regex("\\s*\n\\s*"))
            <~~ Lexer.regex("\\s*\n\\s*end")

    private static let printStatement =
        Lexer.regex("print\\s+") ~~> ExpressionGrammar.rawExpression.! ^^ Statement.print

    static let statement: Parser<Statement> =
        assignment | bareExpression | printStatement | ifStatement | whileStatement <!-- "an expression"

}

enum TopLevelGrammar {

    private static let topLevelItem = StatementGrammar.statement ^^ Program.TopLevelItem.statement

    private static let programBody = topLevelItem.many(separatedBy: Lexer.regex("(\\s*\n\\s*)+"))

    static func parseProgram(_ text: String, named name: String) throws -> Program {
        let body = try programBody.parse(text)
        return Program(name: name, body: body)
    }

}
