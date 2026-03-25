import SwiftUI
import Speech

struct IntentionInputView: View {
    @Binding var text: String
    let onSubmit: () -> Void

    @State private var isRecording: Bool = false
    @State private var characterCount: Int = 0
    @State private var showVoiceUnavailable: Bool = false

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
                Button(action: toggleVoiceInput) {
                    Image(systemName: isRecording ? "stop.circle.fill" : "mic.fill")
                        .font(.system(size: 22))
                        .foregroundColor(isRecording ? Theme.warning : Theme.goldMuted)
                }
                .opacity(showVoiceUnavailable ? 0 : 1)
                .disabled(showVoiceUnavailable)

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

    private func toggleVoiceInput() {
        isRecording.toggle()
        // Voice input would be implemented here with SFSpeechRecognizer
        // For now, just toggle state
        if isRecording {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                isRecording = false
            }
        }
    }

    private func checkVoiceAvailability() {
        showVoiceUnavailable = false
    }
}
