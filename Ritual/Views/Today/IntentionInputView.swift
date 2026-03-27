import SwiftUI
import Speech
import AVFoundation

struct IntentionInputView: View {
    @Binding var text: String
    let onSubmit: () -> Void

    @State private var isRecording: Bool = false
    @State private var characterCount: Int = 0
    @State private var showVoiceUnavailable: Bool = false
    @State private var showPermissionAlert: Bool = false
    @State private var permissionDeniedMessage: String = ""

    private let maxCharacters = 140
    private let warningThreshold = 120

    var body: some View {
        VStack(spacing: Theme.spacingM) {
            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .font(.system(size: 20, weight: .regular, design: .serif))
                    .foregroundColor(Theme.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(Theme.spacingS)
                    .background(Theme.surface)
                    .cornerRadius(Theme.cardRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cardRadius)
                            .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: text) { _, newValue in
                        if newValue.count > maxCharacters {
                            text = String(newValue.prefix(maxCharacters))
                        }
                        characterCount = text.count
                    }

                if text.isEmpty {
                    Text("Today, I intend to...")
                        .font(.system(size: 20, weight: .regular, design: .serif))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, Theme.spacingS + 5)
                        .padding(.vertical, Theme.spacingS + 8)
                        .allowsHitTesting(false)
                }
            }

            HStack {
                Button(action: { HapticFeedback.selection(); handleMicTap() }) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isRecording ? Theme.warning : Theme.goldMuted)
                }
                .accessibilityLabel(isRecording ? "Stop voice recording" : "Start voice recording")
                .opacity(showVoiceUnavailable ? 0 : 1)
                .disabled(showVoiceUnavailable)
                .alert("Voice Input Unavailable", isPresented: $showPermissionAlert) {
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text(permissionDeniedMessage)
                }

                Spacer()

                Text("\(characterCount)/\(maxCharacters)")
                    .font(.system(size: 13))
                    .foregroundColor(characterCount >= warningThreshold ? Theme.warning : Theme.textMuted)
            }

            PrimaryButton(
                title: "Hold This Intention",
                action: onSubmit,
                isEnabled: !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            )
        }
        .padding(.horizontal, Theme.spacingM)
        .onAppear {
            checkVoiceAvailability()
        }
    }

    private func handleMicTap() {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            toggleVoiceInput()
        case .notDetermined:
            requestSpeechPermission()
        case .denied, .restricted:
            showPermissionDeniedAlert(for: status)
        @unknown default:
            showVoiceUnavailable = true
        }
    }

    private func toggleVoiceInput() {
        isRecording.toggle()
        if isRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isRecording = false
            }
        }
    }

    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { [self] status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    toggleVoiceInput()
                case .denied, .restricted:
                    showPermissionDeniedAlert(for: status)
                case .notDetermined:
                    showVoiceUnavailable = true
                @unknown default:
                    showVoiceUnavailable = true
                }
            }
        }
    }

    private func showPermissionDeniedAlert(for status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .denied:
            permissionDeniedMessage = "Voice input requires microphone and speech recognition access. Please enable them in Settings."
        case .restricted:
            permissionDeniedMessage = "Voice input is restricted on this device."
        default:
            permissionDeniedMessage = "Voice input is not available."
        }
        showPermissionAlert = true
    }

    private func checkVoiceAvailability() {
        let recognizer = SFSpeechRecognizer()
        let micPermission = AVAudioApplication.shared.recordPermission

        if micPermission == .denied {
            showVoiceUnavailable = true
        } else if recognizer?.isAvailable == false {
            showVoiceUnavailable = true
        } else {
            showVoiceUnavailable = false
        }
    }
}
