import Foundation
import Parsey

public enum IOError : Error, CustomStringConvertible {
    case fileNotFound
    case cannotDecodeData
    case noInput

    public var description: String {
        switch self {
        case .fileNotFound: return "File not found"
        case .cannotDecodeData: return "Cannot decode data"
        case .noInput: return "No input"
        }
    }
}

func parseFile(_ filePath: String) throws -> Program {
    let path = Bundle.main.path(forResource: filePath, ofType: nil) ?? filePath
    guard FileManager.default.fileExists(atPath: path) else {
        throw IOError.fileNotFound
    }
    let url = URL(fileURLWithPath: path)
    let data = try FileHandle(forReadingFrom: url).readDataToEndOfFile()
    guard let text = String(data: data, encoding: .utf8) else {
        throw IOError.cannotDecodeData
    }
    return try TopLevelGrammar.parseProgram(text, named: url.deletingPathExtension().lastPathComponent)
}

///// Take input from console and print AST
func repl<T>(parsing: Parser<T>) {
    while true {
        print("> ", terminator: "")
        guard let line = readLine(), !line.isEmpty else { continue }
        do {
            let ast = try parsing.parse(line)
            dump(ast)
        }
        catch let error {
            print(error)
        }
    }
}

do {
    guard let arg = CommandLine.arguments.dropFirst().first else {
        throw IOError.noInput
    }
    switch arg {
        case "-expr":
            repl(parsing: ExpressionGrammar.expression)
        case "-stmt":
            repl(parsing: StatementGrammar.statement)
        case "-ast":
            let inputPath = CommandLine.arguments[2]
            let ast = try parseFile(inputPath)
            dump(ast)
        case "-help":
            print("-prog : Program REPL")
            print("-expr : AST.Expression REPL")
            print("-ast <source> : Parse AST")
            print("-sema <source> : Parse and type check")
        default:
            let inputPath = CommandLine.arguments[1]
            let ast = try parseFile(inputPath)
            dump(ast)
    }
}
catch {
    print(error)
}

