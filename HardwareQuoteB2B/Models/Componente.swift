//
//  Componente.swift
//  HardwareQuoteB2B
//

import Foundation
import SwiftData

enum CategoriaComponente: String, Codable, CaseIterable, Identifiable {
    case cpu = "CPU"
    case gpu = "GPU"
    case ram = "RAM"
    case placa = "Placa"
    case fuente = "Fuente"

    var id: String { rawValue }
}

@Model
final class Componente {
    @Attribute(.unique) var id: UUID
    var nombre: String
    var categoria: CategoriaComponente
    var precioBase: Decimal
    var socket: String?
    var consumoWatts: Int
    var stock: Int
    var descripcion: String?
    var fotoURL: String?
    var fichaTecnicaURL: String?

    @Relationship(inverse: \Cotizacion.componentes)
    var cotizaciones: [Cotizacion] = []

    init(
        id: UUID = UUID(),
        nombre: String,
        categoria: CategoriaComponente,
        precioBase: Decimal,
        socket: String? = nil,
        consumoWatts: Int,
        stock: Int,
        descripcion: String? = nil,
        fotoURL: String? = nil,
        fichaTecnicaURL: String? = nil
    ) {
        self.id = id
        self.nombre = nombre
        self.categoria = categoria
        self.precioBase = precioBase
        self.socket = socket
        self.consumoWatts = consumoWatts
        self.stock = stock
        self.descripcion = descripcion
        self.fotoURL = fotoURL
        self.fichaTecnicaURL = fichaTecnicaURL
    }
}
