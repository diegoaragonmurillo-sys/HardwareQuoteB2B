import XCTest
import PDFKit
@testable import HardwareQuoteB2B

@MainActor
final class QuotePDFManagerTests: XCTestCase {

    private struct ServicioSinRed: TipoCambioServicing {
        func obtenerTasas() async throws -> TasasCambioUSD {
            TasasCambioUSD(mxn: 1, pen: 1, fechaActualizacion: Date())
        }
    }

    func testPDF_incluyeTablaConDescripcionYPrecios() throws {
        let lineas = [
            LineaCotizacionPDF(cantidad: 2, descripcion: "Kingston Fury 32GB DDR5", precioUnitario: 120),
            LineaCotizacionPDF(cantidad: 1, descripcion: "AMD Ryzen 9 9950X", precioUnitario: 650)
        ]

        let datos = try QuotePDFManager().generarDatosPDF(
            cliente: "Cliente Test", subtotal: 890, margen: 0.1,
            totalFinal: 979, lineas: lineas, idCotizacion: "ABC12345"
        )

        let texto = PDFDocument(data: datos)?.string ?? ""
        XCTAssertTrue(texto.contains("Kingston Fury 32GB DDR5"))
        XCTAssertTrue(texto.contains("AMD Ryzen 9 9950X"))
        XCTAssertTrue(texto.contains("CANT."))
        XCTAssertTrue(texto.contains("$240.00"), "Total de la línea 2 × 120")
    }

    func testPDF_conMuchasLineas_agregaPaginas() throws {
        let lineas = (1...80).map {
            LineaCotizacionPDF(cantidad: 1, descripcion: "Componente \($0)", precioUnitario: 10)
        }

        let datos = try QuotePDFManager().generarDatosPDF(
            cliente: "Cliente", subtotal: 800, margen: 0, totalFinal: 800,
            lineas: lineas, idCotizacion: "PAG"
        )

        XCTAssertGreaterThan(PDFDocument(data: datos)?.pageCount ?? 0, 1)
    }

    func testGuardar_escribeEnCarpetaCotizaciones() throws {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: base) }

        let url = try QuotePDFManager().guardarPDFEnMemoriaLocal(
            datosPDF: Data([0x25, 0x50, 0x44, 0x46]),
            nombreArchivo: "cotizacion_x.pdf",
            directorioBase: base
        )

        XCTAssertEqual(url.deletingLastPathComponent().lastPathComponent, "Cotizaciones")
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
    }

    func testLineasParaPDF_agrupaComponentesRepetidos() {
        let ram = Componente(nombre: "RAM 16GB", categoria: .ram, precioBase: 50,
                             socket: nil, consumoWatts: 5, stock: 10)
        let cpu = Componente(nombre: "CPU", categoria: .cpu, precioBase: 300,
                             socket: "AM5", consumoWatts: 100, stock: 3)
        let sut = QuoteBuilderViewModel(
            componentesSeleccionados: [ram, cpu, ram],
            margenGanancia: 0,
            servicioTipoCambio: ServicioSinRed()
        )

        let lineas = sut.lineasParaPDF

        XCTAssertEqual(lineas.count, 2)
        XCTAssertEqual(lineas[0], LineaCotizacionPDF(cantidad: 2, descripcion: "RAM 16GB", precioUnitario: 50))
        XCTAssertEqual(lineas[0].total, 100, accuracy: 0.0001)
    }
}
