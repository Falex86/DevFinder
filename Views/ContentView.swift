
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
                Color(red: 0.05, green: 0.07, blue: 0.15),
                Color(red: 0.09, green: 0.08, blue: 0.22),
                Color(red: 0.04, green: 0.06, blue: 0.12)
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

                VStack(spacing: 24) {
                    header
                    searchBar
                    filtersSection

                    if viewModel.isLoading {
                        Spacer()

                        ProgressView()
                            .tint(.white)

                        Text("Finding developers...")
                            .foregroundStyle(.white.opacity(0.7))

                        Spacer()
                    } else if let message = viewModel.errorMessage {
                        Spacer()

                        emptyState(
                            icon: "person.crop.circle.badge.questionmark",
                            title: "No Results",
                            message: message
                        )

                        Spacer()
                    } else if viewModel.users.isEmpty {
                        Spacer()

                        emptyState(
                            icon: "chevron.left.forwardslash.chevron.right",
                            title: "Discover developers",
                            message: "Search GitHub to find developers and explore their profiles."
                        )

                        Spacer()
                    } else {
                        HStack {
                            Text("SEARCH RESULTS")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(.white.opacity(0.6))

                            Spacer()

                            Text("\(viewModel.users.count) found")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.purple)
                        }

                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.users) { user in
                                    NavigationLink(value: user) {
                                        developerCard(user: user)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GitHubUser.self) { user in
                ProfileView(user: user)
            }
        }
    }

    private var favoritesTab: some View {
        NavigationStack {
            ZStack {
                background

                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            Image(systemName: "heart.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 42, height: 42)
                                .background(
                                    Color.purple,
                                    in: RoundedRectangle(cornerRadius: 14)
                                )

                            Text("YOUR COLLECTION")
                                .font(.caption.weight(.bold))
                                .tracking(3)
                                .foregroundStyle(.white.opacity(0.8))
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
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.purple)
                        }

                        ScrollView {
                            LazyVStack(spacing: 14) {
                                ForEach(favoritesManager.favorites) { user in
                                    NavigationLink(value: user) {
                                        developerCard(user: user)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
            }
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: GitHubUser.self) { user in
                ProfileView(user: user)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 14)
                    )

                Text("DEVFINDER")
                    .font(.caption.weight(.bold))
                    .tracking(3)
                    .foregroundStyle(.white.opacity(0.8))
            }

            Text("Find your\nnext developer.")
                .font(.system(size: 36, weight: .bold, design: .rounded))
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
        HStack(spacing: 12) {
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
                Task {
                    await viewModel.search()
                }
            }

            Button {
                Task {
                    await viewModel.search()
                }
            } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(
                        Color.purple,
                        in: RoundedRectangle(cornerRadius: 13)
                    )
            }
            .accessibilityLabel("Search developers")
        }
        .padding(8)
        .padding(.leading, 8)
        .background(
            Color.white.opacity(0.08),
            in: RoundedRectangle(cornerRadius: 20)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        }
    }

    private func developerCard(user: GitHubUser) -> some View {
        HStack(spacing: 15) {
            AsyncImage(url: URL(string: user.avatarURL)) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                ZStack {
                    Color.white.opacity(0.08)

                    Image(systemName: "person.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .frame(width: 62, height: 62)
            .clipShape(RoundedRectangle(cornerRadius: 19))

            VStack(alignment: .leading, spacing: 7) {
                Text(user.name ?? user.login)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text("@\(user.login)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)

                if let location = user.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
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
                    Color(red: 0.75, green: 0.63, blue: 1)
                )

                HStack(spacing: 5) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 10, weight: .bold))

                    Text("View profile")
                        .font(.caption.weight(.medium))
                }
                .foregroundStyle(
                    Color(red: 0.75, green: 0.63, blue: 1)
                )
            }

            Spacer(minLength: 0)

            Button {
                favoritesManager.toggle(user)
            } label: {
                Image(
                    systemName: favoritesManager.isFavorite(user.id)
                        ? "heart.fill"
                        : "heart"
                )
                .font(.title3)
                .foregroundStyle(
                    favoritesManager.isFavorite(user.id)
                        ? .pink
                        : .white.opacity(0.65)
                )
                .frame(width: 38, height: 42)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                favoritesManager.isFavorite(user.id)
                    ? "Remove from favorites"
                    : "Add to favorites"
            )

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Color.white.opacity(0.07),
            in: RoundedRectangle(cornerRadius: 23)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 23)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        }
    }
    
    private var filtersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundStyle(.purple)

                Text("FILTERS")
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.8))

                Spacer()

                Button("Clear") {
                    viewModel.language = ""
                    viewModel.location = ""
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.purple.opacity(0.95))
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LANGUAGE")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.55))

                    Picker("Language", selection: $viewModel.language) {
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
                    .padding(.vertical, 5)
                    .background(
                        Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("LOCATION")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.55))

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
                        Color.white.opacity(0.08),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
            }

            Text("Combine filters with a username or search on their own.")
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private func emptyState(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 35, weight: .medium))
                .foregroundStyle(
                    Color(red: 0.75, green: 0.63, blue: 1)
                )
                .frame(width: 86, height: 86)
                .background(
                    Color.purple.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: 28)
                )

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 18)
    }
}

