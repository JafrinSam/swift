import Foundation
import SwiftData

@Model
class Session {
    var taskName: String
    var duration: TimeInterval
    var audioNoteURL: URL?
    var date: Date
    
    init(taskName: String, duration: TimeInterval, audioNoteURL: URL? = nil) {
        self.taskName = taskName
        self.duration = duration
        self.audioNoteURL = audioNoteURL
        self.date = Date()
    }
}
