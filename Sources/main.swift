repeat {
    guard let line = readLine(), !line.isEmpty else { continue }

    do {
        let ast = try ExpressionGrammar.expression.parse(line)
        dump(ast)
    } catch {
        print(error)
    }
    
} while true
