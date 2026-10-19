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
    var margenGanancia: Decimal // Ej: 0.18 = 18%
    var mostrarSelectorCatalogo: Bool = false

    // MARK: - Estado REST API (Tipo de Cambio B2B)
    var tasaCambioUSD_MXN: Decimal = 1
    var tasaCambioUSD_PEN: Decimal = 1
    var errorTipoCambio: Bool = false
    private let servicioTipoCambio: TipoCambioServicing
    private var contextoSwiftData: ModelContext?
    var estaCargandoTasa: Bool = false

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

    // MARK: - Compatibilidad
    var problemasCompatibilidad: [ProblemaCompatibilidad] {
        ValidadorCompatibilidad.validar(componentesSeleccionados)
    }

    var hayErroresCompatibilidad: Bool {
        problemasCompatibilidad.contains { $0.severidad == .error }
    }

    // MARK: - Computed Metrics (Pricing)
    var subtotal: Decimal {
        componentesSeleccionados.reduce(Decimal(0)) { $0 + $1.precioBase }
    }

    var utilidadComercial: Decimal {
        (subtotal * margenGanancia).redondeado()
    }

    var precioFinal: Decimal {
        subtotal + utilidadComercial
    }

    var precioFinalMXN: Decimal {
        (precioFinal * tasaCambioUSD_MXN).redondeado()
    }

    /// Línea de la cotización: un componente con su cantidad.
    struct LineaSeleccion: Identifiable {
        let componente: Componente
        let cantidad: Int
        var id: UUID { componente.id }
    }

    /// Componentes seleccionados agrupados por producto, en orden de inserción.
    var lineasSeleccionadas: [LineaSeleccion] {
        var orden: [UUID] = []
        var conteo: [UUID: (componente: Componente, cantidad: Int)] = [:]
        for componente in componentesSeleccionados {
            if let existente = conteo[componente.id] {
                conteo[componente.id] = (existente.componente, existente.cantidad + 1)
            } else {
                orden.append(componente.id)
                conteo[componente.id] = (componente, 1)
            }
        }
        return orden.compactMap { id in
            conteo[id].map { LineaSeleccion(componente: $0.componente, cantidad: $0.cantidad) }
        }
    }

    /// Líneas para la tabla del PDF (cantidad × precio unitario).
    var lineasParaPDF: [LineaCotizacionPDF] {
        lineasSeleccionadas.map {
            LineaCotizacionPDF(
                cantidad: $0.cantidad,
                descripcion: $0.componente.nombre,
                precioUnitario: $0.componente.precioBase
            )
        }
    }

    var precioFinalPEN: Decimal {
        (precioFinal * tasaCambioUSD_PEN).redondeado()
    }

    // MARK: - Init
    init(
        clienteNombre: String = "Corporativo Enterprise S.A.",
        componentesSeleccionados: [Componente] = QuoteBuilderViewModel.componentesDemostracion,
        inventarioAlmacen: [Componente] = QuoteBuilderViewModel.catalogoDisponible,
        margenGanancia: Decimal = Decimal(string: "0.18")!,
        servicioTipoCambio: TipoCambioServicing = TipoCambioService()
    ) {
        self.servicioTipoCambio = servicioTipoCambio
        self.clienteNombre = clienteNombre
        self.componentesSeleccionados = componentesSeleccionados
        self.inventarioAlmacen = inventarioAlmacen
        self.margenGanancia = margenGanancia
        consultarTipoCambio()
    }

    // MARK: - Consulta REST API con URLSession (async/await)
    func consultarTipoCambio() {
        estaCargandoTasa = true
        Task {
            do {
                let tasas = try await servicioTipoCambio.obtenerTasas()
                await MainActor.run {
                    self.tasaCambioUSD_MXN = tasas.mxn
                    self.tasaCambioUSD_PEN = tasas.pen
                    self.errorTipoCambio = false
                    self.estaCargandoTasa = false
                }
            } catch {
                await MainActor.run {
                    self.errorTipoCambio = true
                    self.estaCargandoTasa = false
                }
            }
        }
    }

    // MARK: - Actions
    /// Conecta el catálogo con SwiftData. En el primer arranque siembra el catálogo de referencia;
    /// después carga el catálogo persistido (incluidos los componentes que el usuario haya creado).
    func configurarPersistencia(_ contexto: ModelContext) {
        guard contextoSwiftData == nil else { return }
        contextoSwiftData = contexto

        let descriptor = FetchDescriptor<Componente>(sortBy: [SortDescriptor(\.nombre)])
        let guardados = (try? contexto.fetch(descriptor)) ?? []

        if guardados.isEmpty {
            let nombresSeleccionados = Set(componentesSeleccionados.map(\.nombre))
            let extras = Self.catalogoDisponible.filter { !nombresSeleccionados.contains($0.nombre) }
            var vistos = Set<UUID>()
            let catalogo = (componentesSeleccionados + extras).filter { vistos.insert($0.id).inserted }
            catalogo.forEach { contexto.insert($0) }
            try? contexto.save()
            inventarioAlmacen = catalogo
        } else {
            inventarioAlmacen = guardados
            componentesSeleccionados = componentesSeleccionados.compactMap { seleccionado in
                guardados.first { $0.nombre == seleccionado.nombre }
            }
        }
    }

    func registrarNuevoComponenteEnAlmacen(_ componente: Componente) {
        contextoSwiftData?.insert(componente)
        try? contextoSwiftData?.save()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            inventarioAlmacen.insert(componente, at: 0)
        }
    }

    func incrementarCantidad(_ componente: Componente) {
        agregarComponente(componente)
    }

    /// Quita una unidad; si era la última, elimina la línea.
    func decrementarCantidad(_ componente: Componente) {
        guard let indice = componentesSeleccionados.firstIndex(where: { $0.id == componente.id }) else { return }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            _ = componentesSeleccionados.remove(at: indice)
        }
    }

    func eliminarLineas(en offsets: IndexSet) {
        let lineas = lineasSeleccionadas
        let ids = Set(offsets.compactMap { lineas.indices.contains($0) ? lineas[$0].id : nil })
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            componentesSeleccionados.removeAll { ids.contains($0.id) }
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
        var vistos = Set<UUID>()
        let distintos = componentesSeleccionados.filter { vistos.insert($0.id).inserted }
        return Cotizacion(
            cliente: clienteNombre.isEmpty ? "Cliente Corporativo" : clienteNombre,
            fecha: .now,
            componentes: distintos,
            lineas: lineasSeleccionadas.map { LineaCotizacion(componente: $0.componente, cantidad: $0.cantidad) },
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
                precioBase: Decimal(string: "649.00")!,
                socket: "AM5",
                consumoWatts: 170,
                stock: 14,
                descripcion: "Procesador de 16 núcleos y 32 hilos para estaciones de trabajo de alto rendimiento. Socket AM5 con soporte DDR5."
            ),
            Componente(
                nombre: "ASUS ProArt X870E-Creator WiFi",
                categoria: .placa,
                precioBase: Decimal(string: "479.00")!,
                socket: "AM5",
                consumoWatts: 55,
                stock: 9,
                descripcion: "Placa base AM5 para creadores y estaciones de trabajo: DDR5, PCIe 5.0, Wi-Fi 7 y conectividad 10 GbE."
            ),
            Componente(
                nombre: "NVIDIA RTX 4500 Ada Generation 24GB",
                categoria: .gpu,
                precioBase: Decimal(string: "2250.00")!,
                socket: "PCIe 4.0 x16",
                consumoWatts: 210,
                stock: 6,
                descripcion: "GPU profesional con 24 GB de memoria para renderizado, simulación e IA en estaciones de trabajo."
            ),
            Componente(
                nombre: "Kingston Server Premier 64GB DDR5 ECC",
                categoria: .ram,
                precioBase: Decimal(string: "289.00")!,
                socket: "DDR5",
                consumoWatts: 18,
                stock: 22,
                descripcion: "Módulo de memoria DDR5 de 64 GB con corrección de errores (ECC) para equipos que requieren estabilidad continua."
            ),
            Componente(
                nombre: "Seasonic PRIME TX-850 80+ Titanium",
                categoria: .fuente,
                precioBase: Decimal(string: "279.00")!,
                socket: "ATX 3.1",
                consumoWatts: 850,
                stock: 11,
                descripcion: "Fuente ATX 3.1 de 850 W con certificación 80+ Titanium, de alta eficiencia y bajo ruido."
            )
        ]
    }

    static var catalogoDisponible: [Componente] {
        componentesDemostracion + [
            Componente(
                nombre: "Intel Xeon w7-2495X 24-Core",
                categoria: .cpu,
                precioBase: Decimal(string: "2189.00")!,
                socket: "LGA4677",
                consumoWatts: 225,
                stock: 4,
                descripcion: "Procesador Xeon de 24 núcleos para estaciones de trabajo, socket LGA4677 con memoria DDR5 ECC."
            ),
            Componente(
                nombre: "NVIDIA RTX 6000 Ada Generation 48GB",
                categoria: .gpu,
                precioBase: Decimal(string: "6800.00")!,
                socket: "PCIe 4.0 x16",
                consumoWatts: 300,
                stock: 3,
                descripcion: "GPU profesional de 48 GB para cargas pesadas de cómputo gráfico, modelado 3D e inteligencia artificial."
            ),
            Componente(
                nombre: "Corsair WS DDR5 RDIMM 128GB (4x32GB)",
                categoria: .ram,
                precioBase: Decimal(string: "640.00")!,
                socket: "DDR5",
                consumoWatts: 32,
                stock: 8,
                descripcion: "Kit de cuatro módulos DDR5 RDIMM de 32 GB (128 GB en total) para estaciones de trabajo y servidores."
            ),
            Componente(
                nombre: "Seasonic PRIME PX-1300 80+ Platinum",
                categoria: .fuente,
                precioBase: Decimal(string: "369.00")!,
                socket: "ATX 3.1",
                consumoWatts: 1300,
                stock: 7,
                descripcion: "Fuente ATX 3.1 de 1300 W 80+ Platinum para configuraciones con varias GPU."
            )
        ]
    }
}
