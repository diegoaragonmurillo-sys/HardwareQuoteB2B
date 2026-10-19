//
//  QuotePDFManager.swift
//  HardwareQuoteB2B
//
//  Created as part of the B2B Hardware Quoting Platform.
//  Specialist: iOS Local Storage & Document Rendering Engine.
//

import UIKit
import PDFKit
import SwiftUI

// MARK: - Errores de Renderizado y Almacenamiento Local

public enum QuotePDFError: LocalizedError, Sendable {
    case directorioNoEncontrado
    case errorRenderizadoPDF
    case errorEscrituraDisco(String)

    public var errorDescription: String? {
        switch self {
        case .directorioNoEncontrado:
            return "No se pudo acceder al directorio local de Documentos en el dispositivo."
        case .errorRenderizadoPDF:
            return "Ocurrió un error al dibujar el documento con UIGraphicsPDFRenderer."
        case .errorEscrituraDisco(let detalle):
            return "Fallo al guardar el PDF en el almacenamiento local: \(detalle)"
        }
    }
}

// MARK: - Clase Principal QuotePDFManager (Almacenamiento Local)

/// Gestor independiente para la generación vectorial de cotizaciones en PDF y su persistencia estricta
/// en el directorio local de Documentos del dispositivo, permitiendo su uso offline y exportación nativa.
public final class QuotePDFManager: @unchecked Sendable {

    public static let shared = QuotePDFManager()

