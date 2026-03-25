import SwiftUI

struct TemplateCreatorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String = ""
    @State private var selectedCategory: String = "Growth"
    @State private var templateDescription: String = ""
    @State private var example: String = ""
    @State private var showShareSheet: Bool = false
    @State private var showSavedToast: Bool = false
    @State private var shareText: String = ""

    private let categories = ["Work", "Health", "Relationships", "Growth", "Other"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        VStack(spacing: Theme.spacingS) {
                            Text("Shape your practice")
                                .font(.system(size: 20, weight: .regular, design: .serif))
                                .foregroundColor(Theme.textPrimary)

                            Text("Create a template to guide your daily intentions")
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, Theme.spacingS)

                        // Title
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Template Name")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            TextField("e.g., Morning Focus Ritual", text: $title)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textPrimary)
                                .padding(Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(Theme.buttonRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.buttonRadius)
                                        .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Category
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Category")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: Theme.spacingS) {
                                    ForEach(categories, id: \.self) { cat in
                                        CategoryPickerChip(
                                            title: cat,
                                            icon: IntentionCategory(rawValue: cat)?.icon ?? "sparkle",
                                            isSelected: selectedCategory == cat
                                        ) {
                                            selectedCategory = cat
                                        }
                                    }
                                }
                            }
                        }

                        // Description
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Description")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            TextField("What is this template about?", text: $templateDescription)
                                .font(.system(size: 16))
                                .foregroundColor(Theme.textPrimary)
                                .padding(Theme.spacingM)
                                .background(Theme.surface)
                                .cornerRadius(Theme.buttonRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.buttonRadius)
                                        .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
                                )
                        }

                        // Example
                        VStack(alignment: .leading, spacing: Theme.spacingS) {
                            Text("Example Intention")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Theme.textMuted)

                            ZStack(alignment: .topLeading) {
                                TextEditor(text: $example)
                                    .font(.system(size: 16, design: .serif))
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

                                if example.isEmpty {
                                    Text("Today, I intend to...")
                                        .font(.system(size: 16, design: .serif))
                                        .foregroundColor(Theme.textMuted)
                                        .padding(.horizontal, Theme.spacingS + 5)
                                        .padding(.vertical, Theme.spacingS + 8)
                                        .allowsHitTesting(false)
                                }
                            }
                        }

                        Spacer().frame(height: Theme.spacingM)

                        // Action Buttons
                        VStack(spacing: Theme.spacingM) {
                            Button(action: saveTemplate) {
                                HStack {
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.system(size: 14))
                                    Text("Save Template")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(Theme.background)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isFormValid ? Theme.goldPrimary : Theme.textMuted)
                                .cornerRadius(Theme.buttonRadius)
                            }
                            .disabled(!isFormValid)

                            Button(action: shareTemplate) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 14))
                                    Text("Share Template")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(Theme.goldPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Theme.goldPrimary.opacity(0.1))
                                .cornerRadius(Theme.buttonRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Theme.buttonRadius)
                                        .stroke(Theme.goldPrimary.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .disabled(!isFormValid)
                        }
                        .padding(.horizontal, Theme.spacingM)
                        .padding(.bottom, Theme.spacingXL)
                    }
                    .padding(.horizontal, Theme.spacingM)
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16))
                            .foregroundColor(Theme.textMuted)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    savedToast
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [shareText])
            }
        }
    }

    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !example.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func saveTemplate() {
        let template = CustomTemplate(
            id: UUID().uuidString,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            description: templateDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            example: example.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        DatabaseService.shared.saveCustomTemplate(template)

        withAnimation {
            showSavedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSavedToast = false
            }
        }
    }

    private func shareTemplate() {
        shareText = """
        ✦ Intention Template: \(title)

        Category: \(selectedCategory)
        \(templateDescription.isEmpty ? "" : "\(templateDescription)\n")
        Example: "\(example)"

        Created with Ritual ✦
        """

        showShareSheet = true
    }

    private var savedToast: some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.success)

            Text("Template saved!")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Theme.textPrimary)
        }
        .padding(Theme.spacingM)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, Theme.spacingM)
        .padding(.bottom, Theme.spacingM)
    }
}

// MARK: - Category Picker Chip

struct CategoryPickerChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(isSelected ? Theme.goldPrimary : Theme.surface)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Theme.goldMuted.opacity(0.3), lineWidth: isSelected ? 0 : 1)
            )
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
