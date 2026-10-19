import XCTest
@testable import HardwareQuoteB2B

@MainActor
final class ValidadorCompatibilidadTests: XCTestCase {

    private func pieza(_ nombre: String, _ categoria: CategoriaComponente,
                       socket: String? = nil, watts: Int = 0) -> Componente {
        Componente(nombre: nombre, categoria: categoria, precioBase: 100,
                   socket: socket, consumoWatts: watts, stock: 1)
    }

    func testSocketIgual_noHayProblemas() {
        let problemas = ValidadorCompatibilidad.validar([
            pieza("Ryzen", .cpu, socket: "AM5", watts: 100),
            pieza("Placa X870", .placa, socket: "am5 ", watts: 50),
            pieza("Fuente", .fuente, watts: 850)
        ])

        XCTAssertTrue(problemas.isEmpty)
    }

    func testSocketDistinto_generaErrorConNombres() {
        let problemas = ValidadorCompatibilidad.validar([
            pieza("Xeon", .cpu, socket: "LGA4677", watts: 100),
            pieza("Placa AM5", .placa, socket: "AM5", watts: 50),
            pieza("Fuente", .fuente, watts: 850)
        ])

        XCTAssertEqual(problemas.count, 1)
        XCTAssertEqual(problemas.first?.severidad, .error)
        XCTAssertTrue(problemas.first?.mensaje.contains("Xeon") ?? false)
        XCTAssertTrue(problemas.first?.mensaje.contains("Placa AM5") ?? false)
    }

    func testSinSocketRegistrado_noSeMarcaIncompatible() {
        let problemas = ValidadorCompatibilidad.validar([
            pieza("CPU", .cpu, socket: nil, watts: 100),
            pieza("Placa", .placa, socket: "AM5", watts: 50),
            pieza("Fuente", .fuente, watts: 850)
        ])

        XCTAssertTrue(problemas.isEmpty)
    }

    func testConsumoMayorQueLaFuente_esSobrecarga() {
        let problemas = ValidadorCompatibilidad.validar([
            pieza("GPU", .gpu, watts: 600),
            pieza("CPU", .cpu, watts: 300),
            pieza("Fuente 850", .fuente, watts: 850)
        ])

        XCTAssertEqual(problemas.count, 1)
        XCTAssertEqual(problemas.first?.severidad, .error)
        XCTAssertTrue(problemas.first?.mensaje.contains("900 W") ?? false)
    }

    func testConsumoJustoEnLaCapacidad_noEsSobrecargaPeroAdvierte() {
        let problemas = ValidadorCompatibilidad.validar([
            pieza("GPU", .gpu, watts: 850),
            pieza("Fuente 850", .fuente, watts: 850)
        ])

        XCTAssertEqual(problemas.first?.severidad, .advertencia)
    }

    func testConsumoSobreElUmbral80_advierte() {
        let problemas = ValidadorCompatibilidad.validar([
            pieza("GPU", .gpu, watts: 700),
            pieza("Fuente 850", .fuente, watts: 850)
        ])

        XCTAssertEqual(problemas.count, 1)
        XCTAssertEqual(problemas.first?.severidad, .advertencia)
    }

    func testConsumoHolgado_noGeneraProblemas() {
        let problemas = ValidadorCompatibilidad.validar([
            pieza("GPU", .gpu, watts: 300),
            pieza("Fuente 850", .fuente, watts: 850)
        ])

        XCTAssertTrue(problemas.isEmpty)
    }

    func testSinFuente_advierteQueFalta() {
        let problemas = ValidadorCompatibilidad.validar([pieza("GPU", .gpu, watts: 300)])

        XCTAssertEqual(problemas.first?.severidad, .advertencia)
        XCTAssertTrue(problemas.first?.mensaje.contains("fuente") ?? false)
    }

    func testCantidadDuplicada_sumaElConsumo() {
        let gpu = pieza("GPU", .gpu, watts: 300)
        let problemas = ValidadorCompatibilidad.validar([
            gpu, gpu, gpu,
            pieza("Fuente 850", .fuente, watts: 850)
        ])

        XCTAssertEqual(problemas.first?.severidad, .error, "3 × 300 W = 900 W supera 850 W")
    }

    func testViewModel_exponeErroresDeCompatibilidad() {
        struct SinRed: TipoCambioServicing {
            func obtenerTasas() async throws -> TasasCambioUSD {
                TasasCambioUSD(mxn: 1, pen: 1, fechaActualizacion: Date())
            }
        }
        let sut = QuoteBuilderViewModel(
            componentesSeleccionados: [
                pieza("GPU", .gpu, watts: 900),
                pieza("Fuente 850", .fuente, watts: 850)
            ],
            servicioTipoCambio: SinRed()
        )

        XCTAssertTrue(sut.hayErroresCompatibilidad)
    }

    func testCatalogoDemostracion_porDefectoEsCompatible() {
        let problemas = ValidadorCompatibilidad.validar(QuoteBuilderViewModel.componentesDemostracion)

        XCTAssertFalse(problemas.contains { $0.severidad == .error })
    }
}
