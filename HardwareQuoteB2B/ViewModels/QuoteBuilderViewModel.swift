//
//  QuoteBuilderViewModel.swift
//  HardwareQuoteB2B
//

import Foundation
import Observation
import SwiftData
import SwiftUI

@Observable
final class QuoteBuilderViewModel {
    // MARK: - State
    var clienteNombre: String
    var componentesSeleccionados: [Componente]
    var inventarioAlmacen: [Componente]
    var margenGanancia: Double // Ej: 0.18 = 18%
    var mostrarSelectorCatalogo: Bool = false

    // MARK: - Computed Metrics (Watts & Power)
    /// Consumo energético total de los componentes (excluyendo la capacidad nominal de la fuente)
    var consumoTotalWatts: Int {
        componentesSeleccionados
            .filter { $0.categoria != .fuente }
            .reduce(0) { $0 + $1.consumoWatts }
    }

    /// Capacidad nominal de la fuente seleccionada (si existe) o techo de referencia (850W)
    var capacidadFuenteWatts: Int {
        if let fuente = componentesSeleccionados.first(where: { $0.categoria == .fuente }),
           fuente.consumoWatts > 0 {
            return fuente.consumoWatts
        }
        return 850
    }

    /// Proporción de carga energética (0.0 a 1.0)
    var porcentajeCargaWatts: Double {
        guard capacidadFuenteWatts > 0 else { return 0 }
        return min(Double(consumoTotalWatts) / Double(capacidadFuenteWatts), 1.0)
    }

    /// Nivel de holgura energética para retroalimentación visual
    enum EstadoEnergia {
        case optimo
        case moderado
        case critico

        var etiqueta: String {
            switch self {
            case .optimo: return "Holgura Óptima"
            case .moderado: return "Carga Moderada"
            case .critico: return "Límite Energético"
            }
        }
    }

    var estadoEnergia: EstadoEnergia {
        switch porcentajeCargaWatts {
        case ..<0.65:
            return .optimo
        case 0.65..<0.85:
            return .moderado
        default:
            return .critico
        }
    }

    // MARK: - Computed Metrics (Pricing)
    var subtotal: Double {
        componentesSeleccionados.reduce(0) { $0 + $1.precioBase }
    }

    var utilidadComercial: Double {
        subtotal * margenGanancia
    }

    var precioFinal: Double {
        subtotal + utilidadComercial
    }

    // MARK: - Init
    init(
        clienteNombre: String = "Corporativo Enterprise S.A.",
        componentesSeleccionados: [Componente] = QuoteBuilderViewModel.componentesDemostracion,
        inventarioAlmacen: [Componente] = QuoteBuilderViewModel.catalogoDisponible,
        margenGanancia: Double = 0.18
    ) {
        self.clienteNombre = clienteNombre
        self.componentesSeleccionados = componentesSeleccionados
        self.inventarioAlmacen = inventarioAlmacen
        self.margenGanancia = margenGanancia
    }

    // MARK: - Actions
    func registrarNuevoComponenteEnAlmacen(_ componente: Componente) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            inventarioAlmacen.insert(componente, at: 0)
        }
    }

    func agregarComponente(_ componente: Componente) {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            componentesSeleccionados.append(componente)
        }
    }

    func eliminarComponente(_ componente: Componente) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            componentesSeleccionados.removeAll { $0.id == componente.id }
        }
    }

    func eliminarComponentes(en offsets: IndexSet) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            componentesSeleccionados.remove(atOffsets: offsets)
        }
    }

    func generarCotizacion() -> Cotizacion {
        Cotizacion(
            cliente: clienteNombre.isEmpty ? "Cliente Corporativo" : clienteNombre,
            fecha: .now,
            componentes: componentesSeleccionados,
            margenGanancia: margenGanancia,
            subtotal: subtotal,
            total: precioFinal
        )
    }
}

// MARK: - Catálogo de Referencia B2B
extension QuoteBuilderViewModel {
    static var componentesDemostracion: [Componente] {
        [
            Componente(
                nombre: "AMD Ryzen 9 9950X 16-Core",
                categoria: .cpu,
                precioBase: 649.00,
                socket: "AM5",
                consumoWatts: 170,
                stock: 14
            ),
            Componente(
                nombre: "ASUS ProArt X870E-Creator WiFi",
                categoria: .placa,
                precioBase: 479.00,
                socket: "AM5",
                consumoWatts: 55,
                stock: 9
            ),
            Componente(
                nombre: "NVIDIA RTX 4500 Ada Generation 24GB",
                categoria: .gpu,
                precioBase: 2250.00,
                socket: "PCIe 4.0 x16",
                consumoWatts: 210,
                stock: 6
            ),
            Componente(
                nombre: "Kingston Server Premier 64GB DDR5 ECC",
                categoria: .ram,
                precioBase: 289.00,
                socket: "DDR5",
                consumoWatts: 18,
                stock: 22
            ),
            Componente(
                nombre: "Seasonic PRIME TX-850 80+ Titanium",
                categoria: .fuente,
                precioBase: 279.00,
                socket: "ATX 3.1",
                consumoWatts: 850,
                stock: 11
            )
        ]
    }

    static var catalogoDisponible: [Componente] {
        componentesDemostracion + [
            Componente(
                nombre: "Intel Xeon w7-2495X 24-Core",
                categoria: .cpu,
                precioBase: 2189.00,
                socket: "LGA4677",
                consumoWatts: 225,
                stock: 4
            ),
            Componente(
                nombre: "NVIDIA RTX 6000 Ada Generation 48GB",
                categoria: .gpu,
                precioBase: 6800.00,
                socket: "PCIe 4.0 x16",
                consumoWatts: 300,
                stock: 3
            ),
            Componente(
                nombre: "Corsair WS DDR5 RDIMM 128GB (4x32GB)",
                categoria: .ram,
                precioBase: 640.00,
                socket: "DDR5",
                consumoWatts: 32,
                stock: 8
            ),
            Componente(
                nombre: "Seasonic PRIME PX-1300 80+ Platinum",
                categoria: .fuente,
                precioBase: 369.00,
                socket: "ATX 3.1",
                consumoWatts: 1300,
                stock: 7
            )
        ]
    }
}