    // Paleta corporativa B2B
    private let primaryBrandColor = UIColor(red: 0.20, green: 0.34, blue: 0.55, alpha: 1.0)
    private let textDarkColor = UIColor(red: 0.12, green: 0.14, blue: 0.17, alpha: 1.0)
    private let textMutedColor = UIColor(red: 0.45, green: 0.50, blue: 0.55, alpha: 1.0)
    private let boxBgColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0)
    private let borderColor = UIColor(red: 0.85, green: 0.88, blue: 0.92, alpha: 1.0)

    public init() {}

    // MARK: - 1. API Principal con Concurrencia Moderna (async/await)

    /// Genera el documento PDF y lo guarda en el directorio local de Documentos del dispositivo.
    /// - Parameters:
    ///   - cliente: Nombre o razón social del cliente corporativo.
    ///   - subtotal: Monto base de componentes de hardware.
    ///   - margen: Porcentaje de margen comercial (ej: 0.18 para 18%).
    ///   - totalFinal: Monto total con margen e impuestos aplicados.
    ///   - idCotizacion: Identificador opcional para el nombre del archivo (genera UUID por defecto).
    /// - Returns: URL local del archivo recién creado en la memoria interna del dispositivo.
    public func generarYGuardarPDFLocal(
        cliente: String,
        subtotal: Double,
        margen: Double,
        totalFinal: Double,
        idCotizacion: String = UUID().uuidString
    ) async throws -> URL {
        // 1. Dibujar el archivo PDF mediante UIGraphicsPDFRenderer
        let datosPDF = try generarDatosPDF(
            cliente: cliente,
            subtotal: subtotal,
            margen: margen,
            totalFinal: totalFinal,
            idCotizacion: idCotizacion
        )

        // 2. Guardar estrictamente en el directorio local de Documentos (FileManager)
        let nombreArchivo = "cotizacion_\(idCotizacion).pdf"
        let urlLocal = try guardarPDFEnMemoriaLocal(datosPDF: datosPDF, nombreArchivo: nombreArchivo)

        return urlLocal
    }

    // MARK: - 2. Renderizado Gráfico del PDF (UIGraphicsPDFRenderer)

    /// Dibuja los gráficos vectoriales y textos de la cotización usando `UIGraphicsPDFRenderer`.
    public func generarDatosPDF(
        cliente: String,
        subtotal: Double,
        margen: Double,
        totalFinal: Double,
        idCotizacion: String
    ) throws -> Data {
        // Tamaño Carta estándar: 8.5 x 11 pulgadas a 72 ppp (612 x 792 pt)
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let rendererFormat = UIGraphicsPDFRendererFormat()
        rendererFormat.documentInfo = [
            kCGPDFContextTitle as String: "Cotización B2B",
            kCGPDFContextAuthor as String: "HardwareQuote B2B System",
            kCGPDFContextCreator as String: "QuotePDFManager iOS"
        ]

        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: rendererFormat)

        let datos = renderer.pdfData { context in
            context.beginPage()

            let margenIzquierdo: CGFloat = 40
            let anchoContenido: CGFloat = pageRect.width - (margenIzquierdo * 2)
            var posY: CGFloat = 40

            // --- Encabezado Corporativo ---
            let titulo = "Cotización B2B"
            let atributosTitulo: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 26, weight: .bold),
                .foregroundColor: primaryBrandColor
            ]
            titulo.draw(at: CGPoint(x: margenIzquierdo, y: posY), withAttributes: atributosTitulo)

            let subtitulo = "PROPUESTA TÉCNICA Y COMERCIAL DE HARDWARE"
            let atributosSubtitulo: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .semibold),
                .foregroundColor: textMutedColor
            ]
            subtitulo.draw(at: CGPoint(x: margenIzquierdo, y: posY + 32), withAttributes: atributosSubtitulo)

            // Folio y Fecha alineados a la derecha
            let formateadorFecha = DateFormatter()
            formateadorFecha.dateStyle = .medium
            formateadorFecha.timeStyle = .short
            let fechaTexto = "Fecha: \(formateadorFecha.string(from: Date()))"
            let folioTexto = "Folio: #\(idCotizacion.prefix(8).uppercased())"

            let atributosMeta: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                .foregroundColor: textDarkColor
            ]
            let folioSize = folioTexto.size(withAttributes: atributosMeta)
            folioTexto.draw(at: CGPoint(x: pageRect.width - margenIzquierdo - folioSize.width, y: posY + 4), withAttributes: atributosMeta)
            let fechaSize = fechaTexto.size(withAttributes: atributosMeta)
            fechaTexto.draw(at: CGPoint(x: pageRect.width - margenIzquierdo - fechaSize.width, y: posY + 20), withAttributes: atributosMeta)

            posY += 55

            // Línea divisoria decorativa
            let lineaPath = UIBezierPath()
            lineaPath.move(to: CGPoint(x: margenIzquierdo, y: posY))
            lineaPath.addLine(to: CGPoint(x: pageRect.width - margenIzquierdo, y: posY))
            lineaPath.lineWidth = 1.5
            primaryBrandColor.setStroke()
            lineaPath.stroke()

            posY += 20

            // --- Tarjeta de Información del Cliente ---
            let cajaClienteRect = CGRect(x: margenIzquierdo, y: posY, width: anchoContenido, height: 65)
            let cajaClientePath = UIBezierPath(roundedRect: cajaClienteRect, cornerRadius: 8)
            boxBgColor.setFill()
            cajaClientePath.fill()
            borderColor.setStroke()
            cajaClientePath.lineWidth = 1
            cajaClientePath.stroke()

            let labelClienteHeader = "CUENTA / CLIENTE CORPORATIVO"
            labelClienteHeader.draw(at: CGPoint(x: margenIzquierdo + 14, y: posY + 12), withAttributes: [
                .font: UIFont.systemFont(ofSize: 9, weight: .bold),
                .foregroundColor: textMutedColor
            ])

            let nombreClienteFinal = cliente.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Cliente General" : cliente
            nombreClienteFinal.draw(at: CGPoint(x: margenIzquierdo + 14, y: posY + 28), withAttributes: [
                .font: UIFont.systemFont(ofSize: 15, weight: .semibold),
                .foregroundColor: textDarkColor
            ])

            posY += 90

            // --- Sección de Resumen y Desglose Financiero ---
            let tituloDesglose = "DESGLOSE DE VALORES"
            tituloDesglose.draw(at: CGPoint(x: margenIzquierdo, y: posY), withAttributes: [
                .font: UIFont.systemFont(ofSize: 12, weight: .bold),
                .foregroundColor: primaryBrandColor
            ])

            posY += 22

            let formateadorMoneda = NumberFormatter()
            formateadorMoneda.numberStyle = .currency
            formateadorMoneda.currencyCode = "USD"

            let strSubtotal = formateadorMoneda.string(from: NSNumber(value: subtotal)) ?? "$\(subtotal)"
            let strMargen = "+\(Int((margen * 100).rounded()))%"
            let utilidadCalculada = subtotal * margen
            let strUtilidad = formateadorMoneda.string(from: NSNumber(value: utilidadCalculada)) ?? "$\(utilidadCalculada)"
            let strTotal = formateadorMoneda.string(from: NSNumber(value: totalFinal)) ?? "$\(totalFinal)"

            let filas: [(etiqueta: String, valor: String)] = [
                ("Subtotal de Componentes Base", strSubtotal),
                ("Margen Comercial Aplicado (\(strMargen))", strUtilidad),
                ("Soporte y Garantía de Ensamble B2B", "Incluido")
            ]

            for fila in filas {
                fila.etiqueta.draw(at: CGPoint(x: margenIzquierdo + 8, y: posY), withAttributes: [
                    .font: UIFont.systemFont(ofSize: 11, weight: .regular),
                    .foregroundColor: textDarkColor
                ])

                let atributosVal: [NSAttributedString.Key: Any] = [
                    .font: UIFont.monospacedDigitSystemFont(ofSize: 11, weight: .medium),
                    .foregroundColor: textDarkColor
                ]
                let valSize = fila.valor.size(withAttributes: atributosVal)
                fila.valor.draw(at: CGPoint(x: pageRect.width - margenIzquierdo - 8 - valSize.width, y: posY), withAttributes: atributosVal)

                posY += 18

                let subLinea = UIBezierPath()
                subLinea.move(to: CGPoint(x: margenIzquierdo + 8, y: posY))
                subLinea.addLine(to: CGPoint(x: pageRect.width - margenIzquierdo - 8, y: posY))
                subLinea.lineWidth = 0.5
                borderColor.setStroke()
                subLinea.stroke()

                posY += 10
            }

            posY += 15

            // --- Tarjeta de Total Final ---
            let rectTotal = CGRect(x: margenIzquierdo, y: posY, width: anchoContenido, height: 60)
            let pathTotal = UIBezierPath(roundedRect: rectTotal, cornerRadius: 10)
            primaryBrandColor.setFill()
            pathTotal.fill()

            "TOTAL FINAL DE LA PROPUESTA (USD)".draw(at: CGPoint(x: margenIzquierdo + 16, y: posY + 22), withAttributes: [
                .font: UIFont.systemFont(ofSize: 11, weight: .bold),
                .foregroundColor: UIColor.white.withAlphaComponent(0.85)
            ])

            let atributosTotalVal: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .heavy),
                .foregroundColor: UIColor.white
            ]
            let totalValSize = strTotal.size(withAttributes: atributosTotalVal)
            strTotal.draw(at: CGPoint(x: pageRect.width - margenIzquierdo - 16 - totalValSize.width, y: posY + 18), withAttributes: atributosTotalVal)

            posY += 90

            // --- Términos y Condiciones ---
            let terminosTexto = """
            Términos y Condiciones:
            1. Esta cotización tiene una vigencia legal de 15 días calendario a partir de su emisión.
            2. La disponibilidad de componentes y los tiempos de ensamblaje están sujetos a stock al momento de la orden.
            3. Todos los equipos ensamblados cuentan con pruebas de estrés y certificación de estabilidad térmica.
            """
            let terminosRect = CGRect(x: margenIzquierdo, y: posY, width: anchoContenido, height: 120)
            let atributosTerminos: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9, weight: .regular),
                .foregroundColor: textMutedColor
            ]
            terminosTexto.draw(in: terminosRect, withAttributes: atributosTerminos)

            // --- Pie de página ---
            let piePagina = "HardwareQuote B2B • Documento Oficial Generado Digitalmente"
            let atributosPie: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 8, weight: .regular),
                .foregroundColor: textMutedColor
            ]
            let pieSize = piePagina.size(withAttributes: atributosPie)
            piePagina.draw(at: CGPoint(x: (pageRect.width - pieSize.width) / 2, y: pageRect.height - 35), withAttributes: atributosPie)
        }

        guard !datos.isEmpty else {
            throw QuotePDFError.errorRenderizadoPDF
        }

        return datos
    }

    // MARK: - 3. Almacenamiento Temporal para Exportación (FileManager)

    /// Guarda el PDF en el directorio temporal (`temporaryDirectory`) para su exportación y uso en ShareSheet,
    /// evitando saturar permanentemente el almacenamiento de documentos del dispositivo.
    public func guardarPDFEnMemoriaLocal(datosPDF: Data, nombreArchivo: String) throws -> URL {
        let directorioTemporal = FileManager.default.temporaryDirectory
        let urlDestinoLocal = directorioTemporal.appendingPathComponent(nombreArchivo)

        do {
            try datosPDF.write(to: urlDestinoLocal, options: .atomic)
            return urlDestinoLocal
        } catch {
            throw QuotePDFError.errorEscrituraDisco(error.localizedDescription)
        }
    }
}

