//
//  MainTabView.swift
//  HardwareQuoteB2B
//
//  Navegación principal: Cotizador, Almacén, Historial y Perfil.
//

import FirebaseAuth
import SwiftData
import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = QuoteBuilderViewModel()

    private let acento = Color(red: 0.20, green: 0.34, blue: 0.55)

    var body: some View {
        TabView {
            QuoteBuilderView(viewModel: viewModel)
                .tabItem { Label("Cotizador", systemImage: "square.and.pencil") }

            NavigationStack {
                CatalogoHardwareView(viewModel: viewModel, accentColor: acento, mostrarBotonListo: false)
            }
            .tabItem { Label("Almacén", systemImage: "shippingbox") }

            HistorialCotizacionesViewRepresentable()
                .ignoresSafeArea()
                .tabItem { Label("Historial", systemImage: "clock.arrow.circlepath") }

            PerfilView(acento: acento)
                .tabItem { Label("Perfil", systemImage: "person.crop.circle") }
        }
        .tint(acento)
        .onAppear { viewModel.configurarPersistencia(modelContext) }
    }
}

struct PerfilView: View {
    let acento: Color

    private var email: String {
        Auth.auth().currentUser?.email ?? "Sin sesión"
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(acento)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Ensamblador")
                                .font(.headline)
                            Text(email)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    Button(role: .destructive) {
                        cerrarSesion()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Perfil")
        }
    }

    /// Cierra la sesión de Firebase y vuelve a la pantalla de Login.
    private func cerrarSesion() {
        try? Auth.auth().signOut()

        let escena = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        guard let ventana = escena?.windows.first(where: \.isKeyWindow) ?? escena?.windows.first else { return }

        UIView.transition(with: ventana, duration: 0.4, options: .transitionCrossDissolve) {
            ventana.rootViewController = LoginViewController()
        }
    }
}
