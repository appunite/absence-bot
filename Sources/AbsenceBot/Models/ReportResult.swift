import Foundation
import Optics
import Prelude

public struct ReportResult: Encodable {
  /// Defines who is requesting for absence
  public var requester: String?
  public var reviewer: String?
  
  /// Defines when absence is requested
  public var start: Date?
  public var end: Date?
  
  /// Defines why requester is requesting for an absence
  public var reason: Absence.Reason?
  
  ///
  public var eventLink: URL?
  
  /// Dates
  public var createAt: Date?
  public var updatedAt: Date?
  
  init(event: GoogleCalendar.Event) {
    self.eventLink = event.htmlLink
    self.createAt = event.created
    self.updatedAt = event.updated
    
    self.start = event.start.date ?? event.start.dateTime
    self.end = event.end.date ?? event.end.dateTime
    
    self.reason = event.summary
      .split(separator: "-")
      .last?
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .components(separatedBy: .whitespacesAndNewlines)
      .first
      .flatMap(Absence.Reason.init)
    
    self.requester = event.summary
      .split(separator: "-")
      .first?
      .trimmingCharacters(in: .whitespacesAndNewlines)
    
    self.reviewer = event.attendees?
      .filter { $0.email != self.requester }
      .first
      .flatMap(^\.displayName) ?? "<unknown>"
  }
}
