import SwiftUI

struct TrialReminderView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Color.accentColor)
                }

                VStack(spacing: 8) {
                    Text("We've got you covered")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("We'll send you a reminder the day before your trial ends — no unexpected charges.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 8)
                }

                // Timeline
                VStack(alignment: .leading, spacing: 0) {
                    TrialTimelineRow(
                        icon: "gift.fill",
                        iconColor: .green,
                        title: "Today",
                        subtitle: "3-day free trial begins — full access",
                        isLast: false
                    )
                    TrialTimelineRow(
                        icon: "bell.fill",
                        iconColor: .accentColor,
                        title: "Day 2",
                        subtitle: "We send you a billing reminder",
                        isLast: false
                    )
                    TrialTimelineRow(
                        icon: "creditcard.fill",
                        iconColor: Color(.systemGray),
                        title: "Day 3",
                        subtitle: "Trial ends — cancel anytime before this",
                        isLast: true
                    )
                }
                .padding(16)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                viewModel.nextPage()
            } label: {
                Text("Got it, continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

private struct TrialTimelineRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(iconColor)
                }
                if !isLast {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(width: 2, height: 30)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 9)

            Spacer()
        }
    }
}
