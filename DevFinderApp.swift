import SwiftUI

@main
struct DevFinderApp: App {
    @State private var showLaunchScreen = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showLaunchScreen ? 0 : 1)

                if showLaunchScreen {
                    LaunchScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                try? await Task.sleep(for: .seconds(2))
                withAnimation(.easeInOut(duration: 0.5)) {
                    showLaunchScreen = false
                }
            }
            .preferredColorScheme(.dark)
        }
    }
}

struct LaunchScreenView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.04, green: 0.06, blue: 0.13),
                        Color(red: 0.14, green: 0.06, blue: 0.28)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 22) {
                    Image("LaunchScreen")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: min(geometry.size.width * 0.78, 340),
                            height: min(geometry.size.height * 0.58, 480)
                        )
                        .accessibilityLabel("DevFinder")

                    Text("DevFinder")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Discover developers. Explore code.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .padding()
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
            }
        }
    }
}