// MARK: - 4. Componente SwiftUI: Botón con ShareLink Nativo de iOS

/// Botón interactivo para SwiftUI que genera el PDF localmente bajo demanda y activa
/// el ShareLink nativo de iOS para compartir por WhatsApp, Correo o guardar en Archivos.
public struct ShareQuotePDFButton: View {
    public let cliente: String
    public let subtotal: Double
    public let margen: Double
    public let totalFinal: Double
    public var idCotizacion: String = UUID().uuidString

    @State private var pdfURL: URL?
    @State private var estaGenerando: Bool = false
    @State private var mensajeError: String?

    // Estilo corporativo B2B
    private let brandAccent = Color(red: 0.20, green: 0.34, blue: 0.55)

    public init(
        cliente: String,
        subtotal: Double,
        margen: Double,
        totalFinal: Double,
        idCotizacion: String = UUID().uuidString
    ) {
        self.cliente = cliente
        self.subtotal = subtotal
        self.margen = margen
        self.totalFinal = totalFinal
        self.idCotizacion = idCotizacion
    }

    public var body: some View {
        Group {
            if let url = pdfURL {
                // ShareLink nativo de iOS (WhatsApp, Correo, AirDrop, Guardar en Archivos)
                ShareLink(
                    item: url,
                    preview: SharePreview(
                        "Cotización B2B - \(cliente)",
                        image: Image(systemName: "doc.richtext.fill")
                    )
                ) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Compartir Cotización PDF")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(brandAccent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            } else {
                // Botón generador del PDF local
                Button {
                    generarPDF()
                } label: {
                    HStack(spacing: 8) {
                        if estaGenerando {
                            ProgressView()
                                .tint(.white)
                            Text("Generando documento local...")
                                .fontWeight(.semibold)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Exportar y Compartir PDF")
                                .fontWeight(.semibold)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(brandAccent, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(estaGenerando)
            }
        }
        .alert("Error al Exportar PDF", isPresented: Binding(
            get: { mensajeError != nil },
            set: { if !$0 { mensajeError = nil } }
        )) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(mensajeError ?? "No se pudo procesar el archivo.")
        }
    }

    private func generarPDF() {
        estaGenerando = true
        Task {
            do {
                let url = try await QuotePDFManager.shared.generarYGuardarPDFLocal(
                    cliente: cliente,
                    subtotal: subtotal,
                    margen: margen,
                    totalFinal: totalFinal,
                    idCotizacion: idCotizacion
                )
                await MainActor.run {
                    self.pdfURL = url
                    self.estaGenerando = false
                }
            } catch {
                await MainActor.run {
                    self.mensajeError = error.localizedDescription
                    self.estaGenerando = false
                }
            }
        }
    }
}
