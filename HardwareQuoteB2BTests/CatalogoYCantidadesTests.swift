import XCTest
import SwiftData
@testable import HardwareQuoteB2B

@MainActor
final class CatalogoYCantidadesTests: XCTestCase {

    private struct ServicioSinRed: TipoCambioServicing {
        func obtenerTasas() async throws -> TasasCambioUSD {
            TasasCambioUSD(mxn: 1, pen: 1, fechaActualizacion: Date())
        }
    }

    private func crearContexto() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let contenedor = try ModelContainer(
            for: Cotizacion.self, Componente.self, LineaCotizacion.self,
            configurations: config
        )
        return ModelContext(contenedor)
    }

    private func crearViewModel(_ componentes: [Componente] = []) -> QuoteBuilderViewModel {
        QuoteBuilderViewModel(
            componentesSeleccionados: componentes,
            margenGanancia: 0,
            servicioTipoCambio: ServicioSinRed()
        )
    }

    private func componente(_ nombre: String, precio: Decimal) -> Componente {
        Componente(nombre: nombre, categoria: .ram, precioBase: precio, consumoWatts: 5, stock: 10)
    }

    func testConfigurarPersistencia_primerArranque_siembraElCatalogo() throws {
        let contexto = try crearContexto()
        let sut = crearViewModel()

        sut.configurarPersistencia(contexto)

        let guardados = try contexto.fetch(FetchDescriptor<Componente>())
        XCTAssertEqual(guardados.count, QuoteBuilderViewModel.catalogoDisponible.count)
        XCTAssertEqual(sut.inventarioAlmacen.count, guardados.count)
    }

    func testRegistrarNuevoComponente_sePersisteYSobreviveAUnNuevoViewModel() throws {
        let contexto = try crearContexto()
        let primero = crearViewModel()
        primero.configurarPersistencia(contexto)
        primero.registrarNuevoComponenteEnAlmacen(componente("Componente Propio", precio: 99))

        let segundo = crearViewModel()
        segundo.configurarPersistencia(contexto)

        XCTAssertTrue(segundo.inventarioAlmacen.contains { $0.nombre == "Componente Propio" })
    }

    func testCantidad_incrementarYDecrementar_actualizaLineaYSubtotal() {
        let ram = componente("RAM", precio: 50)
        let sut = crearViewModel([ram])

        sut.incrementarCantidad(ram)
        XCTAssertEqual(sut.lineasSeleccionadas.first?.cantidad, 2)
        XCTAssertEqual(sut.subtotal, 100, accuracy: 0.0001)

        sut.decrementarCantidad(ram)
        sut.decrementarCantidad(ram)
        XCTAssertTrue(sut.lineasSeleccionadas.isEmpty)
        XCTAssertEqual(sut.subtotal, 0, accuracy: 0.0001)
    }

    func testGenerarCotizacion_guardaCantidadPorLinea() {
        let ram = componente("RAM", precio: 50)
        let cpu = componente("CPU", precio: 300)
        let sut = crearViewModel([ram, cpu, ram])

        let cotizacion = sut.generarCotizacion()

        XCTAssertEqual(cotizacion.componentes.count, 2)
        XCTAssertEqual(cotizacion.lineas.count, 2)
        XCTAssertEqual(cotizacion.lineas.first { $0.componente?.nombre == "RAM" }?.cantidad, 2)
        XCTAssertEqual(cotizacion.subtotal, 400, accuracy: 0.0001)
    }

    func testRecalcularTotales_conLineas_usaLaCantidad() {
        let ram = componente("RAM", precio: 50)
        let cotizacion = Cotizacion(
            cliente: "X",
            componentes: [ram],
            lineas: [LineaCotizacion(componente: ram, cantidad: 3)],
            margenGanancia: 0.1
        )

        cotizacion.recalcularTotales()

        XCTAssertEqual(cotizacion.subtotal, 150, accuracy: 0.0001)
        XCTAssertEqual(cotizacion.total, 165, accuracy: 0.0001)
    }
}

@MainActor
final class PrecisionDecimalTests: XCTestCase {

    func testSumaDeCentavos_conDecimal_esExacta() {
        // Con Double, 0.1 + 0.2 != 0.3. Con Decimal sí.
        let a = Decimal(string: "0.10")!
        let b = Decimal(string: "0.20")!
        XCTAssertEqual(a + b, Decimal(string: "0.30")!)
    }

    func testRedondeado_aCentavos() {
        XCTAssertEqual(Decimal(string: "262.44655")!.redondeado(), Decimal(string: "262.45")!)
        XCTAssertEqual(Decimal(string: "10.004")!.redondeado(), Decimal(string: "10.00")!)
    }

    func testTotalConMargen_conCentavos_esExactoSinError() {
        let componente = Componente(
            nombre: "X", categoria: .ram,
            precioBase: Decimal(string: "649.99")!, consumoWatts: 1, stock: 1
        )
        let cotizacion = Cotizacion(
            cliente: "C", componentes: [componente],
            margenGanancia: Decimal(string: "0.10")!
        )
        XCTAssertEqual(cotizacion.total, Decimal(string: "714.99")!)
    }
}

@MainActor
final class DetalleProductoTests: XCTestCase {

    func testComponente_guardaDescripcionFotoYFichaTecnica() {
        let componente = Componente(
            nombre: "GPU", categoria: .gpu, precioBase: 100, consumoWatts: 200, stock: 3,
            descripcion: "Tarjeta de prueba",
            fotoURL: "https://example.com/gpu.png",
            fichaTecnicaURL: "https://example.com/gpu.pdf"
        )

        XCTAssertEqual(componente.descripcion, "Tarjeta de prueba")
        XCTAssertEqual(componente.fotoURL, "https://example.com/gpu.png")
        XCTAssertEqual(componente.fichaTecnicaURL, "https://example.com/gpu.pdf")
    }

    func testComponente_sinDetalle_dejaLosCamposEnNil() {
        let componente = Componente(nombre: "RAM", categoria: .ram, precioBase: 10, consumoWatts: 5, stock: 1)

        XCTAssertNil(componente.descripcion)
        XCTAssertNil(componente.fotoURL)
        XCTAssertNil(componente.fichaTecnicaURL)
    }

    func testCatalogoSemilla_todosTienenDescripcion() {
        let sinDescripcion = QuoteBuilderViewModel.catalogoDisponible.filter { $0.descripcion == nil }
        XCTAssertTrue(sinDescripcion.isEmpty, "Sin descripción: \(sinDescripcion.map(\.nombre))")
    }
}
