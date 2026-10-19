//
//  Cotizacion.swift
//  HardwareQuoteB2B
//

import Foundation
import SwiftData

@Model
final class Cotizacion {
    @Attribute(.unique) var id: UUID
    var cliente: String
    var fecha: Date
    @Relationship var componentes: [Componente]
    /// Detalle con cantidad por componente. Si está vacío (cotizaciones antiguas) se usa `componentes`.
    @Relationship(deleteRule: .cascade) var lineas: [LineaCotizacion] = []
    var margenGanancia: Double
    var subtotal: Double
    var total: Double

    init(
        id: UUID = UUID(),
        cliente: String,
        fecha: Date = .now,
        componentes: [Componente] = [],
        lineas: [LineaCotizacion] = [],
        margenGanancia: Double = 0.0,
        subtotal: Double? = nil,
        total: Double? = nil
    ) {
        self.id = id
        self.cliente = cliente
        self.fecha = fecha
        self.componentes = componentes
        self.lineas = lineas
        self.margenGanancia = margenGanancia

        let subtotalCalculado = subtotal ?? Self.calcularSubtotal(lineas: lineas, componentes: componentes)
        self.subtotal = subtotalCalculado
        self.total = total ?? (subtotalCalculado * (1 + margenGanancia))
    }

    func recalcularTotales() {
        subtotal = Self.calcularSubtotal(lineas: lineas, componentes: componentes)
        total = subtotal * (1 + margenGanancia)
    }

    private static func calcularSubtotal(lineas: [LineaCotizacion], componentes: [Componente]) -> Double {
        if lineas.isEmpty {
            return componentes.reduce(0) { $0 + $1.precioBase }
        }
        return lineas.reduce(0) { $0 + $1.subtotal }
    }
}
