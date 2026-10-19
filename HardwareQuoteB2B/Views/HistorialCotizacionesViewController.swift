//
//  HistorialCotizacionesViewController.swift
//  HardwareQuoteB2B
//
//  Created as part of the B2B Hardware Quoting Platform.
//  Specialist: iOS Architecture, CoreData & Realtime Database Sync.
//

import UIKit
import CoreData

final class HistorialCotizacionesViewController: UITableViewController {

    // MARK: - Identificador de Celda
    private let reuseIdentifier = "celda"

    // MARK: - Fuente de Datos desde HistorialManager
    private var cotizaciones: [NSManagedObject] {
        HistorialManager.shared.cotizaciones
    }

    // Formateador de moneda reutilizable
    private let formateadorMoneda: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configurarObservadores()
        recargarHistorial()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        recargarHistorial()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Configuración de Interfaz
    private func setupUI() {
        title = "Historial de Cotizaciones"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground

        // Control de actualización por arrastre (Pull to Refresh)
        refreshControl = UIRefreshControl()
        refreshControl?.attributedTitle = NSAttributedString(string: "Actualizando cotizaciones...")
        refreshControl?.addTarget(self, action: #selector(recargarHistorial), for: .valueChanged)

        tableView.tableFooterView = UIView()
    }

    private func configurarObservadores() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(recargarHistorial),
            name: .historialCotizacionesActualizado,
            object: nil
        )
    }

    // MARK: - Lectura desde HistorialManager
    @objc private func recargarHistorial() {
        HistorialManager.shared.recuperarCotizaciones()
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.tableView.reloadData()
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if cotizaciones.isEmpty {
            mostrarMensajeVacio()
        } else {
            tableView.backgroundView = nil
        }
        return cotizaciones.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuseIdentifier)

        let cotizacion = cotizaciones[indexPath.row]

        let cliente = cotizacion.value(forKey: "cliente") as? String ?? "Cliente Sin Nombre"
        let monto = cotizacion.value(forKey: "montoTotal") as? Double ?? 0.0
        let fecha = cotizacion.value(forKey: "fecha") as? Date ?? Date()

        cell.textLabel?.text = cliente
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        cell.textLabel?.textColor = .label

        let strMonto = formateadorMoneda.string(from: NSNumber(value: monto)) ?? "$\(monto)"
        let strFecha = DateFormatter.localizedString(from: fecha, dateStyle: .medium, timeStyle: .short)
        cell.detailTextLabel?.text = "\(strMonto) • \(strFecha)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 13, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel

        cell.imageView?.image = UIImage(systemName: "doc.text.fill")
        cell.imageView?.tintColor = UIColor(red: 0.20, green: 0.34, blue: 0.55, alpha: 1.0)
        cell.accessoryType = .disclosureIndicator

        return cell
    }

    // MARK: - Eliminación Atómica Segura (Sin colisión con reloadData)
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        HistorialManager.shared.eliminarCotizacion(en: indexPath.row) { [weak self] eliminado in
            guard let self, eliminado else { return }
            tableView.performBatchUpdates({
                tableView.deleteRows(at: [indexPath], with: .fade)
            }, completion: { [weak self] _ in
                guard let self else { return }
                if self.cotizaciones.isEmpty {
                    self.mostrarMensajeVacio()
                }
            })
        }
    }

    // MARK: - Ayudantes Visuales
    private func mostrarMensajeVacio() {
        let label = UILabel()
        label.text = "No hay cotizaciones registradas.\nEmite una propuesta formal desde el Cotizador B2B."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.textColor = .tertiaryLabel
        tableView.backgroundView = label
    }
}
