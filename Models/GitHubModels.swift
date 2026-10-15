import Foundation

struct GitHubUser: Codable, Identifiable, Hashable {
    let id: Int
    let login: String
    let avatarURL: String
    let htmlURL: String

    // Additional information for developer cards
    var name: String?
    var location: String?
    var followers: Int?
    var publicRepos: Int?

    enum CodingKeys: String, CodingKey {
        case id, login, name, location, followers
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case publicRepos = "public_repos"
    }
}

struct GitHubSearchResponse: Decodable {
    let totalCount: Int
    let items: [GitHubUser]

    enum CodingKeys: String, CodingKey {
        case items
        case totalCount = "total_count"
    }
}

struct GitHubProfile: Decodable {
    let login: String
    let name: String?
    let bio: String?
    let location: String?
    let avatarURL: String
    let htmlURL: String
    let followers: Int
    let publicRepos: Int

    enum CodingKeys: String, CodingKey {
        case login, name, bio, location, followers
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
        case publicRepos = "public_repos"
    }
}

struct GitHubRepository: Decodable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let htmlURL: String
    let language: String?
    let stars: Int

    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case htmlURL = "html_url"
        case stars = "stargazers_count"
    }
}
