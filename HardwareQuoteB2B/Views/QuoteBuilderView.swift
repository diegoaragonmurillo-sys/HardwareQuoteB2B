//
//  QuoteBuilderView.swift
//  HardwareQuoteB2B
//
//  Created as part of the B2B Hardware Quoting Platform.
//  Specialist: Modern SwiftUI Architecture & UIKit Bridge Integration.
//

import SwiftData
import SwiftUI
import UIKit

struct QuoteBuilderView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = QuoteBuilderViewModel()

    // MARK: - Variables de Estado de Navegación y Exportación
    @State private var mostrarHistorial = false
    @State private var mostrarShareSheet = false
    @State private var urlDocumentoPDF: URL?
    @State private var estaGenerandoPDF = false

    // Acento corporativo sutil (Azul Pizarra Ejecutivo)
    private let corporateAccent = Color(red: 0.20, green: 0.34, blue: 0.55)

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        cabeceraPrincipalSection
                        headerClienteSection
                        medidorEnergiaCard
                        listadoPiezasSection
                        ControlNotasVozView(accentColor: corporateAccent)
                        margenComercialCard
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 160)
                }
                .scrollIndicators(.hidden)
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                resumenFinancieroFlotante
            }
            // Sheet: Historial de Cotizaciones (CoreData + Firebase RTDB vía HistorialManager)
            .sheet(isPresented: $mostrarHistorial) {
                HistorialCotizacionesViewRepresentable()
            }
            // Sheet: Hoja nativa de compartir PDF (WhatsApp, Correo, Archivos)
            .sheet(isPresented: $mostrarShareSheet) {
                if let url = urlDocumentoPDF {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    // MARK: - Cabecera Principal Alineada Arriba (.top)
    private var cabeceraPrincipalSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("Cotizador B2B")
                    .font(.system(size: 28, weight: .bold, design: .default))
                    .foregroundStyle(.primary)

                Text("Armado y validación de infraestructura")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Botón de Historial
            Button {
                mostrarHistorial = true
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.subheadline.weight(.semibold))
                    Text("Historial")
                        .font(.footnote.weight(.semibold))
                }
                .foregroundStyle(corporateAccent)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(corporateAccent.opacity(0.10), in: Capsule())
            }
            .accessibilityLabel("Ver historial de cotizaciones")

            // Puente NavigationLink hacia CatalogoHardwareView
            NavigationLink {
                CatalogoHardwareView(
                    viewModel: viewModel,
                    accentColor: corporateAccent
                )
            } label: {
                Image(systemName: "plus")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(corporateAccent, in: Circle())
            }
            .accessibilityLabel("Abrir almacén de hardware")
        }
        .padding(.top, 4)
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
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(colorParaEstadoEnergia(viewModel.estadoEnergia))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        colorParaEstadoEnergia(viewModel.estadoEnergia).opacity(0.12),
                        in: Capsule()
                    )
            }

            GeometryReader { geometry in
                let anchoTotal = geometry.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(height: 10)

                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(colorParaEstadoEnergia(viewModel.estadoEnergia))
                        .frame(
                            width: max(0, min(anchoTotal * viewModel.porcentajeCargaWatts, anchoTotal)),
                            height: 10
                        )
                        .animation(.spring(response: 0.45, dampingFraction: 0.75), value: viewModel.porcentajeCargaWatts)
                }
            }
            .frame(height: 10)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }

    private func colorParaEstadoEnergia(_ estado: QuoteBuilderViewModel.EstadoEnergia) -> Color {
        switch estado {
        case .optimo: return .green
        case .moderado: return .orange
        case .critico: return .red
        }
    }

    // MARK: - 3. Listado Dinámico de Componentes con Swipe to Delete (.onDelete)
    private var listadoPiezasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("CONFIGURACIÓN DE HARDWARE")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Spacer()

                NavigationLink {
                    CatalogoHardwareView(
                        viewModel: viewModel,
                        accentColor: corporateAccent
                    )
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Almacén (\(viewModel.componentesSeleccionados.count))")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(corporateAccent)
                }
            }

            if viewModel.componentesSeleccionados.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "cpu")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("Sin componentes asignados")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    NavigationLink {
                        CatalogoHardwareView(
                            viewModel: viewModel,
                            accentColor: corporateAccent
                        )
                    } label: {
                        Text("Explorar almacén corporativo")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(corporateAccent)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            } else {
                List {
                    ForEach(viewModel.componentesSeleccionados) { componente in
                        ComponenteFilaView(
                            componente: componente,
                            accentColor: corporateAccent
                        )
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .listRowBackground(Color.clear)
                    }
                    .onDelete(perform: viewModel.eliminarComponentes)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .scrollDisabled(true)
                .frame(height: CGFloat(viewModel.componentesSeleccionados.count) * 66)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
                    .font(.title3.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(corporateAccent)
            }

            Slider(value: $viewModel.margenGanancia, in: 0.05...0.40, step: 0.01)
                .tint(corporateAccent)

            HStack {
                Text("Mínimo: 5%")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer()
                Text("Techo sugerido: 40%")
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

    // MARK: - 5. Barra Flotante de Resumen Financiero y Emisión de Cotización
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
                emitirYCompartirPropuesta()
            } label: {
                HStack(spacing: 8) {
                    if estaGenerandoPDF {
                        ProgressView()
                            .tint(.white)
                        Text("Generando Propuesta...")
                            .fontWeight(.semibold)
                    } else {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Emitir Propuesta Formal")
                            .fontWeight(.semibold)
                    }
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
            .disabled(viewModel.componentesSeleccionados.isEmpty || estaGenerandoPDF)
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

    // MARK: - Acción de Emisión y Exportación Local de PDF
    private func emitirYCompartirPropuesta() {
        // 1. Guardar en SwiftData
        let nuevaCotizacion = viewModel.generarCotizacion()
        modelContext.insert(nuevaCotizacion)

        // 2. Guardar en CoreData y sincronizar con Firebase RTDB mediante HistorialManager
        HistorialManager.shared.guardarCotizacion(
            id: nuevaCotizacion.id,
            cliente: viewModel.clienteNombre,
            montoTotal: viewModel.precioFinal
        )

        // 3. Tarea asíncrona para generar el PDF localmente
        estaGenerandoPDF = true
        Task {
            do {
                let urlPDF = try await QuotePDFManager.shared.generarYGuardarPDFLocal(
                    cliente: viewModel.clienteNombre,
                    subtotal: viewModel.subtotal,
                    margen: viewModel.margenGanancia,
                    totalFinal: viewModel.precioFinal,
                    idCotizacion: nuevaCotizacion.id.uuidString
                )

                await MainActor.run {
                    self.urlDocumentoPDF = urlPDF
                    self.estaGenerandoPDF = false
                    self.mostrarShareSheet = true
                }
            } catch {
                await MainActor.run {
                    self.estaGenerandoPDF = false
                    print("❌ Error al exportar PDF: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Subvista de Fila de Componente
private struct ComponenteFilaView: View {
    let componente: Componente
    let accentColor: Color

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
        }
        .frame(height: 46)
    }

    private func icono(para categoria: CategoriaComponente) -> String {
        switch categoria {
        case .cpu: return "cpu"
        case .gpu: return "display"
        case .ram: return "memorychip"
        case .placa: return "memorychip"
        case .fuente: return "bolt.horizontal.circle"
        }
    }
}

// MARK: - Puente UIViewControllerRepresentable para el Historial de Cotizaciones
struct HistorialCotizacionesViewRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UINavigationController {
        let historialVC = HistorialCotizacionesViewController()
        return UINavigationController(rootViewController: historialVC)
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}
}

// MARK: - Puente UIViewControllerRepresentable para ShareSheet (UIActivityViewController)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: applicationActivities
        )
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        if let popover = uiViewController.popoverPresentationController {
            popover.sourceView = uiViewController.view
            popover.sourceRect = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
    }
}

#Preview {
    QuoteBuilderView()
        .modelContainer(for: [Componente.self, Cotizacion.self], inMemory: true)
}
