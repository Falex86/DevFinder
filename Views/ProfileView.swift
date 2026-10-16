
import SwiftUI
import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published private(set) var profile: GitHubProfile?
    @Published private(set) var repositories: [GitHubRepository] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service = GitHubService()

    func load(username: String) async {
        guard profile == nil else { return }

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let profileRequest =
                service.fetchProfile(username: username)

            async let repositoriesRequest =
                service.fetchRepositories(username: username)

            let (loadedProfile, loadedRepositories) =
                try await (profileRequest, repositoriesRequest)

            profile = loadedProfile
            repositories = loadedRepositories
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ProfileView: View {
    let user: GitHubUser

    @StateObject private var viewModel = ProfileViewModel()

    private let accentColor = Color(
        red: 0.75,
        green: 0.63,
        blue: 1.0
    )

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.15),
                    Color(red: 0.09, green: 0.08, blue: 0.22),
                    Color(red: 0.04, green: 0.06, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            Group {
                if viewModel.isLoading {
                    loadingView
                } else if let message = viewModel.errorMessage {
                    errorView(message: message)
                } else if let profile = viewModel.profile {
                    profileContent(profile: profile)
                } else {
                    loadingView
                }
            }
        }
        .navigationTitle(user.login)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task(id: user.login) {
            await viewModel.load(username: user.login)
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.isLoading)
        .animation(.easeInOut(duration: 0.3), value: viewModel.profile != nil)
    }

    private var loadingView: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)

            Text("Loading developer profile...")
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 18) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 38))
                .foregroundStyle(accentColor)

            Text("Couldn't load profile")
                .font(.title3.bold())
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await viewModel.load(username: user.login)
                }
            } label: {
                Label("Try again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 13)
                    .background(
                        Color.purple,
                        in: RoundedRectangle(cornerRadius: 15)
                    )
            }
        }
        .padding(28)
    }

    private func profileContent(
        profile: GitHubProfile
    ) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                profileHeader(profile: profile)

                statistics(profile: profile)

                if let bio = profile.bio, !bio.isEmpty {
                    sectionHeading("ABOUT")

                    Text(bio)
                        .font(.body)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineSpacing(5)
                }

                if let url = URL(string: profile.htmlURL) {
                    HStack(spacing: 12) {
                        Link(destination: url) {
                            HStack(spacing: 10) {
                                Image(systemName: "arrow.up.right.square")

                                Text("View GitHub Profile")
                                    .fontWeight(.semibold)

                                Spacer()

                                Image(systemName: "arrow.up.right")
                                    .font(.caption)
                            }
                            .foregroundStyle(.white)
                            .padding(17)
                            .background(
                                Color.purple.opacity(0.8),
                                in: RoundedRectangle(cornerRadius: 17)
                            )
                        }

                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(
                                    Color.white.opacity(0.09),
                                    in: RoundedRectangle(cornerRadius: 17)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 17)
                                        .stroke(
                                            Color.white.opacity(0.12),
                                            lineWidth: 1
                                        )
                                }
                        }
                        .accessibilityLabel("Share GitHub profile")
                    }
                }

                repositoriesSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .padding(.bottom, 32)
        }
        .scrollIndicators(.hidden)
    }

    private func profileHeader(
        profile: GitHubProfile
    ) -> some View {
        VStack(spacing: 15) {
            AsyncImage(url: URL(string: profile.avatarURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Color.white.opacity(0.08)

                    Image(systemName: "person.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 112, height: 112)
            .clipShape(RoundedRectangle(cornerRadius: 32))
            .overlay {
                RoundedRectangle(cornerRadius: 32)
                    .stroke(
                        accentColor.opacity(0.6),
                        lineWidth: 2
                    )
            }

            VStack(spacing: 6) {
                Text(profile.name ?? profile.login)
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text("@\(profile.login)")
                    .font(.subheadline)
                    .foregroundStyle(accentColor)

                if let location = profile.location,
                   !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.65))
                }
            }

            HStack(spacing: 7) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 7, height: 7)

                Text("GitHub Developer")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 8)
            .background(
                Color.white.opacity(0.07),
                in: Capsule()
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
    }

    private func statistics(
        profile: GitHubProfile
    ) -> some View {
        HStack(spacing: 10) {
            statisticCard(
                value: profile.followers,
                title: "Followers",
                icon: "person.2"
            )

            statisticCard(
                value: profile.publicRepos,
                title: "Public repos",
                icon: "book.closed"
            )

            statisticCard(
                value: viewModel.repositories.count,
                title: "Loaded",
                icon: "checkmark.circle"
            )
        }
    }

    private func statisticCard(
        value: Int,
        title: String,
        icon: String
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentColor)

            Text(value.formatted())
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 105)
        .padding(.horizontal, 5)
        .background(
            Color.white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )
        }
    }

    private var repositoriesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                sectionHeading("RECENT REPOSITORIES")

                Spacer()

                Text("\(viewModel.repositories.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(accentColor)
            }

            if viewModel.repositories.isEmpty {
                Text("No public repositories found.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        Color.white.opacity(0.06),
                        in: RoundedRectangle(cornerRadius: 18)
                    )
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.repositories) { repo in
                        repositoryCard(repo)
                            .transition(
                                .opacity.combined(
                                    with: .move(edge: .bottom)
                                )
                            )
                    }
                }
                .animation(
                    .easeInOut(duration: 0.35),
                    value: viewModel.repositories.count
                )
            }
        }
    }

    private func repositoryCard(
        _ repo: GitHubRepository
    ) -> some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "book.closed")
                    .foregroundStyle(accentColor)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 6) {
                    if let url = URL(string: repo.htmlURL) {
                        Link(destination: url) {
                            Text(repo.name)
                                .font(.headline)
                                .foregroundStyle(.white)
                                .lineLimit(2)
                        }
                    } else {
                        Text(repo.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    if let description = repo.description,
                       !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                            .lineLimit(3)
                    }
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.45))
            }

            HStack(spacing: 15) {
                if let language = repo.language,
                   !language.isEmpty {
                    Label(language, systemImage: "circle.fill")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(accentColor)
                }

                Label(
                    repo.stars.formatted(),
                    systemImage: "star"
                )
                .foregroundStyle(.white.opacity(0.7))
            }
            .font(.caption)
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.065),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    Color.white.opacity(0.08),
                    lineWidth: 1
                )
        }
    }

    private func sectionHeading(
        _ title: String
    ) -> some View {
        Text(title)
            .font(.caption.weight(.bold))
            .tracking(2)
            .foregroundStyle(.white.opacity(0.65))
    }
}
