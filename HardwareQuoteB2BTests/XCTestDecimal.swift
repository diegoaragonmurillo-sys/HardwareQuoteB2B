import XCTest

/// `XCTAssertEqual(_:_:accuracy:)` no admite `Decimal`; esta sobrecarga compara montos con tolerancia.
func XCTAssertEqual(
    _ expresion1: @autoclosure () throws -> Decimal,
    _ expresion2: @autoclosure () throws -> Decimal,
    accuracy: Decimal,
    _ mensaje: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    do {
        let a = try expresion1()
        let b = try expresion2()
        let diferencia = a > b ? a - b : b - a
        XCTAssertTrue(
            diferencia <= accuracy,
            "\(a) no es igual a \(b) (tolerancia \(accuracy)). \(mensaje())",
            file: file, line: line
        )
    } catch {
        XCTFail("Se lanzó un error: \(error)", file: file, line: line)
    }
}
