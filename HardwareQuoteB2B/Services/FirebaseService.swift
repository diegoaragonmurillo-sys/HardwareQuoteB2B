//
//  FirebaseService.swift
//  HardwareQuoteB2B
//
//  Created as part of the B2B Hardware Quoting Platform.
//  Specialist: iOS Persistence & Networking Architecture.
//

import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

#if canImport(FirebaseStorage)
import FirebaseStorage
#endif

#if canImport(FirebaseDatabase)
import FirebaseDatabase
#endif

// MARK: - 1. Modelos de Dominio y DTOs

/// Representa al técnico o ensamblador autenticado en la plataforma B2B.
public struct UsuarioEnsamblador: Codable, Sendable, Identifiable {
    public let id: String
    public let email: String
    public let nombre: String
    public let rol: RolUsuario
    public let fechaAutenticacion: Date

    public enum RolUsuario: String, Codable, Sendable {
        case ensambladorMaster = "ensamblador_master"
        case ensambladorJunior = "ensamblador_junior"
        case controlCalidad = "control_calidad"
        case administrador = "administrador"
    }

    public init(
        id: String,
        email: String,
        nombre: String = "Técnico Ensamblador",
        rol: RolUsuario = .ensambladorMaster,
        fechaAutenticacion: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.nombre = nombre
        self.rol = rol
        self.fechaAutenticacion = fechaAutenticacion
    }
}

/// Estados del ciclo de vida de ensamble y aprobación de la cotización B2B.
public enum EstadoCotizacion: String, Codable, Sendable, CaseIterable {
    case borrador = "BORRADOR"
    case pendienteAprobacion = "PENDIENTE_APROBACION"
    case aprobadoParaEnsamble = "APROBADO_ENSAMBLE"
    case enProcesoEnsamble = "EN_ENSAMBLE"
    case pruebasYControlCalidad = "CONTROL_CALIDAD"
    case listoParaDespacho = "LISTO_DESPACHO"
    case entregado = "ENTREGADO"
    case cancelado = "CANCELADO"

    public var descripcionOperativa: String {
        switch self {
        case .borrador: return "Cotización en edición inicial"
        case .pendienteAprobacion: return "Esperando validación comercial y de compatibilidad"
        case .aprobadoParaEnsamble: return "Componentes aprobados y reservados en bodega"
        case .enProcesoEnsamble: return "Montaje de hardware en banco de trabajo"
        case .pruebasYControlCalidad: return "Pruebas de estrés (AIDA64/FurMark) y balanceo de carga"
        case .listoParaDespacho: return "Empacado y listo para logística/entrega al cliente"
        case .entregado: return "Recibido a satisfacción por el cliente corporativo"
        case .cancelado: return "Cotización rechazada o cancelada"
        }
    }
}

/// Estructura de evento emitida a Firebase Realtime Database.
public struct ActualizacionEstadoCotizacion: Codable, Sendable {
    public let idCotizacion: String
    public let estado: EstadoCotizacion
    public let idEnsamblador: String
    public let nombreEnsamblador: String
    public let notasTecnicas: String?
    public let fechaActualizacion: Date
    public let timestampMilisegundos: Int64
    public let totalCotizacion: Double?

    public init(
        idCotizacion: String,
        estado: EstadoCotizacion,
        idEnsamblador: String,
        nombreEnsamblador: String,
        notasTecnicas: String? = nil,
        fechaActualizacion: Date = Date(),
        totalCotizacion: Double? = nil
    ) {
        self.idCotizacion = idCotizacion
        self.estado = estado
        self.idEnsamblador = idEnsamblador
        self.nombreEnsamblador = nombreEnsamblador
        self.notasTecnicas = notasTecnicas
        self.fechaActualizacion = fechaActualizacion
        self.timestampMilisegundos = Int64(fechaActualizacion.timeIntervalSince1970 * 1000)
        self.totalCotizacion = totalCotizacion
    }

    /// Diccionario para Realtime Database
    public var diccionarioRTDB: [String: Any] {
        var dict: [String: Any] = [
            "idCotizacion": idCotizacion,
            "estado": estado.rawValue,
            "idEnsamblador": idEnsamblador,
            "nombreEnsamblador": nombreEnsamblador,
            "fechaISO": ISO8601DateFormatter().string(from: fechaActualizacion),
            "timestamp": timestampMilisegundos
        ]
        if let notas = notasTecnicas {
            dict["notasTecnicas"] = notas
        }
        if let total = totalCotizacion {
            dict["totalCotizacion"] = total
        }
        return dict
    }
}

