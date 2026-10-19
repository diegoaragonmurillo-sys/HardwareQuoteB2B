//
//  ProductoDetalleView.swift
//  HardwareQuoteB2B
//
//  Detalle de un producto del almacén: foto, descripción y pestañas
//  (Resumen, Especificaciones, Compatibilidad, Documentos).
//

import SwiftUI

struct ProductoDetalleView: View {
    enum Pestana: String, CaseIterable, Identifiable {
        case resumen = "Resumen"
        case especificaciones = "Especificaciones"
        case compatibilidad = "Compatibilidad"
        case documentos = "Documentos"

        var id: String { rawValue }
    }

    let componente: Componente
    var viewModel: QuoteBuilderViewModel
    var accentColor: Color = Color(red: 0.20, green: 0.34, blue: 0.55)

    @State private var pestana: Pestana = .resumen
    @State private var agregado = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                foto

                VStack(alignment: .leading, spacing: 6) {
                    Text(componente.nombre)
                        .font(.title2.weight(.bold))
                    Text(componente.precioBase, format: .currency(code: "USD"))
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundStyle(accentColor)
                }

                Picker("Sección", selection: $pestana) {
                    ForEach(Pestana.allCases) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)

                Group {
                    switch pestana {
                    case .resumen: resumen
                    case .especificaciones: especificaciones
                    case .compatibilidad: compatibilidad
                    case .documentos: documentos
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                viewModel.agregarComponente(componente)
                agregado = true
            } label: {
                Label(agregado ? "Agregado a la cotización" : "Agregar a la cotización",
                      systemImage: agregado ? "checkmark.circle.fill" : "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
        }
    }

    // MARK: - Foto

    private var foto: some View {
        Group {
            if let texto = componente.fotoURL, let url = URL(string: texto) {
                AsyncImage(url: url) { fase in
                    switch fase {
                    case .success(let imagen):
                        imagen.resizable().scaledToFit()
                    case .failure:
                        iconoRespaldo
                    default:
                        ProgressView()
                    }
                }
            } else {
                iconoRespaldo
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
        .background(accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .accessibilityLabel("Foto de \(componente.nombre)")
    }

    private var iconoRespaldo: some View {
        Image(systemName: ProductoDetalleView.icono(para: componente.categoria))
            .font(.system(size: 64, weight: .light))
            .foregroundStyle(accentColor)
    }

    // MARK: - Pestañas

    private var resumen: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(componente.descripcion ?? "Este producto aún no tiene una descripción registrada.")
                .font(.body)
                .foregroundStyle(componente.descripcion == nil ? .secondary : .primary)

            HStack(spacing: 10) {
                etiqueta(componente.categoria.rawValue, icono: ProductoDetalleView.icono(para: componente.categoria))
                etiqueta("\(componente.consumoWatts) W", icono: "bolt.fill")
                etiqueta("Stock \(componente.stock)", icono: "shippingbox")
            }
        }
    }

    private var especificaciones: some View {
        VStack(spacing: 0) {
            fila("Categoría", componente.categoria.rawValue)
            fila("Socket / Interfaz", componente.socket ?? "No especificado")
            fila(componente.categoria == .fuente ? "Capacidad" : "Consumo", "\(componente.consumoWatts) W")
            fila("Precio base", componente.precioBase.formatted(.currency(code: "USD")))
            fila("Stock", "\(componente.stock) uds.")
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var compatibilidad: some View {
        let enCotizacion = viewModel.componentesSeleccionados
            .filter { $0.id != componente.id }

        return VStack(alignment: .leading, spacing: 12) {
            Text("Socket / Interfaz: \(componente.socket ?? "No especificado")")
                .font(.subheadline.weight(.semibold))

            if enCotizacion.isEmpty {
                Text("Agrega componentes a la cotización para comparar su compatibilidad con este producto.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(enCotizacion) { otro in
                    HStack {
                        Text(otro.nombre)
                            .font(.subheadline)
                            .lineLimit(1)
                        Spacer()
                        Text(otro.socket ?? "—")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var documentos: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let texto = componente.fichaTecnicaURL, let url = URL(string: texto) {
                Link(destination: url) {
                    Label("Ficha técnica (PDF)", systemImage: "doc.richtext")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(accentColor)
                }
            } else {
                Text("Este producto no tiene documentos adjuntos.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Componentes de apoyo

    private func fila(_ titulo: String, _ valor: String) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(titulo).foregroundStyle(.secondary)
                Spacer()
                Text(valor).fontWeight(.medium).monospacedDigit()
            }
            .font(.subheadline)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            Divider().padding(.leading, 14)
        }
    }

    private func etiqueta(_ texto: String, icono: String) -> some View {
        Label(texto, systemImage: icono)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(accentColor.opacity(0.10), in: Capsule())
            .foregroundStyle(accentColor)
    }

    static func icono(para categoria: CategoriaComponente) -> String {
        switch categoria {
        case .cpu: return "cpu"
        case .gpu: return "display"
        case .ram: return "memorychip"
        case .placa: return "memorychip"
        case .fuente: return "bolt.horizontal.circle"
        }
    }
}
