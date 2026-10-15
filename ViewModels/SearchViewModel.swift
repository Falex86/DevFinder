import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var language = ""
    @Published var location = ""

    @Published private(set) var users: [GitHubUser] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let service: GitHubService

    init(service: GitHubService? = nil) {
        self.service = service ?? GitHubService()
    }

    func search() async {
        let term = query.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let selectedLanguage = language.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        let selectedLocation = location.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        var searchTerms: [String] = []

        if !term.isEmpty {
            searchTerms.append(term)
        }

        if !selectedLanguage.isEmpty {
            searchTerms.append("language:\(selectedLanguage)")
        }

        if !selectedLocation.isEmpty {
            searchTerms.append("location:\(selectedLocation)")
        }

        guard !searchTerms.isEmpty else {
            users = []
            errorMessage = "Enter a search term or select a filter."
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let results = try await service.searchUsers(
                query: searchTerms.joined(separator: " ")
            )

            var enrichedUsers = results

            // Load full profile information for up to five users.
            for index in 0..<min(5, results.count) {
                do {
                    let profile = try await service.fetchProfile(
                        username: results[index].login
                    )

                    let user = results[index]

                    enrichedUsers[index] = GitHubUser(
                        id: user.id,
                        login: user.login,
                        avatarURL: user.avatarURL,
                        htmlURL: user.htmlURL,
                        name: profile.name,
                        location: profile.location,
                        followers: profile.followers,
                        publicRepos: profile.publicRepos
                    )
                } catch {
                    // Keep the basic search result if its profile fails.
                    continue
                }
            }

            users = enrichedUsers

            if users.isEmpty {
                errorMessage = "No developers found. Try different filters."
            }
        } catch {
            users = []
            errorMessage = error.localizedDescription
        }
    }
}
