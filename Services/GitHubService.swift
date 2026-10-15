import Foundation

enum GitHubAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .invalidResponse:
            return "GitHub returned an invalid response."
        case .httpError(let code):
            if code == 403 || code == 429 {
                return "GitHub rate limit reached. Try again later."
            }
            if code == 404 {
                return "The requested GitHub resource was not found."
            }
            return "GitHub returned HTTP error \(code)."
        }
    }
}

struct GitHubService {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private func get<T: Decodable>(
        _ url: URL,
        as type: T.Type
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue(
            "DevFinder-iOS",
            forHTTPHeaderField: "User-Agent"
        )

        let (data, response) = try await session.data(
            for: request
        )

        guard let response = response as? HTTPURLResponse else {
            throw GitHubAPIError.invalidResponse
        }

        guard (200..<300).contains(response.statusCode) else {
            throw GitHubAPIError.httpError(response.statusCode)
        }

        return try JSONDecoder().decode(type, from: data)
    }

    func searchUsers(query: String) async throws
        -> [GitHubUser] {
        var components = URLComponents(
            string: "https://api.github.com/search/users"
        )
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: "20")
        ]

        guard let url = components?.url else {
            throw GitHubAPIError.invalidURL
        }

        let result = try await get(
            url,
            as: GitHubSearchResponse.self
        )
        return result.items
    }

    func fetchProfile(username: String) async throws
        -> GitHubProfile {
        guard let url = URL(
            string: "https://api.github.com/users/\(username)"
        ) else {
            throw GitHubAPIError.invalidURL
        }

        return try await get(url, as: GitHubProfile.self)
    }

    func fetchRepositories(username: String) async throws
        -> [GitHubRepository] {
        guard let url = URL(
            string: "https://api.github.com/users/\(username)/repos?sort=updated&per_page=20"
        ) else {
            throw GitHubAPIError.invalidURL
        }

        return try await get(
            url,
            as: [GitHubRepository].self
        )
    }
}

