//
//  DetalleComponenteViewController.swift
//  HardwareQuoteB2B
//

import UIKit

final class DetalleComponenteViewController: UIViewController {
    var componente: Componente?

    @IBOutlet weak var nombreLabel: UILabel!
    @IBOutlet weak var categoriaLabel: UILabel!
    @IBOutlet weak var precioLabel: UILabel!
    @IBOutlet weak var socketLabel: UILabel!
    @IBOutlet weak var consumoWattsLabel: UILabel!
    @IBOutlet weak var stockLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        guard let componente = componente else { return }
        title = componente.nombre
        nombreLabel?.text = componente.nombre
        categoriaLabel?.text = componente.categoria.rawValue
        precioLabel?.text = String(format: "$%.2f", componente.precioBase)
        socketLabel?.text = componente.socket ?? "N/A"
        consumoWattsLabel?.text = "\(componente.consumoWatts) W"
        stockLabel?.text = "\(componente.stock) unidades"
    }
}
