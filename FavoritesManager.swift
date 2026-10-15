import Foundation
import Combine

@MainActor
final class FavoritesManager: ObservableObject {
    @Published private(set) var favorites: [GitHubUser] = []

    private let storageKey = "devfinder.favoriteUsers.v2"

    init() {
        guard
            let data = UserDefaults.standard.data(forKey: storageKey),
            let savedUsers = try? JSONDecoder().decode(
                [GitHubUser].self,
                from: data
            )
        else {
            return
        }

        favorites = savedUsers
    }

    func isFavorite(_ userID: Int) -> Bool {
        favorites.contains { $0.id == userID }
    }

    func toggle(_ user: GitHubUser) {
        if isFavorite(user.id) {
            favorites.removeAll { $0.id == user.id }
        } else {
            favorites.append(user)
        }

        saveFavorites()
    }

    private func saveFavorites() {
        guard let data = try? JSONEncoder().encode(favorites) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

