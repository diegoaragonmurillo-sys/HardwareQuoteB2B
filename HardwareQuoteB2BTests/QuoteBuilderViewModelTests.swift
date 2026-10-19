//
//  QuoteBuilderViewModelTests.swift
//  HardwareQuoteB2BTests
//

import XCTest
@testable import HardwareQuoteB2B

private struct ServicioFalsoSinRed: TipoCambioServicing {
    func obtenerTasas() async throws -> TasasCambioUSD {
        TasasCambioUSD(mxn: 1, pen: 1, fechaActualizacion: Date())
    }
}

@MainActor
final class QuoteBuilderViewModelTests: XCTestCase {

    private var sut: QuoteBuilderViewModel!
    private let precision: Decimal = 0

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = QuoteBuilderViewModel(
            clienteNombre: "Corporativo Test B2B",
            componentesSeleccionados: [],
            margenGanancia: 0.0,
            servicioTipoCambio: ServicioFalsoSinRed()
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testCalculoDeDemandaEnergeticaYSubtotal() {
        // Arrange
        let cpuMock = Componente(
            nombre: "AMD Ryzen 9 9950X",
            categoria: .cpu,
            precioBase: 650.00,
            socket: "AM5",
            consumoWatts: 170,
            stock: 10
        )
        let gpuMock = Componente(
            nombre: "NVIDIA RTX 4500 Ada",
            categoria: .gpu,
            precioBase: 2250.00,
            socket: "PCIe 4.0",
            consumoWatts: 210,
            stock: 5
        )

        // Act
        sut.componentesSeleccionados = [cpuMock, gpuMock]

        // Assert
        let subtotalEsperado: Decimal = 2900.00 // 650.00 + 2250.00
        let wattsEsperados: Int = 380          // 170W + 210W

        XCTAssertEqual(
            sut.subtotal,
            subtotalEsperado,
            accuracy: precision,
            "El subtotal en USD debe ser la suma exacta de los precios base de los componentes."
        )
        XCTAssertEqual(
            sut.consumoTotalWatts,
            wattsEsperados,
            "El consumo total en Watts debe coincidir con la suma energética de la CPU y la GPU."
        )
    }

    func testCalculoDeMargenComercial() {
        // Arrange
        let servidorMock = Componente(
            nombre: "Intel Xeon w7-2495X",
            categoria: .cpu,
            precioBase: 2000.00,
            socket: "LGA4677",
            consumoWatts: 225,
            stock: 4
        )

        // Act
        sut.componentesSeleccionados = [servidorMock]
        sut.margenGanancia = 0.20 // 20% de margen comercial

        // Assert
        let utilidadEsperada: Decimal = 400.00   // 2000.00 * 0.20
        let precioFinalEsperado: Decimal = 2400.00 // 2000.00 + 400.00

        XCTAssertEqual(
            sut.utilidadComercial,
            utilidadEsperada,
            accuracy: precision,
            "La utilidad comercial debe corresponder al 20% del subtotal."
        )
        XCTAssertEqual(
            sut.precioFinal,
            precioFinalEsperado,
            accuracy: precision,
            "El total final de la cotización debe incluir correctamente el 20% de margen comercial."
        )
    }
}
