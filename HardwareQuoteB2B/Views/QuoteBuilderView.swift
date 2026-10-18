//
//  QuoteBuilderView.swift
//  HardwareQuoteB2B
//

import SwiftData
import SwiftUI

struct QuoteBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = QuoteBuilderViewModel()
    @State private var mostrarConfirmacionGuardado = false

    // Acento corporativo sutil (Azul Pizarra Ejecutivo)
    private let corporateAccent = Color(red: 0.20, green: 0.34, blue: 0.55)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerClienteSection
                        medidorEnergiaCard
                        listadoPiezasSection
                        margenComercialCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 160)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Cotizador B2B")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        viewModel.mostrarSelectorCatalogo = true
                    } label: {
                        Label("Añadir Pieza", systemImage: "plus.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(corporateAccent)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                resumenFinancieroFlotante
            }
            .sheet(isPresented: $viewModel.mostrarSelectorCatalogo) {
                CatalogoSelectorSheet(
                    viewModel: viewModel,
                    accentColor: corporateAccent
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(.ultraThinMaterial)
            }
            .alert("Cotización Registrada", isPresented: $mostrarConfirmacionGuardado) {
                Button("Aceptar", role: .cancel) {}
            } message: {
                Text("La propuesta para \(viewModel.clienteNombre) se ha guardado correctamente.")
            }
        }
    }

    // MARK: - 1. Encabezado de Cuenta Corporativa
    private var headerClienteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CUENTA CORPORATIVA")
                .font(.caption2.weight(.semibold))
                .tracking(1.1)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Image(systemName: "building.2.crop.circle")
                    .font(.title3)
                    .foregroundStyle(corporateAccent)

                TextField("Nombre del cliente o empresa", text: $viewModel.clienteNombre)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.07), lineWidth: 0.8)
            )
        }
    }

    // MARK: - 2. Barra Interactiva Animada de Consumo en Watts
    private var medidorEnergiaCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("DEMANDA ENERGÉTICA", systemImage: "bolt.fill")
                        .font(.caption2.weight(.semibold))
                        .tracking(1.1)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.consumoTotalWatts)")
                            .font(.system(size: 32, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                            .contentTransition(.numericText(value: Double(viewModel.consumoTotalWatts)))
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.consumoTotalWatts)

                        Text("/ \(viewModel.capacidadFuenteWatts) W")
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text(viewModel.estadoEnergia.etiqueta)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(colorEstadoEnergia)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        colorEstadoEnergia.opacity(0.12),
                        in: Capsule(style: .continuous)
                    )
            }

            // Barra animada con indicadores de umbral
            GeometryReader { proxy in
                let totalWidth = proxy.size.width
                let fillWidth = max(0, min(totalWidth * viewModel.porcentajeCargaWatts, totalWidth))

                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 10)

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [corporateAccent, colorEstadoEnergia],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: fillWidth, height: 10)
                        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: viewModel.porcentajeCargaWatts)

                    // Marcador sutil del 80% de eficiencia recomendada
                    Rectangle()
                        .fill(Color.primary.opacity(0.22))
                        .frame(width: 1.5, height: 14)
                        .offset(x: totalWidth * 0.80)
                }
            }
            .frame(height: 14)

            HStack {
                Text("Carga estimada del sistema: \(Int(viewModel.porcentajeCargaWatts * 100))%")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Umbral óptimo ≤ 80%")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }

    private var colorEstadoEnergia: Color {
        switch viewModel.estadoEnergia {
        case .optimo:
            return corporateAccent
        case .moderado:
            return Color.orange
        case .critico:
            return Color.red
        }
    }

    // MARK: - 3. Listado de Piezas Seleccionadas
    private var listadoPiezasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CONFIGURACIÓN DE HARDWARE")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(viewModel.componentesSeleccionados.count) piezas")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if viewModel.componentesSeleccionados.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "cpu")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("Sin componentes asignados")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                    Button("Explorar catálogo corporativo") {
                        viewModel.mostrarSelectorCatalogo = true
                    }
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(corporateAccent)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.componentesSeleccionados.enumerated()), id: \.element.id) { index, componente in
                        ComponenteFilaView(
                            componente: componente,
                            accentColor: corporateAccent,
                            onRemove: {
                                viewModel.eliminarComponente(componente)
                            }
                        )

                        if index < viewModel.componentesSeleccionados.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
                )
            }
        }
    }

    // MARK: - 4. Control Reactivo de Margen Comercial
    private var margenComercialCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("MARGEN COMERCIAL B2B")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(Int((viewModel.margenGanancia * 100).rounded()))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(corporateAccent)
                    .contentTransition(.numericText(value: viewModel.margenGanancia))
            }

            Slider(
                value: $viewModel.margenGanancia,
                in: 0.05...0.45,
                step: 0.01
            )
            .tint(corporateAccent)

            HStack(spacing: 8) {
                ForEach([0.12, 0.18, 0.25, 0.35], id: \.self) { preset in
                    let isSelected = abs(viewModel.margenGanancia - preset) < 0.005
                    Button {
                        withAnimation(.snappy(duration: 0.25)) {
                            viewModel.margenGanancia = preset
                        }
                    } label: {
                        Text("\(Int(preset * 100))%")
                            .font(.caption.weight(.medium))
                            .monospacedDigit()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 7)
                            .background(
                                isSelected ? corporateAccent.opacity(0.15) : Color.primary.opacity(0.05),
                                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                            )
                            .foregroundStyle(isSelected ? corporateAccent : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }

    // MARK: - 5. Barra Flotante de Resumen Financiero (.ultraThinMaterial)
    private var resumenFinancieroFlotante: some View {
        VStack(spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Subtotal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(viewModel.subtotal, format: .currency(code: "USD"))
                                .font(.subheadline.weight(.medium))
                                .monospacedDigit()
                                .contentTransition(.numericText(value: viewModel.subtotal))
                        }

                        Divider()
                            .frame(height: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Margen (+\(Int((viewModel.margenGanancia * 100).rounded()))%)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(viewModel.utilidadComercial, format: .currency(code: "USD"))
                                .font(.subheadline.weight(.medium))
                                .monospacedDigit()
                                .foregroundStyle(corporateAccent)
                                .contentTransition(.numericText(value: viewModel.utilidadComercial))
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("TOTAL COTIZACIÓN")
                        .font(.caption2.weight(.semibold))
                        .tracking(0.8)
                        .foregroundStyle(.secondary)

                    Text(viewModel.precioFinal, format: .currency(code: "USD"))
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText(value: viewModel.precioFinal))
                }
            }
            .animation(.snappy(duration: 0.25), value: viewModel.precioFinal)

            Button {
                let nuevaCotizacion = viewModel.generarCotizacion()
                modelContext.insert(nuevaCotizacion)
                mostrarConfirmacionGuardado = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.badge.checkmark")
                    Text("Emitir Propuesta Formal")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    viewModel.componentesSeleccionados.isEmpty ? Color.secondary.opacity(0.4) : corporateAccent,
                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                )
            }
            .disabled(viewModel.componentesSeleccionados.isEmpty)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Divider()
                .opacity(0.5)
        }
    }
}

