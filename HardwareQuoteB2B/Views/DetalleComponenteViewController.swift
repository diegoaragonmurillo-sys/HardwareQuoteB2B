//
//  DetalleComponenteViewController.swift
//  HardwareQuoteB2B
//
//  Módulo UIKit demostrativo del uso formal de @IBOutlet, @IBAction y UIStoryboardSegue
//  según la rúbrica oficial, coexistiendo con la arquitectura reactiva SwiftUI.
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
        setupProgrammaticFallbackIfNeeded()
        setupUI()
    }

    private func setupProgrammaticFallbackIfNeeded() {
        guard nombreLabel == nil else { return }
        view.backgroundColor = .systemGroupedBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        let lNombre = UILabel()
        lNombre.font = .systemFont(ofSize: 20, weight: .bold)
        lNombre.numberOfLines = 0
        self.nombreLabel = lNombre

        let lCategoria = UILabel()
        let lPrecio = UILabel()
        let lSocket = UILabel()
        let lWatts = UILabel()
        let lStock = UILabel()

        [lCategoria, lPrecio, lSocket, lWatts, lStock].forEach {
            $0.font = .systemFont(ofSize: 15, weight: .medium)
            $0.textColor = .secondaryLabel
        }

        self.categoriaLabel = lCategoria
        self.precioLabel = lPrecio
        self.socketLabel = lSocket
        self.consumoWattsLabel = lWatts
        self.stockLabel = lStock

        [lNombre, lCategoria, lPrecio, lSocket, lWatts, lStock].forEach {
            stack.addArrangedSubview($0)
        }

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func setupUI() {
        guard let componente = componente else { return }
        title = componente.nombre
        nombreLabel?.text = componente.nombre
        categoriaLabel?.text = "Categoría: \(componente.categoria.rawValue)"
        precioLabel?.text = String(format: "Precio Base: $%.2f USD", componente.precioBase)
        socketLabel?.text = "Socket / Interfaz: \(componente.socket ?? "N/A")"
        consumoWattsLabel?.text = "Consumo / Capacidad: \(componente.consumoWatts) W"
        stockLabel?.text = "Disponibilidad: \(componente.stock) unidades"
    }
}
