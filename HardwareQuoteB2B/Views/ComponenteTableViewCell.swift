//
//  ComponenteTableViewCell.swift
//  HardwareQuoteB2B
//

import UIKit

final class ComponenteTableViewCell: UITableViewCell {
    static let reuseIdentifier = "ComponenteTableViewCell"

    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var categoriaLabel: UILabel!
    @IBOutlet weak var precioLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!
    @IBOutlet weak var especificacionesLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .default
    }

    func configure(with componente: Componente) {
        nombreLabel?.text = componente.nombre
        categoriaLabel?.text = componente.categoria.rawValue
        precioLabel?.text = String(format: "$%.2f", componente.precioBase)
        stockLabel?.text = "Stock: \(componente.stock)"

        var specs = "\(componente.consumoWatts)W"
        if let socket = componente.socket, !socket.isEmpty {
            specs += " • Socket: \(socket)"
        }
        especificacionesLabel?.text = specs
    }
}
