import Foundation

extension Decimal {
    /// Redondea a `decimales` posiciones (2 por defecto, centavos) con redondeo comercial.
    func redondeado(_ decimales: Int = 2) -> Decimal {
        var origen = self
        var resultado = Decimal()
        NSDecimalRound(&resultado, &origen, decimales, .plain)
        return resultado
    }

    /// Solo para APIs que exigen `Double` (CoreData, Firebase, animaciones). No usar para calcular.
    var aDouble: Double {
        NSDecimalNumber(decimal: self).doubleValue
    }

    var aNSNumber: NSNumber {
        NSDecimalNumber(decimal: self)
    }

    /// Texto con 2 decimales y sin símbolo de moneda (ej. "1,234.50").
    var textoDosDecimales: String {
        formatted(.number.precision(.fractionLength(2)))
    }
}
