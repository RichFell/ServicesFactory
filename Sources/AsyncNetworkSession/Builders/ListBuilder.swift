import Foundation

/// Decodes raw list data into ``List`` models.
struct ListBuilder: Sendable {
    init() {}

    /// Decodes `data` into an array of lists.
    func decode(_ data: Data) throws -> [List] {
        try JSONDecoder().decode([List].self, from: data)
    }
}
