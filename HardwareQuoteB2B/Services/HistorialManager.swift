//
//  HistorialManager.swift
//  HardwareQuoteB2B
//
//  Singleton de persistencia dual atómica (CoreData programático + Firebase RTDB 1:1).
//

import Foundation
import CoreData

#if canImport(FirebaseDatabase)
import FirebaseDatabase
#else
// MARK: - Firebase Realtime Database Stub (Fallback para compilación antes de vincular SPM)
public final class DatabaseReference {
    public let key: String?
    private let path: String

    init(path: String = "", key: String? = nil) {
        self.path = path
        self.key = key
    }

    public func child(_ pathString: String) -> DatabaseReference {
        let clean = path.isEmpty ? pathString : "\(path)/\(pathString)"
        return DatabaseReference(path: clean, key: pathString)
    }

    public func childByAutoId() -> DatabaseReference {
        let generatedKey = UUID().uuidString
        return DatabaseReference(path: "\(path)/\(generatedKey)", key: generatedKey)
    }

    public func setValue(_ value: Any?, withCompletionBlock block: ((Error?, DatabaseReference) -> Void)? = nil) {
        print("📡 [Firebase RTDB Stub] Sincronizando en nodo '/\(path)':")
        if let val = value {
            print("   \(val)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            block?(nil, self)
        }
    }

    public func removeValue(completionBlock block: ((Error?, DatabaseReference) -> Void)? = nil) {
        print("🗑️ [Firebase RTDB Stub] Eliminando nodo '/\(path)'")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self else { return }
            block?(nil, self)
        }
    }
}

public final class Database {
    public static let shared = Database()
    public static func database() -> Database { shared }

    public func reference() -> DatabaseReference {
        return DatabaseReference()
    }
}
#endif

extension Notification.Name {
    static let historialCotizacionesActualizado = Notification.Name("historialCotizacionesActualizado")
}

// MARK: - HistorialManager Singleton

final class HistorialManager {

    static let shared = HistorialManager()

