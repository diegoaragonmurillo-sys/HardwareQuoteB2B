import XCTest
@testable import HardwareQuoteB2B

private struct ServicioTipoCambioFalso: TipoCambioServicing {
    let resultado: Result<TasasCambioUSD, Error>
    func obtenerTasas() async throws -> TasasCambioUSD { try resultado.get() }
}

@MainActor
final class TipoCambioTests: XCTestCase {

    func testDecodificar_respuestaValida_extraeMXNyPEN() throws {
        let json = """
        {"result":"success","time_last_update_unix":1792368152,
         "rates":{"USD":1,"MXN":18.5,"PEN":3.75}}
        """.data(using: .utf8)!

        let tasas = try TipoCambioService.decodificar(json)

        XCTAssertEqual(tasas.mxn, 18.5, accuracy: 0.0001)
        XCTAssertEqual(tasas.pen, 3.75, accuracy: 0.0001)
    }

    func testDecodificar_sinPEN_lanzaMonedaNoDisponible() {
        let json = """
        {"result":"success","time_last_update_unix":1,"rates":{"MXN":18.5}}
        """.data(using: .utf8)!

        XCTAssertThrowsError(try TipoCambioService.decodificar(json)) { error in
            XCTAssertEqual(error as? TipoCambioError, .monedaNoDisponible("PEN"))
        }
    }

    func testViewModel_convierteTotalAMXNyPEN() async throws {
        let tasas = TasasCambioUSD(mxn: 20, pen: 4, fechaActualizacion: Date())
        let componente = Componente(nombre: "CPU", categoria: .cpu, precioBase: 100,
                                    socket: "AM5", consumoWatts: 100, stock: 1)
        let sut = QuoteBuilderViewModel(
            componentesSeleccionados: [componente],
            margenGanancia: 0.0,
            servicioTipoCambio: ServicioTipoCambioFalso(resultado: .success(tasas))
        )

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(sut.precioFinalMXN, 2000, accuracy: 0.0001)
        XCTAssertEqual(sut.precioFinalPEN, 400, accuracy: 0.0001)
        XCTAssertFalse(sut.errorTipoCambio)
    }

    func testViewModel_siFallaLaAPI_marcaError() async throws {
        let sut = QuoteBuilderViewModel(
            componentesSeleccionados: [],
            servicioTipoCambio: ServicioTipoCambioFalso(resultado: .failure(TipoCambioError.respuestaInvalida))
        )

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertTrue(sut.errorTipoCambio)
    }
}
