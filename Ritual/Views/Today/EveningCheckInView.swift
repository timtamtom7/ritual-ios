import SwiftUI

struct EveningCheckInView: View {
    let onComplete: (Bool, String?) -> Void
    let onDismiss: () -> Void

    @State private var selectedAnswer: Bool?
    @State private var reflectionText: String = ""
    @State private var showReflection: Bool = false

    var body: some View {
        VStack(spacing: Theme.spacingL) {
            if !showReflection {
                questionView
            } else {
                reflectionView
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showReflection)
    }

    private var questionView: some View {
        VStack(spacing: Theme.spacingL) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 40))
                .foregroundColor(Theme.goldPrimary)

            Text("Evening Check-In")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)

            Text("Did you act on your intention today?")
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)

            Spacer()

            HStack(spacing: Theme.spacingM) {
                CheckInButton(title: "Yes", isSelected: selectedAnswer == true) {
                    selectedAnswer = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onComplete(true, nil)
                    }
                }

                CheckInButton(title: "Not Quite", isSelected: selectedAnswer == false) {
                    selectedAnswer = false
                    withAnimation {
                        showReflection = true
                    }
                }
            }
            .padding(.horizontal, Theme.spacingM)

            Spacer()
        }
    }

    private var reflectionView: some View {
        VStack(spacing: Theme.spacingL) {
            Text("What got in the way?")
                .font(.system(size: 24, weight: .regular, design: .serif))
                .foregroundColor(Theme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.top, Theme.spacingXL)

            Spacer()

            ReflectionInputView(text: $reflectionText)
                .padding(.horizontal, Theme.spacingM)

            Spacer()

            PrimaryButton(
                title: reflectionText.isEmpty ? "Skip" : "Save Reflection",
                action: {
                    onComplete(false, reflectionText.isEmpty ? nil : reflectionText)
                }
            )
            .padding(.horizontal, Theme.spacingM)
            .padding(.bottom, Theme.spacingM)
        }
    }
}

struct ReflectionInputView: View {
    @Binding var text: String

    private let maxCharacters = 280

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.system(size: 17))
                .foregroundColor(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 100)
                .padding(Theme.spacingS)
                .background(Theme.surface)
                .cornerRadius(Theme.buttonRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.buttonRadius)
                        .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
                )
                .onChange(of: text) { _, newValue in
                    if newValue.count > maxCharacters {
                        text = String(newValue.prefix(maxCharacters))
                    }
                }

            if text.isEmpty {
                Text("What got in the way?")
                    .font(.system(size: 17))
                    .foregroundColor(Theme.textMuted)
                    .padding(.horizontal, Theme.spacingS + 5)
                    .padding(.vertical, Theme.spacingS + 8)
                    .allowsHitTesting(false)
            }
        }
    }
}