/// DTO para el tipo de cambio financiero aplicado a componentes de hardware importados.
public struct TipoCambioHardware: Codable, Sendable {
    public let monedaBase: String              // Ej: "USD"
    public let monedaDestino: String           // Ej: "MXN", "COP", "EUR"
    public let tasaCambio: Double              // Tasa spot nominal
    public let factorArancelarioHardware: Double // Margen de fluctuación e impuestos aduanales (ej: 1.04)
    public let tasaEfectiva: Double            // tasaCambio * factorArancelarioHardware
    public let fecha: Date
    public let proveedorMercado: String

    public init(
        monedaBase: String = "USD",
        monedaDestino: String = "MXN",
        tasaCambio: Double,
        factorArancelarioHardware: Double = 1.04,
        fecha: Date = Date(),
        proveedorMercado: String = "Banco Central Mock / Forex Hardware API"
    ) {
        self.monedaBase = monedaBase
        self.monedaDestino = monedaDestino
        self.tasaCambio = tasaCambio
        self.factorArancelarioHardware = factorArancelarioHardware
        self.tasaEfectiva = (tasaCambio * factorArancelarioHardware * 100).rounded() / 100
        self.fecha = fecha
        self.proveedorMercado = proveedorMercado
    }
}

// MARK: - 2. Errores Robustos de Red y Persistencia

public enum FirebaseServiceError: LocalizedError, Sendable {
    case sesionNoIniciada
    case errorAutenticacion(String)
    case datosPDFInvalidos
    case errorSubidaStorage(String)
    case errorRealtimeDatabase(String)
    case urlInvalida
    case errorRespuestaServidor(codigo: Int)
    case errorDecodificacion(String)
    case errorConexionRed(String)

    public var errorDescription: String? {
        switch self {
        case .sesionNoIniciada:
            return "No se ha encontrado una sesión activa para el usuario ensamblador."
        case .errorAutenticacion(let mensaje):
            return "Fallo en la autenticación con Firebase Auth: \(mensaje)"
        case .datosPDFInvalidos:
            return "El archivo PDF de la cotización está vacío o no contiene una estructura válida."
        case .errorSubidaStorage(let mensaje):
            return "Error al subir el comprobante a Firebase Storage: \(mensaje)"
        case .errorRealtimeDatabase(let mensaje):
            return "Error al actualizar el estado en Firebase Realtime Database: \(mensaje)"
        case .urlInvalida:
            return "La URL proporcionada para el servicio REST no es válida."
        case .errorRespuestaServidor(let codigo):
            return "El servidor REST respondió con un código HTTP inesperado: \(codigo)."
        case .errorDecodificacion(let detalle):
            return "Error al procesar la respuesta JSON del tipo de cambio: \(detalle)"
        case .errorConexionRed(let detalle):
            return "Error en la solicitud de red con URLSession: \(detalle)"
        }
    }
}

// MARK: - 3. Contratos de Servicio (Protocolos)

public protocol FirebaseServiceProtocol: Sendable {
    /// 1. Autenticación con Firebase Auth
    func autenticarEnsamblador(email: String, contrasena: String) async throws -> UsuarioEnsamblador
    func registrarEnsamblador(email: String, contrasena: String, nombre: String, rol: UsuarioEnsamblador.RolUsuario) async throws -> UsuarioEnsamblador
    func cerrarSesion() throws
    func obtenerEnsambladorActual() -> UsuarioEnsamblador?

    /// 2. Subida de PDF a Firebase Storage
    func subirComprobanteCotizacionPDF(
        datosPDF: Data,
        idCotizacion: String,
        nombreArchivo: String?
    ) async throws -> URL

    /// 3. Emisión de estado en Firebase Realtime Database
    func emitirEstadoCotizacion(_ actualizacion: ActualizacionEstadoCotizacion) async throws
    func emitirEstadoCotizacion(
        idCotizacion: String,
        nuevoEstado: EstadoCotizacion,
        notas: String?,
        total: Double?
    ) async throws
}

