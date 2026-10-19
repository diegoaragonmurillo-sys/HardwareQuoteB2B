//
//  ValidadorCompatibilidad.swift
//  HardwareQuoteB2B
//
//  Reglas de compatibilidad de una cotización: socket CPU/placa y consumo vs. fuente.
//

import Foundation

struct ProblemaCompatibilidad: Identifiable, Equatable {
    enum Severidad: Equatable {
        case advertencia
        case error
    }

    let severidad: Severidad
    let mensaje: String

    var id: String { "\(severidad)-\(mensaje)" }
}

enum ValidadorCompatibilidad {
    /// Porcentaje de carga de la fuente a partir del cual se advierte (holgura insuficiente).
    static let umbralAdvertenciaPorcentaje = 80

    static func validar(_ componentes: [Componente]) -> [ProblemaCompatibilidad] {
        validarSockets(componentes) + validarEnergia(componentes)
    }

    // MARK: - Socket CPU ↔ Placa

    private static func validarSockets(_ componentes: [Componente]) -> [ProblemaCompatibilidad] {
        let cpus = distintos(componentes.filter { $0.categoria == .cpu })
        let placas = distintos(componentes.filter { $0.categoria == .placa })
        var problemas: [ProblemaCompatibilidad] = []

        for cpu in cpus {
            for placa in placas {
                guard let socketCPU = normalizado(cpu.socket),
                      let socketPlaca = normalizado(placa.socket),
                      socketCPU != socketPlaca else { continue }

                problemas.append(ProblemaCompatibilidad(
                    severidad: .error,
                    mensaje: "Socket incompatible: \(cpu.nombre) usa \(cpu.socket ?? "")"
                        + " y \(placa.nombre) usa \(placa.socket ?? "")."
                ))
            }
        }
        return problemas
    }

    // MARK: - Consumo vs. Fuente

    private static func validarEnergia(_ componentes: [Componente]) -> [ProblemaCompatibilidad] {
        let consumo = componentes
            .filter { $0.categoria != .fuente }
            .reduce(0) { $0 + $1.consumoWatts }

        guard consumo > 0 else { return [] }

        guard let fuente = componentes.first(where: { $0.categoria == .fuente }), fuente.consumoWatts > 0 else {
            return [ProblemaCompatibilidad(
                severidad: .advertencia,
                mensaje: "Falta una fuente de poder: los componentes demandan \(consumo) W."
            )]
        }

        let capacidad = fuente.consumoWatts

        if consumo > capacidad {
            return [ProblemaCompatibilidad(
                severidad: .error,
                mensaje: "Sobrecarga: la demanda de \(consumo) W supera los \(capacidad) W de \(fuente.nombre)."
            )]
        }

        if consumo * 100 >= capacidad * umbralAdvertenciaPorcentaje {
            return [ProblemaCompatibilidad(
                severidad: .advertencia,
                mensaje: "Poca holgura: \(consumo) W de \(capacidad) W (más del \(umbralAdvertenciaPorcentaje)% de la fuente)."
            )]
        }

        return []
    }

    // MARK: - Utilidades

    private static func distintos(_ componentes: [Componente]) -> [Componente] {
        var vistos = Set<UUID>()
        return componentes.filter { vistos.insert($0.id).inserted }
    }

    private static func normalizado(_ socket: String?) -> String? {
        guard let limpio = socket?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
              !limpio.isEmpty else { return nil }
        return limpio
    }
}
