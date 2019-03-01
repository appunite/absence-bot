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

    // get start day
    self.start = event.start.date ?? event.start.dateTime

    // get end day if date-time
    if let _end = event.end.dateTime {
      self.end = _end
    }

    // get end day if whole day event
    else if let _end = event.end.date {
      // if we're adding all day event, google is exluding end date, so we need to go back in time by one day
      let calendar = Calendar.gmtTimeZoneCalendar
      self.end = calendar.date(byAdding: .day, value: -1, to: _end)
    }

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