public protocol HardwareExchangeRateClientProtocol: Sendable {
    /// Cliente HTTP con async/await para consultar endpoint REST mock
    func consultarTipoCambioHardware(
        monedaBase: String,
        monedaDestino: String
    ) async throws -> TipoCambioHardware
}

// MARK: - 4. Implementación Principal de FirebaseService

/// Servicio de infraestructura para Firebase (Auth, Storage, Realtime Database)
/// Diseñado con aislamiento concurrente, soporte para SDK nativo de Firebase
/// y simulación resiliente para entornos de desarrollo y pruebas unitarias.
public final class FirebaseService: FirebaseServiceProtocol, @unchecked Sendable {

    public static let shared = FirebaseService()

    // Estado interno sincronizado para usuario actual
    private let lock = NSLock()
    private var _ensambladorEnSesion: UsuarioEnsamblador?

    public init() {
        #if canImport(FirebaseAuth)
        if let usuarioActual = Auth.auth().currentUser {
            self._ensambladorEnSesion = UsuarioEnsamblador(
                id: usuarioActual.uid,
                email: usuarioActual.email ?? "ensamblador@hardwarequote.b2b",
                nombre: usuarioActual.displayName ?? "Ensamblador B2B",
                rol: .ensambladorMaster
            )
        }
        #endif
    }

    // MARK: - 4.1 Firebase Auth: Autenticación del Ensamblador

    public func autenticarEnsamblador(email: String, contrasena: String) async throws -> UsuarioEnsamblador {
        guard !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              contrasena.count >= 6 else {
            throw FirebaseServiceError.errorAutenticacion("El correo debe ser válido y la contraseña tener al menos 6 caracteres.")
        }

        #if canImport(FirebaseAuth)
        do {
            let authResult = try await Auth.auth().signIn(withEmail: email, password: contrasena)
            let usuario = UsuarioEnsamblador(
                id: authResult.user.uid,
                email: authResult.user.email ?? email,
                nombre: authResult.user.displayName ?? email.components(separatedBy: "@").first ?? "Ensamblador",
                rol: .ensambladorMaster,
                fechaAutenticacion: Date()
            )
            lock.lock()
            self._ensambladorEnSesion = usuario
            lock.unlock()
            return usuario
        } catch {
            throw FirebaseServiceError.errorAutenticacion(error.localizedDescription)
        }
        #else
        // Simulación controlada para previsualización y testing antes de vincular el SDK via SPM
        try await Task.sleep(nanoseconds: 400_000_000) // Simulación de latencia de red (400ms)
        let usuarioSimulado = UsuarioEnsamblador(
            id: "ensamblador_\(UUID().uuidString.prefix(8).lowercased())",
            email: email,
            nombre: email.components(separatedBy: "@").first?.capitalized ?? "Ensamblador Certificado",
            rol: .ensambladorMaster,
            fechaAutenticacion: Date()
        )
        lock.lock()
        self._ensambladorEnSesion = usuarioSimulado
        lock.unlock()
        return usuarioSimulado
        #endif
    }

    public func registrarEnsamblador(
        email: String,
        contrasena: String,
        nombre: String,
        rol: UsuarioEnsamblador.RolUsuario = .ensambladorJunior
    ) async throws -> UsuarioEnsamblador {
        guard !email.isEmpty, contrasena.count >= 6 else {
            throw FirebaseServiceError.errorAutenticacion("Credenciales no válidas para registro de técnico.")
        }

        #if canImport(FirebaseAuth)
        do {
            let authResult = try await Auth.auth().createUser(withEmail: email, password: contrasena)
            let changeRequest = authResult.user.createProfileChangeRequest()
            changeRequest.displayName = nombre
            try await changeRequest.commitChanges()

            let nuevoUsuario = UsuarioEnsamblador(
                id: authResult.user.uid,
                email: email,
                nombre: nombre,
                rol: rol,
                fechaAutenticacion: Date()
            )
            lock.lock()
            self._ensambladorEnSesion = nuevoUsuario
            lock.unlock()
            return nuevoUsuario
        } catch {
            throw FirebaseServiceError.errorAutenticacion(error.localizedDescription)
        }
        #else
        try await Task.sleep(nanoseconds: 500_000_000)
        let usuarioNuevo = UsuarioEnsamblador(
            id: "ensamblador_\(UUID().uuidString.prefix(8).lowercased())",
            email: email,
            nombre: nombre,
            rol: rol,
            fechaAutenticacion: Date()
        )
        lock.lock()
        self._ensambladorEnSesion = usuarioNuevo
        lock.unlock()
        return usuarioNuevo
        #endif
    }

