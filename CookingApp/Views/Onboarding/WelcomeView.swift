import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    var splashDismissed: Bool

    @State private var mascotVisible  = false
    @State private var contentVisible = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image("ChefMascot")
                .resizable()
                .scaledToFit()
                .frame(width: 180, height: 180)
                .accessibilityHidden(true)
                .opacity(mascotVisible ? 1 : 0)

            VStack(spacing: 12) {
                Text("Welcome to Inkgredients")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Get personalized daily recipe suggestions tailored to your dietary needs.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 16)

            Spacer()

            Button {
                viewModel.nextPage()
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .opacity(contentVisible ? 1 : 0)
            .offset(y: contentVisible ? 0 : 16)
        }
        .onAppear {
            guard splashDismissed else { return }
            mascotVisible = true
            contentVisible = true
        }
        .onChange(of: splashDismissed) { dismissed in
            guard dismissed else { return }
            // Mascot fades in as the splash fades out — same image, smooth cross-dissolve
            withAnimation(.easeInOut(duration: 0.3)) {
                mascotVisible = true
            }
            // Text and button slide up shortly after
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.25)) {
                contentVisible = true
            }
        }
    }
}