// MARK: - Subvista de Fila de Componente
private struct ComponenteFilaView: View {
    let componente: Componente
    let accentColor: Color
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icono(para: componente.categoria))
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 34, height: 34)
                .background(
                    accentColor.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 9, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(componente.nombre)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(componente.categoria.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let socket = componente.socket, !socket.isEmpty {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                        Text(socket)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(componente.categoria == .fuente ? "Capacidad \(componente.consumoWatts)W" : "\(componente.consumoWatts)W")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 8)

            Text(componente.precioBase, format: .currency(code: "USD"))
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(.primary)

            Button(role: .destructive, action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .symbolRenderingMode(.hierarchical)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Eliminar \(componente.nombre)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private func icono(para categoria: CategoriaComponente) -> String {
        switch categoria {
        case .cpu: return "cpu"
        case .gpu: return "display"
        case .ram: return "memorychip"
        case .placa: return "circuitboard"
        case .fuente: return "bolt.horizontal.circle"
        }
    }
}

// MARK: - Hoja Modal de Catálogo de Piezas
private struct CatalogoSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: QuoteBuilderViewModel
    let accentColor: Color

    var body: some View {
        NavigationStack {
            List(QuoteBuilderViewModel.catalogoDisponible) { item in
                Button {
                    viewModel.agregarComponente(
                        Componente(
                            nombre: item.nombre,
                            categoria: item.categoria,
                            precioBase: item.precioBase,
                            socket: item.socket,
                            consumoWatts: item.consumoWatts,
                            stock: item.stock
                        )
                    )
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.nombre)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)

                            Text("\(item.categoria.rawValue) • \(item.consumoWatts)W • Stock: \(item.stock)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Text(item.precioBase, format: .currency(code: "USD"))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(accentColor)
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle("Añadir Componente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    QuoteBuilderView()
        .modelContainer(for: [Componente.self, Cotizacion.self], inMemory: true)
}
