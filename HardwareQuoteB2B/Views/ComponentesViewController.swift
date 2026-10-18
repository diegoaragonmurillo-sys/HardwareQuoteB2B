//
//  ComponentesViewController.swift
//  HardwareQuoteB2B
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

    var componentes: [Componente] = []
    private var componentesFiltrados: [Componente] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupData()
    }

    private func setupUI() {
        title = "Catálogo de Componentes"
        
        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        recordVoiceNoteButton?.setTitle("Grabar Nota de Voz", for: .normal)
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

            let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let audioURL = documentPath.appendingPathComponent("NotaVoz_\(Date().timeIntervalSince1970).m4a")

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
            recordVoiceNoteButton?.setTitle("Detener Grabación", for: .normal)
            recordVoiceNoteButton?.tintColor = .systemRed
        } catch {
            print("Error al iniciar grabación: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false

        recordVoiceNoteButton?.setTitle("Grabar Nota de Voz", for: .normal)
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

    // MARK: - Navigation
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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: ComponenteTableViewCell.reuseIdentifier,
            for: indexPath
        ) as? ComponenteTableViewCell else {
            return UITableViewCell()
        }

        let componente = componentesFiltrados[indexPath.row]
        cell.configure(with: componente)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let componenteSeleccionado = componentesFiltrados[indexPath.row]
        performSegue(withIdentifier: segueDetalleID, sender: componenteSeleccionado)
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
