import Foundation

/// Tasas de cambio con base USD obtenidas de la API.
struct TasasCambioUSD: Equatable, Sendable {
    let mxn: Double
    let pen: Double
    let fechaActualizacion: Date
}

protocol TipoCambioServicing: Sendable {
    func obtenerTasas() async throws -> TasasCambioUSD
}

enum TipoCambioError: Error, Equatable {
    case respuestaInvalida
    case monedaNoDisponible(String)
}

/// Cliente de la API pública y gratuita https://open.er-api.com (sin API key).
struct TipoCambioService: TipoCambioServicing {
    private struct Respuesta: Decodable {
        let result: String
        let timeLastUpdateUnix: TimeInterval
        let rates: [String: Double]

        enum CodingKeys: String, CodingKey {
            case result
            case timeLastUpdateUnix = "time_last_update_unix"
            case rates
        }
    }

    private let session: URLSession
    private let url: URL

    init(
        session: URLSession = .shared,
        url: URL = URL(string: "https://open.er-api.com/v6/latest/USD")!
    ) {
        self.session = session
        self.url = url
    }

    func obtenerTasas() async throws -> TasasCambioUSD {
        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw TipoCambioError.respuestaInvalida
        }
        return try Self.decodificar(data)
    }

    static func decodificar(_ data: Data) throws -> TasasCambioUSD {
        let respuesta = try JSONDecoder().decode(Respuesta.self, from: data)
        guard respuesta.result == "success" else { throw TipoCambioError.respuestaInvalida }
        guard let mxn = respuesta.rates["MXN"] else { throw TipoCambioError.monedaNoDisponible("MXN") }
        guard let pen = respuesta.rates["PEN"] else { throw TipoCambioError.monedaNoDisponible("PEN") }
        return TasasCambioUSD(
            mxn: mxn,
            pen: pen,
            fechaActualizacion: Date(timeIntervalSince1970: respuesta.timeLastUpdateUnix)
        )
    }
}