    // MARK: - CoreData Stack Programático
    private lazy var persistentContainer: NSPersistentContainer = {
        let model = crearModeloCoreDataProgramatico()
        let container = NSPersistentContainer(name: "HardwareQuoteCoreData", managedObjectModel: model)

        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Error al inicializar almacenamiento CoreData: \(error), \(error.userInfo)")
            } else {
                print("✅ CoreData inicializado correctamente en HistorialManager: \(storeDescription.type)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private(set) var cotizaciones: [NSManagedObject] = []

    private init() {
        recuperarCotizaciones()
    }

    // MARK: - 1. Modelo CoreData Programático
    private func crearModeloCoreDataProgramatico() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        let entidad = NSEntityDescription()
        entidad.name = "CotizacionEntity"
        entidad.managedObjectClassName = NSStringFromClass(NSManagedObject.self)

        let attrId = NSAttributeDescription()
        attrId.name = "id"
        attrId.attributeType = .UUIDAttributeType
        attrId.isOptional = false

        let attrCliente = NSAttributeDescription()
        attrCliente.name = "cliente"
        attrCliente.attributeType = .stringAttributeType
        attrCliente.isOptional = false

        let attrFecha = NSAttributeDescription()
        attrFecha.name = "fecha"
        attrFecha.attributeType = .dateAttributeType
        attrFecha.isOptional = false

        let attrMontoTotal = NSAttributeDescription()
        attrMontoTotal.name = "montoTotal"
        attrMontoTotal.attributeType = .doubleAttributeType
        attrMontoTotal.isOptional = false

        entidad.properties = [attrId, attrCliente, attrFecha, attrMontoTotal]
        model.entities = [entidad]
        return model
    }

    // MARK: - 2. Operaciones CRUD Atómicas (CoreData + Firebase RTDB 1:1)

    /// Recupera las cotizaciones almacenadas en CoreData ordenadas por fecha descendente.
    @discardableResult
    func recuperarCotizaciones() -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CotizacionEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "fecha", ascending: false)]

        do {
            cotizaciones = try context.fetch(fetchRequest)
            return cotizaciones
        } catch {
            print("❌ Error al recuperar cotizaciones de CoreData: \(error.localizedDescription)")
            return []
        }
    }

    /// Guarda una cotización real en CoreData y la sincroniza bajo la misma clave UUID en Firebase RTDB.
    func guardarCotizacion(
        id: UUID = UUID(),
        cliente: String,
        montoTotal: Double,
        fecha: Date = Date(),
        completion: ((Bool) -> Void)? = nil
    ) {
        let nombreClienteLimpio = cliente.trimmingCharacters(in: .whitespacesAndNewlines)
        let clienteFinal = nombreClienteLimpio.isEmpty ? "Cliente Corporativo" : nombreClienteLimpio

        guard let entidad = NSEntityDescription.entity(forEntityName: "CotizacionEntity", in: context) else {
            print("❌ No se encontró la entidad CotizacionEntity en CoreData.")
            completion?(false)
            return
        }

        let nuevaCotizacion = NSManagedObject(entity: entidad, insertInto: context)
        let idUUID = id
        nuevaCotizacion.setValue(idUUID, forKey: "id")
        nuevaCotizacion.setValue(clienteFinal, forKey: "cliente")
        nuevaCotizacion.setValue(montoTotal, forKey: "montoTotal")
        nuevaCotizacion.setValue(fecha, forKey: "fecha")

        do {
            try context.save()
            cotizaciones.insert(nuevaCotizacion, at: 0)
            print("💾 Cotización guardada en CoreData [\(idUUID.uuidString)]: \(clienteFinal) - $\(montoTotal)")

            NotificationCenter.default.post(name: .historialCotizacionesActualizado, object: nil)

            sincronizarConFirebaseRTDB(
                id: idUUID.uuidString,
                cliente: clienteFinal,
                montoTotal: montoTotal,
                fecha: fecha,
                completion: completion
            )
        } catch {
            print("❌ Error al guardar en CoreData: \(error.localizedDescription)")
            completion?(false)
        }
    }

    /// Elimina de forma atómica y bidireccional un registro en CoreData y en Firebase RTDB (/historial_cotizaciones/{uuidString}).
    /// No emite `.historialCotizacionesActualizado` para evitar colisión entre `deleteRows` y `reloadData` en `UITableView`.
    func eliminarCotizacion(
        en indice: Int,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard cotizaciones.indices.contains(indice) else {
            completion?(false)
            return
        }

        let objetoAEliminar = cotizaciones[indice]
        let idUUID = objetoAEliminar.value(forKey: "id") as? UUID

        context.delete(objetoAEliminar)

        do {
            try context.save()
            cotizaciones.remove(at: indice)
            completion?(true)

            if let idUUID = idUUID {
                Database.database()
                    .reference()
                    .child("historial_cotizaciones")
                    .child(idUUID.uuidString)
                    .removeValue { [weak self] error, _ in
                        guard self != nil else { return }
                        DispatchQueue.main.async {
                            if let error = error {
                                print("⚠️ Error al eliminar nodo en Firebase RTDB (\(idUUID.uuidString)): \(error.localizedDescription)")
                            } else {
                                print("🗑️ Nodo eliminado exitosamente en Firebase RTDB: /historial_cotizaciones/\(idUUID.uuidString)")
                            }
                        }
                    }
            }
        } catch {
            print("❌ Error al eliminar cotización de CoreData: \(error.localizedDescription)")
            completion?(false)
        }
    }

    // MARK: - 3. Sincronización Determinista 1:1 con Firebase Realtime Database

    private func sincronizarConFirebaseRTDB(
        id: String,
        cliente: String,
        montoTotal: Double,
        fecha: Date,
        completion: ((Bool) -> Void)? = nil
    ) {
        // Uso determinista de .child(id) en lugar de .childByAutoId() para garantizar clave 1:1 con CoreData
        let nodoRegistro = Database.database()
            .reference()
            .child("historial_cotizaciones")
            .child(id)

        let payload: [String: Any] = [
            "idLocal": id,
            "cliente": cliente,
            "montoTotal": montoTotal,
            "fechaISO": ISO8601DateFormatter().string(from: fecha),
            "timestamp": Int64(fecha.timeIntervalSince1970 * 1000)
        ]

        nodoRegistro.setValue(payload) { [weak self] error, ref in
            guard self != nil else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("⚠️ Error en sincronización RTDB: \(error.localizedDescription)")
                    completion?(false)
                } else {
                    print("☁️ Sincronizado 1:1 con Firebase RTDB en: /historial_cotizaciones/\(ref.key ?? id)")
                    completion?(true)
                }
            }
        }
    }
}
