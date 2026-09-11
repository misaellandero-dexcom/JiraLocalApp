import Foundation

/// A Jira issue as returned by `jira search` (see ~/.local/share/jira-cli/jira.py cmd_search).
struct Ticket: Codable, Identifiable, Hashable {
    let key: String
    let url: String
    let summary: String?
    let status: String?
    let issueType: String?

    enum CodingKeys: String, CodingKey {
        case key, url, summary, status
        case issueType = "issue_type"
    }

    var id: String { key }

    /// Project key derived from the ticket key prefix, e.g. "RDS-1234" -> "RDS".
    var project: String {
        String(key.split(separator: "-").first ?? Substring(key))
    }
}

struct SearchResponse: Codable {
    let total: Int
    let issues: [Ticket]
}