    public func cerrarSesion() throws {
        #if canImport(FirebaseAuth)
        do {
            try Auth.auth().signOut()
        } catch {
            throw FirebaseServiceError.errorAutenticacion("No se pudo cerrar sesión: \(error.localizedDescription)")
        }
        #endif
        lock.lock()
        self._ensambladorEnSesion = nil
        lock.unlock()
    }

    public func obtenerEnsambladorActual() -> UsuarioEnsamblador? {
        lock.lock()
        defer { lock.unlock() }
        return _ensambladorEnSesion
    }

    // MARK: - 4.2 Firebase Storage: Subida de Comprobante PDF de Cotización

    public func subirComprobanteCotizacionPDF(
        datosPDF: Data,
        idCotizacion: String,
        nombreArchivo: String? = nil
    ) async throws -> URL {
        guard !datosPDF.isEmpty else {
            throw FirebaseServiceError.datosPDFInvalidos
        }

        let ensamblador = obtenerEnsambladorActual()
        let timestamp = Int(Date().timeIntervalSince1970)
        let nombreFinal = nombreArchivo ?? "comprobante_\(idCotizacion)_\(timestamp).pdf"
        let rutaStorage = "cotizaciones/\(idCotizacion)/documentos/\(nombreFinal)"

        #if canImport(FirebaseStorage)
        do {
            let storageReference = Storage.storage().reference().child(rutaStorage)

            let metadata = StorageMetadata()
            metadata.contentType = "application/pdf"
            metadata.customMetadata = [
                "idCotizacion": idCotizacion,
                "subidoPor": ensamblador?.id ?? "desconocido",
                "emailEnsamblador": ensamblador?.email ?? "sin_email",
                "fechaSubida": ISO8601DateFormatter().string(from: Date())
            ]

            // Subida asíncrona mediante putDataAsync
            _ = try await storageReference.putDataAsync(datosPDF, metadata: metadata)
            let downloadURL = try await storageReference.downloadURL()
            return downloadURL
        } catch {
            throw FirebaseServiceError.errorSubidaStorage(error.localizedDescription)
        }
        #else
        // Simulación realista en caso de no compilar con el SDK enlazado
        try await Task.sleep(nanoseconds: 700_000_000)
        guard let urlSimulada = URL(string: "https://firebasestorage.googleapis.com/v0/b/hardwarequoteb2b.appspot.com/o/\(rutaStorage.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? rutaStorage)?alt=media&token=\(UUID().uuidString)") else {
            throw FirebaseServiceError.errorSubidaStorage("No se pudo construir la URL de descarga.")
        }
        return urlSimulada
        #endif
    }

    // MARK: - 4.3 Firebase Realtime Database: Emisión del Estado de la Cotización

    public func emitirEstadoCotizacion(_ actualizacion: ActualizacionEstadoCotizacion) async throws {
        #if canImport(FirebaseDatabase)
        do {
            let ref = Database.database().reference()
            let rutaCotizacion = ref.child("cotizaciones").child(actualizacion.idCotizacion)

            // Actualizar nodo estado actual y registrar historial cronológico
            let payload = actualizacion.diccionarioRTDB

            try await rutaCotizacion.child("estadoActual").setValue(payload)
            try await rutaCotizacion.child("historial").childByAutoId().setValue(payload)
        } catch {
            throw FirebaseServiceError.errorRealtimeDatabase(error.localizedDescription)
        }
        #else
        // Simulación asíncrona de escritura en base de datos en tiempo real
        try await Task.sleep(nanoseconds: 350_000_000)
        #endif
    }

