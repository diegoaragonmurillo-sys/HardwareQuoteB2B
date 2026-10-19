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
    var margenGanancia: Decimal
    var subtotal: Decimal
    var total: Decimal

    init(
        id: UUID = UUID(),
        cliente: String,
        fecha: Date = .now,
        componentes: [Componente] = [],
        lineas: [LineaCotizacion] = [],
        margenGanancia: Decimal = 0,
        subtotal: Decimal? = nil,
        total: Decimal? = nil
    ) {
        self.id = id
        self.cliente = cliente
        self.fecha = fecha
        self.componentes = componentes
        self.lineas = lineas
        self.margenGanancia = margenGanancia

        let subtotalCalculado = subtotal ?? Self.calcularSubtotal(lineas: lineas, componentes: componentes)
        self.subtotal = subtotalCalculado
        self.total = total ?? (subtotalCalculado * (1 + margenGanancia)).redondeado()
    }

    func recalcularTotales() {
        subtotal = Self.calcularSubtotal(lineas: lineas, componentes: componentes)
        total = (subtotal * (1 + margenGanancia)).redondeado()
    }

    private static func calcularSubtotal(lineas: [LineaCotizacion], componentes: [Componente]) -> Decimal {
        if lineas.isEmpty {
            return componentes.reduce(0) { $0 + $1.precioBase }
        }
        return lineas.reduce(0) { $0 + $1.subtotal }
    }
}
