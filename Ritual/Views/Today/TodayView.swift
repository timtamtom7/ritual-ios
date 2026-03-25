import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    @State private var showingBreathing = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.spacingL) {
                        headerSection

                        if viewModel.showMorningFlow {
                            morningFlowSection
                        } else if viewModel.todaysIntention != nil {
                            intentionSection
                        }

                        breathingButton

                        if viewModel.showEveningFlow {
                            eveningFlowSection
                        } else if viewModel.todaysCheckIn != nil {
                            checkInSummary
                        }
                    }
                    .padding(.horizontal, Theme.spacingM)
                    .padding(.vertical, Theme.spacingL)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(greeting)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                }
            }
            .sheet(isPresented: $showingBreathing) {
                BreathingSessionView()
            }
            .onAppear {
                viewModel.loadTodaysData()
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 {
            return "Good Morning"
        } else if hour < 17 {
            return "Good Afternoon"
        } else {
            return "Good Evening"
        }
    }

    private var headerSection: some View {
        VStack(spacing: Theme.spacingS) {
            Text(dateString)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(Theme.textMuted)
        }
        .frame(maxWidth: .infinity)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }

    @ViewBuilder
    private var morningFlowSection: some View {
        MorningIntentionView(
            onComplete: { text in
                viewModel.saveIntention(text)
            },
            onDismiss: {
                viewModel.showMorningFlow = false
            }
        )
    }

    @ViewBuilder
    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: Theme.spacingS) {
            Text("Today's Intention")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Theme.textMuted)
                .textCase(.uppercase)
                .tracking(1)

            if let intention = viewModel.todaysIntention {
                IntentionCard(intention: intention, isHighlighted: true)
            }
        }
    }

    private var breathingButton: some View {
        Button(action: { showingBreathing = true }) {
            HStack(spacing: Theme.spacingS) {
                Image(systemName: "wind")
                    .font(.system(size: 18))
                Text("Breathe")
                    .font(.system(size: 17, weight: .medium))
            }
            .foregroundColor(Theme.goldPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Theme.goldPrimary.opacity(0.1))
            .cornerRadius(Theme.buttonRadius)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.buttonRadius)
                    .stroke(Theme.goldMuted.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.top, Theme.spacingS)
    }

    @ViewBuilder
    private var eveningFlowSection: some View {
        EveningCheckInView(
            onComplete: { acted, reflection in
                viewModel.saveCheckIn(acted: acted, reflection: reflection)
            },
            onDismiss: {
                viewModel.showEveningFlow = false
            }
        )
    }

    @ViewBuilder
    private var checkInSummary: some View {
        if let checkIn = viewModel.todaysCheckIn {
            VStack(alignment: .leading, spacing: Theme.spacingS) {
                Text("Evening Check-In")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textMuted)
                    .textCase(.uppercase)
                    .tracking(1)

                HStack {
                    Image(systemName: checkIn.acted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(checkIn.acted ? Theme.success : Theme.warning)
                        .font(.system(size: 24))

                    VStack(alignment: .leading, spacing: 4) {
                        Text(checkIn.acted ? "You acted on your intention" : "You didn't quite get there")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(Theme.textPrimary)

                        if let reflection = checkIn.reflection, !reflection.isEmpty {
                            Text(reflection)
                                .font(.system(size: 14))
                                .foregroundColor(Theme.textSecondary)
                                .lineLimit(2)
                        }
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
            .padding(.top, Theme.spacingS)
        }
    }
}
