import Either
import Foundation
import Prelude
import Optics

public struct DateInterval {
  public private(set) var start: Date
  public private(set) var end: Date
}

extension DateInterval: Codable, Equatable {}

extension DateInterval {
  public init(dates: (Date, Date), tz: TimeZone?) {
    let sortedDates = [dates.0, dates.1]
      .sorted(by: <)
    
    self.start = tz.flatMap { sortedDates.first!.dateByReplacingTimeZone(timeZone: $0) } ?? sortedDates.first!
    self.end = tz.flatMap { sortedDates.last!.dateByReplacingTimeZone(timeZone: $0) } ?? sortedDates.last!
  }
  
  public var isAllDay: Bool {
    let dateComponentsA = Calendar.gmtTimeZoneCalendar
      .dateComponents([.hour, .minute, .second], from: start)
    let dateComponentsB = Calendar.gmtTimeZoneCalendar
      .dateComponents([.hour, .minute, .second], from: end)
    
    return dateComponentsA == dateComponentsB
  }
}

extension DateInterval {
  func dates(tz: TimeZone) -> [String] {
    let sortedDates = Array(Set([self.start, self.end]))
      .sorted(by: <)
    
    if self.isAllDay {
      return sortedDates
        .compactMap { daysRangeFormatter(tz).string(from: $0) }
    } else {
      return sortedDates
        .compactMap { dateTimeRangeFormatter(tz).string(from: $0) }
    }
  }
  
  func dateRange(tz: TimeZone) -> String {
    return dates(tz: tz)
      .map({"*\($0)*"})
      .joined(separator: " - ")
  }
}

private let daysRangeFormatter: (TimeZone) -> DateFormatter = { timeZone in
  return DateFormatter()
    |> \.locale .~ Locale(identifier: "en_US_POSIX")
    |> \.timeZone .~ timeZone
    |> \.dateStyle .~ .long
    |> \.timeStyle .~ .none
}

private let dateTimeRangeFormatter: (TimeZone) -> DateFormatter = { timeZone in
  return DateFormatter()
    |> \.locale .~ Locale(identifier: "en_US_POSIX")
    |> \.timeZone .~ timeZone
    |> \.dateStyle .~ .long
    |> \.timeStyle .~ .short
}
