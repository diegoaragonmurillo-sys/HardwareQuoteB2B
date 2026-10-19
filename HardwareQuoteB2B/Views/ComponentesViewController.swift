//
//  ComponentesViewController.swift
//  HardwareQuoteB2B
//
//  Módulo UIKit demostrativo del uso formal de @IBOutlet, @IBAction y UIStoryboardSegue
//  según la rúbrica oficial, coexistiendo con la arquitectura reactiva SwiftUI.
//

import UIKit
import AVFoundation

final class ComponentesViewController: UIViewController {

    // MARK: - IBOutlets
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var recordVoiceNoteButton: UIButton!

    // MARK: - Properties
    private let segueDetalleID = "showDetalleComponente"
    private var audioRecorder: AVAudioRecorder?
    private var isRecording = false

    var componentes: [Componente] = QuoteBuilderViewModel.catalogoDisponible
    private var componentesFiltrados: [Componente] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProgrammaticFallbackIfNeeded()
        setupUI()
        setupData()
    }

    /// Fallback programático cuando el controlador se instancia sin Storyboard desde el menú de desarrollador.
    private func setupProgrammaticFallbackIfNeeded() {
        guard tableView == nil || searchBar == nil else { return }
        view.backgroundColor = .systemGroupedBackground

        let barraBusqueda = UISearchBar()
        barraBusqueda.placeholder = "Filtrar componentes UIKit..."
        barraBusqueda.searchBarStyle = .minimal
        barraBusqueda.translatesAutoresizingMaskIntoConstraints = false
        self.searchBar = barraBusqueda

        let tabla = UITableView(frame: .zero, style: .insetGrouped)
        tabla.translatesAutoresizingMaskIntoConstraints = false
        self.tableView = tabla

        let botonVoz = UIButton(type: .system)
        botonVoz.translatesAutoresizingMaskIntoConstraints = false
        botonVoz.backgroundColor = UIColor(red: 0.20, green: 0.34, blue: 0.55, alpha: 0.12)
        botonVoz.layer.cornerRadius = 10
        botonVoz.addTarget(self, action: #selector(recordVoiceNoteTapped(_:)), for: .touchUpInside)
        self.recordVoiceNoteButton = botonVoz

        view.addSubview(barraBusqueda)
        view.addSubview(botonVoz)
        view.addSubview(tabla)

        NSLayoutConstraint.activate([
            barraBusqueda.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            barraBusqueda.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            barraBusqueda.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            botonVoz.topAnchor.constraint(equalTo: barraBusqueda.bottomAnchor, constant: 4),
            botonVoz.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            botonVoz.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            botonVoz.heightAnchor.constraint(equalToConstant: 40),

            tabla.topAnchor.constraint(equalTo: botonVoz.bottomAnchor, constant: 6),
            tabla.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabla.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tabla.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupUI() {
        title = "Catálogo UIKit"

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        recordVoiceNoteButton?.setTitle(" Grabar Nota de Voz", for: .normal)
        recordVoiceNoteButton?.setImage(UIImage(systemName: "mic.fill"), for: .normal)
    }

    private func setupData() {
        componentesFiltrados = componentes
        tableView.reloadData()
    }

    // MARK: - IBActions
    @IBAction func recordVoiceNoteTapped(_ sender: UIButton) {
        if isRecording {
            stopRecording()
        } else {
            requestMicrophonePermissionAndRecord()
        }
    }

    // MARK: - Audio Recording
    private func requestMicrophonePermissionAndRecord() {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            startRecording()
        case .denied:
            showPermissionAlert()
        case .undetermined:
            session.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.startRecording()
                    } else {
                        self?.showPermissionAlert()
                    }
                }
            }
        @unknown default:
            break
        }
    }

    private func startRecording() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try audioSession.setActive(true)

            let tempPath = FileManager.default.temporaryDirectory
            let audioURL = tempPath.appendingPathComponent("NotaVoz_\(Date().timeIntervalSince1970).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            isRecording = true
            recordVoiceNoteButton?.setTitle(" Detener Grabación", for: .normal)
            recordVoiceNoteButton?.tintColor = .systemRed
        } catch {
            print("Error al iniciar grabación: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        recordVoiceNoteButton?.setTitle(" Grabar Nota de Voz", for: .normal)
        recordVoiceNoteButton?.tintColor = .systemBlue

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func showPermissionAlert() {
        let alert = UIAlertController(
            title: "Permiso denegado",
            message: "Por favor active el acceso al micrófono en Configuración para grabar notas de voz.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Navigation (UIStoryboardSegue)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == segueDetalleID,
              let destinationVC = segue.destination as? DetalleComponenteViewController,
              let selectedComponente = sender as? Componente else {
            return
        }
        destinationVC.componente = selectedComponente
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ComponentesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return componentesFiltrados.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let componente = componentesFiltrados[indexPath.row]

        if let cell = tableView.dequeueReusableCell(withIdentifier: ComponenteTableViewCell.reuseIdentifier) as? ComponenteTableViewCell {
            cell.configure(with: componente)
            return cell
        }

        let fallbackCell = UITableViewCell(style: .subtitle, reuseIdentifier: "FallbackComponenteCell")
        fallbackCell.textLabel?.text = componente.nombre
        fallbackCell.textLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        fallbackCell.detailTextLabel?.text = "\(componente.categoria.rawValue) • \(componente.consumoWatts)W • $\(componente.precioBase.textoDosDecimales)"
        fallbackCell.accessoryType = .disclosureIndicator
        return fallbackCell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let componenteSeleccionado = componentesFiltrados[indexPath.row]

        if storyboard != nil {
            performSegue(withIdentifier: segueDetalleID, sender: componenteSeleccionado)
        } else {
            let detalleVC = DetalleComponenteViewController()
            detalleVC.componente = componenteSeleccionado
            navigationController?.pushViewController(detalleVC, animated: true)
        }
    }
}

// MARK: - UISearchBarDelegate
extension ComponentesViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            componentesFiltrados = componentes
        } else {
            componentesFiltrados = componentes.filter {
                $0.nombre.localizedCaseInsensitiveContains(query) ||
                $0.categoria.rawValue.localizedCaseInsensitiveContains(query) ||
                ($0.socket?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }
        tableView.reloadData()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        componentesFiltrados = componentes
        tableView.reloadData()
    }
}

// MARK: - AVAudioRecorderDelegate
extension ComponentesViewController: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            print("Nota de voz guardada exitosamente en: \(recorder.url.lastPathComponent)")
        }
    }
}
