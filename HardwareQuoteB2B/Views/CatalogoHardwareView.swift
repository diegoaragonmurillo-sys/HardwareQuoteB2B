//
//  CatalogoHardwareView.swift
//  HardwareQuoteB2B
//
//  Vista de almacén B2B con stock dinámico de componentes de hardware listos para agregar a la cotización.
//

import SwiftUI

struct CatalogoHardwareView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: QuoteBuilderViewModel
    var accentColor: Color = Color(red: 0.20, green: 0.34, blue: 0.55)
    /// En una pestaña raíz no hay a dónde volver, así que se oculta.
    var mostrarBotonListo: Bool = true

    @State private var textoBusqueda: String = ""
    @State private var categoriaSeleccionada: CategoriaComponente? = nil
    @State private var ultimoComponenteAgregado: String? = nil
    @State private var mostrandoFormulario = false

    // Filtra directamente desde la propiedad reactiva viewModel.inventarioAlmacen
    private var inventarioFiltrado: [Componente] {
        viewModel.inventarioAlmacen.filter { item in
            let coincideCategoria = (categoriaSeleccionada == nil) || (item.categoria == categoriaSeleccionada)
            let query = textoBusqueda.trimmingCharacters(in: .whitespacesAndNewlines)
            let coincideTexto = query.isEmpty ||
                item.nombre.localizedCaseInsensitiveContains(query) ||
                item.categoria.rawValue.localizedCaseInsensitiveContains(query) ||
                (item.socket?.localizedCaseInsensitiveContains(query) ?? false)
            return coincideCategoria && coincideTexto
        }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    filtrosCategoriaSection

                    VStack(spacing: 12) {
                        ForEach(inventarioFiltrado) { item in
                            TarjetaAlmacenRow(
                                componente: item,
                                accentColor: accentColor,
                                alAgregar: {
                                    agregarAlCotizador(item)
                                }
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 80)
            }
            .scrollIndicators(.hidden)

            if let nombreAgregado = ultimoComponenteAgregado {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text("Añadido: \(nombreAgregado)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.primary.opacity(0.10), lineWidth: 0.8)
                )
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle("Almacén de Hardware")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 14) {
                    Button {
                        mostrandoFormulario = true
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                            .foregroundStyle(accentColor)
                    }
                    .accessibilityLabel("Registrar nuevo componente en almacén")

                    if mostrarBotonListo {
                        Button("Listo") {
                            dismiss()
                        }
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)
                    }
                }
            }
        }
        .searchable(text: $textoBusqueda, prompt: "Buscar CPU, GPU, RAM, socket...")
        .sheet(isPresented: $mostrandoFormulario) {
            CrearComponenteFormView(
                viewModel: viewModel,
                accentColor: accentColor
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Selector de Categorías
    private var filtrosCategoriaSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chipFiltro(titulo: "Todos", seleccionado: categoriaSeleccionada == nil) {
                    withAnimation(.snappy(duration: 0.2)) {
                        categoriaSeleccionada = nil
                    }
                }

                ForEach(CategoriaComponente.allCases) { categoria in
                    chipFiltro(
                        titulo: categoria.rawValue,
                        seleccionado: categoriaSeleccionada == categoria
                    ) {
                        withAnimation(.snappy(duration: 0.2)) {
                            categoriaSeleccionada = categoria
                        }
                    }
                }
            }
        }
    }

    private func chipFiltro(titulo: String, seleccionado: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(titulo)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    seleccionado ? accentColor : Color.primary.opacity(0.06),
                    in: Capsule()
                )
                .foregroundStyle(seleccionado ? .white : .secondary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Acción para añadir al ViewModel principal
    private func agregarAlCotizador(_ item: Componente) {
        // Se agrega la misma instancia del catálogo (no una copia) para que la cantidad se agrupe por producto.
        viewModel.agregarComponente(item)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            ultimoComponenteAgregado = item.nombre
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeOut(duration: 0.25)) {
                if ultimoComponenteAgregado == item.nombre {
                    ultimoComponenteAgregado = nil
                }
            }
        }
    }
}

// MARK: - Tarjeta Individual de Componente en Almacén
private struct TarjetaAlmacenRow: View {
    let componente: Componente
    let accentColor: Color
    let alAgregar: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icono(para: componente.categoria))
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 42, height: 42)
                .background(
                    accentColor.opacity(0.10),
                    in: RoundedRectangle(cornerRadius: 11, style: .continuous)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(componente.nombre)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(componente.categoria.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(accentColor)

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

                    Text("\(componente.consumoWatts)W")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text("Stock: \(componente.stock)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text(componente.precioBase, format: .currency(code: "USD"))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)
                    .padding(.top, 2)
            }

            Spacer(minLength: 8)

            Button(action: alAgregar) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(accentColor, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agregar \(componente.nombre) a la cotización")
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
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
