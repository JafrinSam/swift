import Foundation
import SwiftData

@Model
class Snippet {
    var title: String
    var code: String
    var language: String // e.g., "Swift", "Python", "Bash"
    var createdAt: Date
    
    init(title: String, code: String, language: String = "Swift") {
        self.title = title
        self.code = code
        self.language = language
        self.createdAt = Date()
    }
}
