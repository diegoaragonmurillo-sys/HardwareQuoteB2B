//
//  ControlNotasVozView.swift
//  HardwareQuoteB2B
//
//  Componente SwiftUI para grabación y reproducción de notas de voz técnicas B2B.
//

import SwiftUI

struct ControlNotasVozView: View {
    @State private var voiceManager = VoiceNoteManager()
    let accentColor: Color

    init(accentColor: Color = Color(red: 0.20, green: 0.34, blue: 0.55)) {
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("NOTA DE VOZ TÉCNICA", systemImage: "waveform")
                    .font(.caption2.weight(.semibold))
                    .tracking(1.1)
                    .foregroundStyle(.secondary)

                Spacer()

                if voiceManager.estaGrabando {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 7, height: 7)
                        Text(voiceManager.formatearTiempo(voiceManager.duracionSegundos))
                            .font(.caption.monospacedDigit().weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
            }

            HStack(spacing: 12) {
                Button {
                    withAnimation(.snappy(duration: 0.25)) {
                        voiceManager.alternarGrabacion()
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: voiceManager.estaGrabando ? "stop.fill" : "mic.fill")
                            .font(.subheadline.weight(.semibold))
                        Text(voiceManager.estaGrabando ? "Detener" : (voiceManager.urlNotaActual == nil ? "Grabar Nota" : "Regrabar"))
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        voiceManager.estaGrabando ? Color.red : accentColor,
                        in: Capsule()
                    )
                }
                .buttonStyle(.plain)

                if voiceManager.urlNotaActual != nil && !voiceManager.estaGrabando {
                    Button {
                        voiceManager.alternarReproduccion()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: voiceManager.estaReproduciendo ? "stop.fill" : "play.fill")
                                .font(.caption.weight(.semibold))
                            Text(voiceManager.estaReproduciendo ? "Parar" : "Escuchar")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(accentColor.opacity(0.12), in: Capsule())
                    }
                    .buttonStyle(.plain)

                    Button(role: .destructive) {
                        withAnimation(.snappy(duration: 0.2)) {
                            voiceManager.eliminarNota()
                        }
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(10)
                            .background(Color.red.opacity(0.10), in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Eliminar nota de voz")
                }

                Spacer()
            }

            Text(voiceManager.mensajeEstado)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
        )
    }
}
