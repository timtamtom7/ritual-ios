import SwiftUI

struct CommunityTemplatesView: View {
    @State private var selectedCategory: String? = nil
    @State private var adoptedTemplate: IntentionTemplate?
    @State private var showAdoptedToast: Bool = false

    private var categories: [String] {
        var cats = Set<String>()
        for template in IntentionTemplateStore.popularTemplates {
            cats.insert(template.category)
        }
        return Array(cats).sorted()
    }

    private var filteredTemplates: [IntentionTemplate] {
        IntentionTemplateStore.getTemplates(forCategory: selectedCategory)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        headerSection

                        categoryFilter

                        templatesList

                        Spacer()
                            .frame(height: Theme.spacingL)
                    }
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingS)
                }
            }
            .navigationTitle("Templates")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .overlay(alignment: .bottom) {
                if showAdoptedToast, let template = adoptedTemplate {
                    adoptedToast(for: template)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.spacingS) {
            Text("Browse community intention templates")
                .font(.system(size: 17))
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)

            Text("Adopt a template to shape your daily practice")
                .font(.system(size: 14, design: .serif))
                .foregroundColor(Theme.textMuted)
                .italic()
        }
        .padding(.top, Theme.spacingS)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.spacingS) {
                CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                    withAnimation { selectedCategory = nil }
                }

                ForEach(categories, id: \.self) { category in
                    CategoryChip(title: category, isSelected: selectedCategory == category) {
                        withAnimation { selectedCategory = category }
                    }
                }
            }
        }
    }

    private var templatesList: some View {
        VStack(spacing: Theme.spacingM) {
            ForEach(filteredTemplates) { template in
                TemplateCard(template: template) {
                    adoptTemplate(template)
                }
            }
        }
    }

    private func adoptTemplate(_ template: IntentionTemplate) {
        adoptedTemplate = template
        UIPasteboard.general.string = template.example

        withAnimation {
            showAdoptedToast = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation {
                showAdoptedToast = false
            }
        }
    }

    private func adoptedToast(for template: IntentionTemplate) -> some View {
        HStack(spacing: Theme.spacingS) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(Theme.success)

            VStack(alignment: .leading, spacing: 2) {
                Text("Template adopted!")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Theme.textPrimary)
                Text("Example copied — paste it in your intention")
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textSecondary)
            }
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

// MARK: - Supporting Views

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Theme.background : Theme.textSecondary)
                .padding(.horizontal, 16)
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

struct TemplateCard: View {
    let template: IntentionTemplate
    let onAdopt: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: template.icon)
                    .font(.system(size: 16))
                    .foregroundColor(Theme.goldPrimary)
                    .frame(width: 36, height: 36)
                    .background(Theme.goldPrimary.opacity(0.1))
                    .cornerRadius(10)

                VStack(alignment: .leading, spacing: 2) {
                    Text(template.title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.textPrimary)

                    Text("\(template.category) · Used \(template.timesUsed.formatted()) times")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textMuted)
                }

                Spacer()
            }

            Text(template.description)
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)
                .lineLimit(2)

            Text("\"\(template.example)\"")
                .font(.system(size: 14, weight: .regular, design: .serif))
                .foregroundColor(Theme.textMuted)
                .italic()
                .lineLimit(2)
                .padding(.top, 4)

            Button(action: onAdopt) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14))
                    Text("Use Template")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Theme.goldPrimary)
                .padding(.top, Theme.spacingS)
            }
        }
        .padding(Theme.spacingM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface)
        .cornerRadius(Theme.cardRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cardRadius)
                .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
        )
    }
}
