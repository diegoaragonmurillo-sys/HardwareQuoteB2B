//
//  LineaCotizacion.swift
//  HardwareQuoteB2B
//

import Foundation
import SwiftData

/// Línea de una cotización: un componente y cuántas unidades se cotizan.
@Model
final class LineaCotizacion {
    @Attribute(.unique) var id: UUID
    var componente: Componente?
    var cantidad: Int

    @Relationship(inverse: \Cotizacion.lineas)
    var cotizacion: Cotizacion?

    init(id: UUID = UUID(), componente: Componente, cantidad: Int) {
        self.id = id
        self.componente = componente
        self.cantidad = cantidad
    }

    var subtotal: Double {
        Double(cantidad) * (componente?.precioBase ?? 0)
    }
}
