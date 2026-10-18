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
    var margenGanancia: Double
    var subtotal: Double
    var total: Double

    init(
        id: UUID = UUID(),
        cliente: String,
        fecha: Date = .now,
        componentes: [Componente] = [],
        margenGanancia: Double = 0.0,
        subtotal: Double? = nil,
        total: Double? = nil
    ) {
        self.id = id
        self.cliente = cliente
        self.fecha = fecha
        self.componentes = componentes
        self.margenGanancia = margenGanancia

        let subtotalCalculado = subtotal ?? componentes.reduce(0) { $0 + $1.precioBase }
        self.subtotal = subtotalCalculado
        self.total = total ?? (subtotalCalculado * (1 + margenGanancia))
    }

    func recalcularTotales() {
        subtotal = componentes.reduce(0) { $0 + $1.precioBase }
        total = subtotal * (1 + margenGanancia)
    }
}
