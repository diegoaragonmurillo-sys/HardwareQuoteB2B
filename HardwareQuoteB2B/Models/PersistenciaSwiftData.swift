import SwiftData

/// Único `ModelContainer` de la app, compartido por la App y el flujo de Login.
enum PersistenciaSwiftData {
    static let contenedor: ModelContainer = {
        do {
            return try ModelContainer(for: Cotizacion.self, Componente.self)
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }()
}
