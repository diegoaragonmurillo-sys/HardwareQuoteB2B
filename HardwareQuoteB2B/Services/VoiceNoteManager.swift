//
//  VoiceNoteManager.swift
//  HardwareQuoteB2B
//
//  Gestor de grabación y reproducción de notas de voz técnicas con AVFoundation.
//

import AVFoundation
import Foundation
import Observation

@Observable
final class VoiceNoteManager: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    var estaGrabando = false
    var estaReproduciendo = false
    var urlNotaActual: URL?
    var duracionSegundos: Int = 0
    var mensajeEstado: String = "Listo para grabar especificaciones"

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?

    deinit {
        timer?.invalidate()
        audioRecorder?.stop()
        audioPlayer?.stop()
    }

    func alternarGrabacion() {
        if estaGrabando {
            detenerGrabacion()
        } else {
            solicitarPermisoYGrabar()
        }
    }

    // MARK: - Chequeo Preventivo de Autorización y Plist (TCC)
    private func solicitarPermisoYGrabar() {
        // Verificación defensiva de la clave TCC en el Bundle antes de invocar AVAudioSession
        guard Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil else {
            mensajeEstado = "Configuración faltante: NSMicrophoneUsageDescription en Info.plist"
            return
        }

        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .granted:
                iniciarGrabacion()
            case .denied:
                mensajeEstado = "Permiso de micrófono denegado en Configuración"
            case .undetermined:
                AVAudioApplication.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        if granted {
                            self.iniciarGrabacion()
                        } else {
                            self.mensajeEstado = "Se requiere acceso al micrófono"
                        }
                    }
                }
            @unknown default:
                mensajeEstado = "Estado de micrófono no disponible"
            }
        } else {
            let session = AVAudioSession.sharedInstance()
            switch session.recordPermission {
            case .granted:
                iniciarGrabacion()
            case .denied:
                mensajeEstado = "Permiso de micrófono denegado en Configuración"
            case .undetermined:
                session.requestRecordPermission { [weak self] granted in
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        if granted {
                            self.iniciarGrabacion()
                        } else {
                            self.mensajeEstado = "Se requiere acceso al micrófono"
                        }
                    }
                }
            @unknown default:
                mensajeEstado = "Estado de micrófono no disponible"
            }
        }
    }

    private func iniciarGrabacion() {
        detenerReproduccion()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let tempDir = FileManager.default.temporaryDirectory
            let fileURL = tempDir.appendingPathComponent("NotaTecnicaB2B_\(Int(Date().timeIntervalSince1970)).m4a")

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()

            urlNotaActual = fileURL
            estaGrabando = true
            duracionSegundos = 0
            mensajeEstado = "Grabando nota técnica..."

            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                guard let self else { return }
                self.duracionSegundos += 1
            }
        } catch {
            mensajeEstado = "Error al iniciar grabación"
            print("❌ Error en VoiceNoteManager: \(error.localizedDescription)")
        }
    }

    func detenerGrabacion() {
        audioRecorder?.stop()
        audioRecorder = nil
        estaGrabando = false
        timer?.invalidate()
        timer = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        mensajeEstado = "Nota de voz adjunta (\(formatearTiempo(duracionSegundos)))"
    }

    func alternarReproduccion() {
        if estaReproduciendo {
            detenerReproduccion()
        } else {
            reproducirNota()
        }
    }

    private func reproducirNota() {
        guard let url = urlNotaActual else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.play()
            estaReproduciendo = true
            mensajeEstado = "Reproduciendo nota técnica..."
        } catch {
            mensajeEstado = "No se pudo reproducir el audio"
        }
    }

    func detenerReproduccion() {
        audioPlayer?.stop()
        audioPlayer = nil
        estaReproduciendo = false
        if urlNotaActual != nil {
            mensajeEstado = "Nota de voz adjunta (\(formatearTiempo(duracionSegundos)))"
        }
    }

    func eliminarNota() {
        detenerReproduccion()
        if let url = urlNotaActual {
            try? FileManager.default.removeItem(at: url)
        }
        urlNotaActual = nil
        duracionSegundos = 0
        mensajeEstado = "Listo para grabar especificaciones"
    }

    func formatearTiempo(_ segundos: Int) -> String {
        let mins = segundos / 60
        let secs = segundos % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.estaReproduciendo = false
            self.mensajeEstado = "Nota de voz adjunta (\(self.formatearTiempo(self.duracionSegundos)))"
        }
    }
}
