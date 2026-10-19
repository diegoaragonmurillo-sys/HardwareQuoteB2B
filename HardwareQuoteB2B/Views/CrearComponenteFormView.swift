//
//  CrearComponenteFormView.swift
//  HardwareQuoteB2B
//
//  Formulario en SwiftUI para dar de alta un nuevo componente en el almacén en tiempo real.
//

import SwiftUI

struct CrearComponenteFormView: View {
    @Environment(\.dismiss) private var dismiss

    var viewModel: QuoteBuilderViewModel
    var accentColor: Color = Color(red: 0.20, green: 0.34, blue: 0.55)

    // MARK: - Estado del Formulario
    @State private var nombre: String = ""
    @State private var categoria: CategoriaComponente = .cpu
    @State private var precioBaseTexto: String = ""
    @State private var consumoWattsTexto: String = ""
    @State private var socketDetalle: String = ""
    @State private var stockInicial: Int = 10
    @State private var descripcion: String = ""
    @State private var fotoURLTexto: String = ""
    @State private var fichaTecnicaTexto: String = ""

    private var formularioValido: Bool {
        let nombreLimpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        let precio = Decimal(string: precioBaseTexto.replacingOccurrences(of: ",", with: ".")) ?? 0
        let watts = Int(consumoWattsTexto) ?? 0
        return !nombreLimpio.isEmpty && precio > 0 && watts > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Información General") {
                    TextField("Nombre del componente (ej. AMD EPYC 9654)", text: $nombre)
                        .textInputAutocapitalization(.words)

                    Picker("Categoría", selection: $categoria) {
                        ForEach(CategoriaComponente.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }

                    TextField("Socket / Detalle técnico (opcional)", text: $socketDetalle)
                        .textInputAutocapitalization(.characters)
                }

                Section("Especificaciones Comerciales y Energéticas") {
                    HStack {
                        Text("Precio Base (USD)")
                        Spacer()
                        TextField("0.00", text: $precioBaseTexto)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }

                    HStack {
                        Text(categoria == .fuente ? "Capacidad (Watts)" : "Consumo (Watts)")
                        Spacer()
                        TextField("0", text: $consumoWattsTexto)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .monospacedDigit()
                    }

                    Stepper("Stock Inicial: \(stockInicial) uds.", value: $stockInicial, in: 1...500)
                        .monospacedDigit()
                }

                Section("Detalle del Producto (opcional)") {
                    TextField("Descripción", text: $descripcion, axis: .vertical)
                        .lineLimit(2...5)
                    TextField("URL de la foto", text: $fotoURLTexto)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("URL de la ficha técnica (PDF)", text: $fichaTecnicaTexto)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }

                Section {
                    Button {
                        guardarComponente()
                    } label: {
                        HStack(spacing: 8) {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                            Text("Guardar en Almacén")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(formularioValido ? accentColor : Color.secondary.opacity(0.35))
                    .disabled(!formularioValido)
                }
            }
            .navigationTitle("Nuevo Componente")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func textoOpcional(_ texto: String) -> String? {
        let limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        return limpio.isEmpty ? nil : limpio
    }

    private func guardarComponente() {
        let nombreFinal = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        let precioFinal = Decimal(string: precioBaseTexto.replacingOccurrences(of: ",", with: ".")) ?? 0
        let wattsFinal = Int(consumoWattsTexto) ?? 0
        let socketLimpio = socketDetalle.trimmingCharacters(in: .whitespacesAndNewlines)

        let nuevoComponente = Componente(
            nombre: nombreFinal,
            categoria: categoria,
            precioBase: precioFinal,
            socket: socketLimpio.isEmpty ? nil : socketLimpio,
            consumoWatts: wattsFinal,
            stock: stockInicial,
            descripcion: textoOpcional(descripcion),
            fotoURL: textoOpcional(fotoURLTexto),
            fichaTecnicaURL: textoOpcional(fichaTecnicaTexto)
        )

        viewModel.registrarNuevoComponenteEnAlmacen(nuevoComponente)
        dismiss()
    }
}
