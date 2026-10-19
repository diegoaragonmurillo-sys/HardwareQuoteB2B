//
//  HardwareQuoteB2BTests.swift
//  HardwareQuoteB2BTests
//
//  Created by QA Specialist on 17/10/26.
//

import XCTest
@testable import HardwareQuoteB2B

/// Suite de Pruebas Unitarias de QA para validar el motor de cálculo de Cotizaciones B2B.
/// Cubre: Subtotal, Utilidad Comercial, Precio Final y Sincronización entre `QuoteBuilderViewModel` y `Cotizacion`.
final class HardwareQuoteB2BTests: XCTestCase {

    // MARK: - SUT & Test Fixtures
    private var sutViewModel: QuoteBuilderViewModel!
    private let precisionDelta: Decimal = 0

    // MARK: - Lifecycle
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Inicializamos con lista vacía y margen 0 para pruebas controladas
        sutViewModel = QuoteBuilderViewModel(
            clienteNombre: "Tech Corp Inc.",
            componentesSeleccionados: [],
            margenGanancia: 0.18
        )
    }

    override func tearDownWithError() throws {
        sutViewModel = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Factory
    private func crearComponente(
        nombre: String = "Componente Test",
        categoria: CategoriaComponente = .cpu,
        precioBase: Decimal,
        consumoWatts: Int = 100,
        stock: Int = 10
    ) -> Componente {
        Componente(
            nombre: nombre,
            categoria: categoria,
            precioBase: precioBase,
            consumoWatts: consumoWatts,
            stock: stock
        )
    }

    // MARK: - 1. Pruebas de Subtotal

    func testSubtotal_conListaVacia_debeSerCero() {
        // Arrange
        sutViewModel.componentesSeleccionados = []

        // Act
        let subtotal = sutViewModel.subtotal

        // Assert
        XCTAssertEqual(
            subtotal,
            0.0,
            accuracy: precisionDelta,
            "El subtotal para una cotización sin componentes debe ser estrictamente 0.0"
        )
    }

    func testSubtotal_conUnSoloComponente_esIgualAlPrecioBase() {
        // Arrange
        let cpu = crearComponente(precioBase: 599.99)
        sutViewModel.componentesSeleccionados = [cpu]

        // Act
        let subtotal = sutViewModel.subtotal

        // Assert
        XCTAssertEqual(
            subtotal,
            599.99,
            accuracy: precisionDelta,
            "El subtotal de un único componente debe ser idéntico a su precio base"
        )
    }

    func testSubtotal_conMultiplesComponentes_calculaSumaExacta() {
        // Arrange
        let cpu = crearComponente(nombre: "Ryzen 9", categoria: .cpu, precioBase: 649.00)
        let gpu = crearComponente(nombre: "RTX 4080", categoria: .gpu, precioBase: 1199.50)
        let ram = crearComponente(nombre: "DDR5 32GB", categoria: .ram, precioBase: 159.25)
        sutViewModel.componentesSeleccionados = [cpu, gpu, ram]

        let sumaEsperada = Decimal(string: "2007.75")!

        // Act
        let subtotalObtenido = sutViewModel.subtotal

        // Assert
        XCTAssertEqual(
            subtotalObtenido,
            sumaEsperada,
            accuracy: precisionDelta,
            "El subtotal debe corresponder a la sumatoria exacta de los precios base de los componentes"
        )
    }

    func testSubtotal_alAgregarYEliminarComponentes_seActualizaDinamicamente() {
        // Arrange
        let cpu = crearComponente(precioBase: 300.0)
        let placa = crearComponente(categoria: .placa, precioBase: 200.0)

        // Act & Assert 1: Agregar primer componente
        sutViewModel.agregarComponente(cpu)
        XCTAssertEqual(sutViewModel.subtotal, 300.0, accuracy: precisionDelta, "El subtotal debe actualizarse al agregar el primer componente")

        // Act & Assert 2: Agregar segundo componente
        sutViewModel.agregarComponente(placa)
        XCTAssertEqual(sutViewModel.subtotal, 500.0, accuracy: precisionDelta, "El subtotal acumulado debe reflejar ambos componentes")

        // Act & Assert 3: Eliminar un componente
        sutViewModel.eliminarComponente(cpu)
        XCTAssertEqual(sutViewModel.subtotal, 200.0, accuracy: precisionDelta, "El subtotal debe decrecer correctamente al eliminar un componente")
    }

    // MARK: - 2. Pruebas de Utilidad Comercial

    func testUtilidadComercial_conMargenCero_debeSerCero() {
        // Arrange
        let gpu = crearComponente(precioBase: 1000.00)
        sutViewModel.componentesSeleccionados = [gpu]
        sutViewModel.margenGanancia = 0.0

        // Act
        let utilidad = sutViewModel.utilidadComercial

        // Assert
        XCTAssertEqual(
            utilidad,
            0.0,
            accuracy: precisionDelta,
            "La utilidad comercial debe ser 0.0 cuando el margen de ganancia es del 0%"
        )
    }

    func testUtilidadComercial_conMargenEstandar_calculaPorcentajeCorrecto() {
        // Arrange
        let componente = crearComponente(precioBase: 2500.00)
        sutViewModel.componentesSeleccionados = [componente]
        sutViewModel.margenGanancia = 0.20 // 20%

        let utilidadEsperada: Decimal = 500.00

        // Act
        let utilidad = sutViewModel.utilidadComercial

        // Assert
        XCTAssertEqual(
            utilidad,
            utilidadEsperada,
            accuracy: precisionDelta,
            "La utilidad comercial debe ser igual al subtotal multiplicado por el margen de ganancia"
        )
    }

    func testUtilidadComercial_alCambiarMargenDinamicamente_recalculaEnTiempoReal() {
        // Arrange
        let fuente = crearComponente(categoria: .fuente, precioBase: 1000.00)
        sutViewModel.componentesSeleccionados = [fuente]

        // Act & Assert: Margen inicial 15%
        sutViewModel.margenGanancia = 0.15
        XCTAssertEqual(sutViewModel.utilidadComercial, 150.00, accuracy: precisionDelta)

        // Act & Assert: Modificación de margen al 30%
        sutViewModel.margenGanancia = 0.30
        XCTAssertEqual(sutViewModel.utilidadComercial, 300.00, accuracy: precisionDelta, "La utilidad comercial debe reaccionar al cambio del margen")
    }

    // MARK: - 3. Pruebas de Precio Final

    func testPrecioFinal_esLaSumaExactaDeSubtotalYUtilidadComercial() {
        // Arrange
        let cpu = crearComponente(precioBase: 750.00)
        let ram = crearComponente(precioBase: 250.00)
        sutViewModel.componentesSeleccionados = [cpu, ram] // Subtotal = 1000.00
        sutViewModel.margenGanancia = 0.18 // Utilidad = 180.00

        let subtotalEsperado: Decimal = 1000
        let utilidadEsperada: Decimal = 180
        let precioFinalEsperado = subtotalEsperado + utilidadEsperada // 1180.00

        // Act
        let precioFinalObtenido = sutViewModel.precioFinal

        // Assert
        XCTAssertEqual(
            precioFinalObtenido,
            precioFinalEsperado,
            accuracy: precisionDelta,
            "El precio final debe ser exactamente la suma del subtotal y la utilidad comercial"
        )
    }

    func testPrecioFinal_conMargenCero_esIgualAlSubtotal() {
        // Arrange
        let gpu = crearComponente(precioBase: 1500.00)
        sutViewModel.componentesSeleccionados = [gpu]
        sutViewModel.margenGanancia = 0.0

        // Act
        let precioFinal = sutViewModel.precioFinal

        // Assert
        XCTAssertEqual(
            precioFinal,
            sutViewModel.subtotal,
            accuracy: precisionDelta,
            "Cuando el margen de ganancia es 0%, el precio final debe ser idéntico al subtotal"
        )
    }

    func testPrecioFinal_conValoresDecimalesB2B_mantienePrecision() {
        // Arrange: Simulación de componentes reales con centavos
        let item1 = crearComponente(precioBase: 649.99)
        let item2 = crearComponente(precioBase: 479.49)
        let item3 = crearComponente(precioBase: 289.15)
        sutViewModel.componentesSeleccionados = [item1, item2, item3]
        sutViewModel.margenGanancia = Decimal(string: "0.185")! // 18.5%

        let subtotalCalculado = Decimal(string: "1418.63")!
        let utilidadCalculada = Decimal(string: "262.45")! // 262.44655 redondeado a centavos
        let totalEsperado = Decimal(string: "1681.08")!

        // Act
        let subtotalActual = sutViewModel.subtotal
        let utilidadActual = sutViewModel.utilidadComercial
        let precioFinalActual = sutViewModel.precioFinal

        // Assert
        XCTAssertEqual(subtotalActual, subtotalCalculado, accuracy: precisionDelta, "El subtotal con centavos debe mantener precisión")
        XCTAssertEqual(utilidadActual, utilidadCalculada, accuracy: precisionDelta, "La utilidad con margen fraccionario debe ser precisa")
        XCTAssertEqual(precioFinalActual, totalEsperado, accuracy: precisionDelta, "El precio final debe mantener la precisión decimal esperada")
    }

    // MARK: - 4. Pruebas de Integración con el Modelo `Cotizacion`

    func testGenerarCotizacion_transfiereValoresConsistentesAlModelo() {
        // Arrange
        let cpu = crearComponente(precioBase: 800.00)
        let fuente = crearComponente(categoria: .fuente, precioBase: 200.00)
        sutViewModel.clienteNombre = "Acme Corp Logistics"
        sutViewModel.componentesSeleccionados = [cpu, fuente]
        sutViewModel.margenGanancia = 0.25 // 25%

        let subtotalEsperado: Decimal = 1000
        let totalEsperado: Decimal = 1250 // 1000 + (1000 * 0.25)

        // Act
        let cotizacionGenerada = sutViewModel.generarCotizacion()

        // Assert
        XCTAssertEqual(cotizacionGenerada.cliente, "Acme Corp Logistics", "El cliente debe transferirse fielmente a la entidad Cotizacion")
        XCTAssertEqual(cotizacionGenerada.margenGanancia, 0.25, accuracy: precisionDelta, "El margen de ganancia debe persistir con exactitud")
        XCTAssertEqual(cotizacionGenerada.subtotal, subtotalEsperado, accuracy: precisionDelta, "El subtotal en Cotizacion debe coincidir con el ViewModel")
        XCTAssertEqual(cotizacionGenerada.total, totalEsperado, accuracy: precisionDelta, "El total en Cotizacion debe coincidir con el precio final del ViewModel")
        XCTAssertEqual(cotizacionGenerada.componentes.count, 2, "La lista de componentes debe coincidir")
    }

    func testCotizacionModelo_recalcularTotales_actualizaSubtotalYTotalCorrectamente() {
        // Arrange
        let ram1 = crearComponente(precioBase: 150.00)
        let ram2 = crearComponente(precioBase: 150.00)
        let cotizacion = Cotizacion(
            cliente: "Studio Render SL",
            componentes: [ram1],
            margenGanancia: 0.10
        )

        XCTAssertEqual(cotizacion.subtotal, 150.00, accuracy: precisionDelta)
        XCTAssertEqual(cotizacion.total, 165.00, accuracy: precisionDelta)

        // Act: Agregar otro componente directamente y modificar el margen
        cotizacion.componentes.append(ram2)
        cotizacion.margenGanancia = 0.20 // 20%
        cotizacion.recalcularTotales()

        let nuevoSubtotalEsperado: Decimal = 300
        let nuevoTotalEsperado: Decimal = 360

        // Assert
        XCTAssertEqual(cotizacion.subtotal, nuevoSubtotalEsperado, accuracy: precisionDelta, "El método recalcularTotales() debe actualizar el subtotal")
        XCTAssertEqual(cotizacion.total, nuevoTotalEsperado, accuracy: precisionDelta, "El método recalcularTotales() debe actualizar el total acorde al nuevo margen")
    }

    func testCotizacionModelo_conValoresPorDefecto_iniciaConsistente() {
        // Arrange & Act
        let cotizacionVacia = Cotizacion(cliente: "Cliente Sin Pedidos")

        // Assert
        XCTAssertEqual(cotizacionVacia.subtotal, 0.0, accuracy: precisionDelta, "Una cotización nueva sin componentes debe inicializar subtotal en 0")
        XCTAssertEqual(cotizacionVacia.total, 0.0, accuracy: precisionDelta, "Una cotización nueva sin componentes debe inicializar total en 0")
        XCTAssertEqual(cotizacionVacia.margenGanancia, 0.0, accuracy: precisionDelta, "El margen por defecto debe ser 0.0")
    }
}
