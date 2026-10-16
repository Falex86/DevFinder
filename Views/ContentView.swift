import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = SearchViewModel()
    @StateObject private var favoritesManager = FavoritesManager()

    var body: some View {
        TabView {
            searchTab
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }

            favoritesTab
                .tabItem {
                    Label("Favorites", systemImage: "heart.fill")
                }
        }
        .tint(Color.purple)
        .preferredColorScheme(.dark)
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.05, blue: 0.12),
                Color(red: 0.10, green: 0.07, blue: 0.23),
                Color(red: 0.05, green: 0.06, blue: 0.14)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var searchTab: some View {
        NavigationStack {
            ZStack {
                background

                VStack(spacing: 22) {
                    header
                    searchBar
                    filtersSection

                    if viewModel.isLoading {
                        loadingState
                            .frame(maxHeight: .infinity)
                            .transition(.opacity)

                    } else if let message = viewModel.errorMessage {
                        VStack(spacing: 18) {
                            emptyState(
                                icon: "wifi.exclamationmark",
                                title: "Something went wrong",
                                message: message
                            )

                            Button {
                                performSearch()
                            } label: {
                                Label(
                                    "Try again",
                                    systemImage: "arrow.clockwise"
                                )
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 13)
                                .background(
                                    Color.purple,
                                    in: RoundedRectangle(cornerRadius: 15)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxHeight: .infinity)
                        .transition(.opacity)

                    } else if viewModel.users.isEmpty {
                        emptyState(
                            icon: "chevron.left.forwardslash.chevron.right",
                            title: "Discover developers",
                            message: "Search GitHub to find developers and explore their profiles."
                        )
                        .frame(maxHeight: .infinity)
                        .transition(.opacity)

                    } else {
                        HStack {
                            Text("SEARCH RESULTS")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.65))

                            Spacer()

                            Text("\(viewModel.users.count) found")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.purple.opacity(0.95))
                        }
                        .transition(.opacity)

                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.users) { user in
                                    NavigationLink(value: user) {
                                        developerCard(user: user)
                                    }
                                    .buttonStyle(.plain)
                                    .transition(
                                        .opacity.combined(
                                            with: .move(edge: .bottom)
                                        )
                                    )
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .scrollIndicators(.hidden)
                        .transition(.opacity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .animation(
                    .easeInOut(duration: 0.3),
                    value: viewModel.users.count
                )
                .animation(
                    .easeInOut(duration: 0.3),
                    value: viewModel.isLoading
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GitHubUser.self) { user in
                ProfileView(user: user)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 15)
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text("DEVFINDER")
                        .font(.caption.weight(.heavy))
                        .tracking(3)
                        .foregroundStyle(.white)

                    Text("GITHUB DEVELOPER EXPLORER")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }

            Text("Find your\nnext developer.")
                .font(.system(
                    size: 36,
                    weight: .bold,
                    design: .rounded
                ))
                .tracking(-1)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text("Explore the people building on GitHub.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.purple)

            TextField(
                "Search GitHub developers",
                text: $viewModel.query
            )
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .submitLabel(.search)
            .onSubmit {
                performSearch()
            }

            if !viewModel.query.isEmpty {
                Button {
                    viewModel.query = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search text")
            }

            Button {
                performSearch()
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Search developers")
        }
        .padding(8)
        .padding(.leading, 8)
        .background(
            Color.white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 21)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 21)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        }
    }

    private func performSearch() {
        Task {
            await viewModel.search()
        }
    }

    private var loadingState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(
                        Color.purple.opacity(0.18),
                        lineWidth: 5
                    )
                    .frame(width: 76, height: 76)

                ProgressView()
                    .controlSize(.large)
                    .tint(.purple)
                    .scaleEffect(1.3)
            }

            VStack(spacing: 7) {
                Text("Finding developers")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("Searching GitHub for matching profiles...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(28)
    }

    private var favoritesTab: some View {
        NavigationStack {
            ZStack {
                background

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 44, height: 44)
                                .background(
                                    LinearGradient(
                                        colors: [.pink, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 15)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text("YOUR COLLECTION")
                                    .font(.caption.weight(.bold))
                                    .tracking(2)
                                    .foregroundStyle(.white.opacity(0.85))

                                Text("\(favoritesManager.favorites.count) saved profiles")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }

                        Text("Favorite\ndevelopers.")
                            .font(.system(
                                size: 34,
                                weight: .bold,
                                design: .rounded
                            ))
                            .foregroundStyle(.white)

                        Text("Your saved GitHub profiles, all in one place.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    if favoritesManager.favorites.isEmpty {
                        Spacer()

                        emptyState(
                            icon: "heart",
                            title: "No favorites yet",
                            message: "Search for developers and tap the heart on a card to save them here."
                        )

                        Spacer()
                    } else {
                        HStack {
                            Text("SAVED DEVELOPERS")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.6))

                            Spacer()

                            Text("\(favoritesManager.favorites.count) saved")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.purple)
                        }

                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(favoritesManager.favorites) { user in
                                    NavigationLink(value: user) {
                                        developerCard(user: user)
                                    }
                                    .buttonStyle(.plain)
                                    .transition(
                                        .opacity.combined(
                                            with: .move(edge: .bottom)
                                        )
                                    )
                                }
                            }
                            .padding(.bottom, 24)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .animation(
                    .easeInOut(duration: 0.3),
                    value: favoritesManager.favorites.count
                )
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GitHubUser.self) { user in
                ProfileView(user: user)
            }
        }
    }

    private func developerCard(user: GitHubUser) -> some View {
        HStack(spacing: 14) {
            AsyncImage(url: URL(string: user.avatarURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Color.white.opacity(0.08)

                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 19))
            .overlay {
                RoundedRectangle(cornerRadius: 19)
                    .stroke(
                        Color.white.opacity(0.12),
                        lineWidth: 1
                    )
            }

            VStack(alignment: .leading, spacing: 7) {
                Text(user.name ?? user.login)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("@\(user.login)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                if let location = user.location,
                   !location.isEmpty {
                    Label(
                        location,
                        systemImage: "mappin.and.ellipse"
                    )
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
                    .lineLimit(1)
                }

                HStack(spacing: 12) {
                    if let followers = user.followers {
                        Label(
                            followers.formatted(),
                            systemImage: "person.2"
                        )
                    }

                    if let repos = user.publicRepos {
                        Label(
                            repos.formatted(),
                            systemImage: "book.closed"
                        )
                    }
                }
                .font(.caption2)
                .foregroundStyle(
                    Color(red: 0.78, green: 0.68, blue: 1)
                )

                HStack(spacing: 5) {
                    Text("View profile")
                        .font(.caption.weight(.medium))

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(
                    Color(red: 0.78, green: 0.68, blue: 1)
                )
                .padding(.top, 2)
            }

            Spacer(minLength: 0)

            Button {
                withAnimation(.spring(
                    response: 0.32,
                    dampingFraction: 0.48
                )) {
                    favoritesManager.toggle(user)
                }
            } label: {
                Image(
                    systemName: favoritesManager.isFavorite(user.id)
                        ? "heart.fill"
                        : "heart"
                )
                .font(.system(size: 19, weight: .semibold))
                .foregroundStyle(
                    favoritesManager.isFavorite(user.id)
                        ? Color.pink
                        : Color.white.opacity(0.65)
                )
                .symbolEffect(
                    .bounce,
                    value: favoritesManager.isFavorite(user.id)
                )
                .scaleEffect(
                    favoritesManager.isFavorite(user.id) ? 1.08 : 1.0
                )
                .frame(width: 38, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                favoritesManager.isFavorite(user.id)
                    ? "Remove from favorites"
                    : "Add to favorites"
            )

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
        }
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 23)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.085),
                            Color.white.opacity(0.035)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .overlay {
            RoundedRectangle(cornerRadius: 23)
                .stroke(
                    Color.white.opacity(0.09),
                    lineWidth: 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 23))
    }

    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(.purple)

                    Text("REFINE SEARCH")
                        .font(.caption.weight(.bold))
                        .tracking(2)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.language = ""
                        viewModel.location = ""
                    }
                } label: {
                    Label("Clear", systemImage: "arrow.counterclockwise")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    Text("LANGUAGE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))

                    Picker(
                        "Language",
                        selection: $viewModel.language
                    ) {
                        Text("Any").tag("")
                        Text("Swift").tag("Swift")
                        Text("Python").tag("Python")
                        Text("JavaScript").tag("JavaScript")
                        Text("TypeScript").tag("TypeScript")
                        Text("Java").tag("Java")
                        Text("C#").tag("C#")
                        Text("Go").tag("Go")
                        Text("Kotlin").tag("Kotlin")
                        Text("Ruby").tag("Ruby")
                    }
                    .tint(.white)
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Color.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(
                                Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 7) {
                    Text("LOCATION")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.5))

                    TextField(
                        "e.g. Toronto",
                        text: $viewModel.location
                    )
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 11)
                    .background(
                        Color.white.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 13)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(
                                Color.white.opacity(0.08),
                                lineWidth: 1
                            )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text("Combine filters with a username or search on their own.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
    }

    private func emptyState(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(
                    Color(red: 0.78, green: 0.68, blue: 1)
                )
                .frame(width: 84, height: 84)
                .background {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.purple.opacity(0.16))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            Color.purple.opacity(0.18),
                            lineWidth: 1
                        )
                }

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.62))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
        .padding(.vertical, 20)
    }
}