    public func emitirEstadoCotizacion(
        idCotizacion: String,
        nuevoEstado: EstadoCotizacion,
        notas: String? = nil,
        total: Double? = nil
    ) async throws {
        guard let ensamblador = obtenerEnsambladorActual() else {
            throw FirebaseServiceError.sesionNoIniciada
        }

        let actualizacion = ActualizacionEstadoCotizacion(
            idCotizacion: idCotizacion,
            estado: nuevoEstado,
            idEnsamblador: ensamblador.id,
            nombreEnsamblador: ensamblador.nombre,
            notasTecnicas: notas,
            fechaActualizacion: Date(),
            totalCotizacion: total
        )

        try await emitirEstadoCotizacion(actualizacion)
    }
}

// MARK: - 5. Cliente HTTP Asíncrono (URLSession async/await) para Tipo de Cambio REST

/// Cliente REST liviano y desacoplado para consultar el tipo de cambio financiero en tiempo real.
public final class HardwareExchangeRateClient: HardwareExchangeRateClientProtocol, @unchecked Sendable {

    private let session: URLSession
    private let urlEndpointMock: URL
    private let decoder: JSONDecoder

    /// Inicializador con inyección de dependencias para tests unitarios y configuración de red.
    public init(
        session: URLSession = {
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 15.0
            configuration.timeoutIntervalForResource = 30.0
            configuration.waitsForConnectivity = true
            return URLSession(configuration: configuration)
        }(),
        endpointURL: URL? = URL(string: "https://api.mockhardwarequote.internal/v1/exchange-rates")
    ) {
        self.session = session
        self.urlEndpointMock = endpointURL ?? URL(string: "https://api.mockhardwarequote.internal/v1/exchange-rates")!

        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .iso8601
        self.decoder = jsonDecoder
    }

    /// Consulta asíncrona (async/await) para obtener la tasa de cambio entre dos divisas.
    public func consultarTipoCambioHardware(
        monedaBase: String = "USD",
        monedaDestino: String = "MXN"
    ) async throws -> TipoCambioHardware {
        var componentesURL = URLComponents(url: urlEndpointMock, resolvingAgainstBaseURL: true)
        componentesURL?.queryItems = [
            URLQueryItem(name: "base", value: monedaBase.uppercased()),
            URLQueryItem(name: "target", value: monedaDestino.uppercased())
        ]

        guard let urlSolicitud = componentesURL?.url else {
            throw FirebaseServiceError.urlInvalida
        }

        var solicitud = URLRequest(url: urlSolicitud)
        solicitud.httpMethod = "GET"
        solicitud.setValue("application/json", forHTTPHeaderField: "Accept")
        solicitud.setValue("HardwareQuoteB2B-iOS/1.0", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: solicitud)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw FirebaseServiceError.errorConexionRed("Respuesta no HTTP recibida.")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw FirebaseServiceError.errorRespuestaServidor(codigo: httpResponse.statusCode)
            }

            // Intento de decodificación del formato REST oficial
            do {
                let tipoCambio = try decoder.decode(TipoCambioHardware.self, from: data)
                return tipoCambio
            } catch {
                throw FirebaseServiceError.errorDecodificacion(error.localizedDescription)
            }

        } catch let serviceError as FirebaseServiceError {
            // Re-lanzar errores de validación de servicio
            throw serviceError
        } catch {
            // Resiliencia para entornos sin servidor local mock: genera cotización simulada y transparente
            #if DEBUG
            return generarTasaSimuladaResiliente(base: monedaBase, destino: monedaDestino)
            #else
            throw FirebaseServiceError.errorConexionRed(error.localizedDescription)
            #endif
        }
    }

    /// Generador de contingencia para ambiente de pruebas locales o previsualización offline en SwiftUI.
    private func generarTasaSimuladaResiliente(base: String, destino: String) -> TipoCambioHardware {
        let tasasBase: [String: Double] = [
            "MXN": 19.82,
            "COP": 4150.00,
            "EUR": 0.92,
            "CLP": 940.00,
            "USD": 1.00
        ]

        let tasaNominal = tasasBase[destino.uppercased()] ?? 20.00
        return TipoCambioHardware(
            monedaBase: base.uppercased(),
            monedaDestino: destino.uppercased(),
            tasaCambio: tasaNominal,
            factorArancelarioHardware: 1.05, // 5% arancel estimado para GPU/CPU
            fecha: Date(),
            proveedorMercado: "Mock REST Local Fallback (Forex Hardware B2B)"
        )
    }
}
