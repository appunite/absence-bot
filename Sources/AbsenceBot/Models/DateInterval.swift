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
    let calendar = Calendar.gmtTimeZoneCalendar
    let components: Set<Calendar.Component> = [.hour, .minute, .second]

    return calendar.dateComponents(components, from: start)
      == calendar.dateComponents(components, from: end)
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
  
  func dateRange(tz: TimeZone, bolded: Bool = true) -> String {
    return dates(tz: tz)
      .map({ bolded ? "*\($0)*" : $0})
      .joined(separator: " - ")
  }
}

extension DateInterval {
  init?(year: Int, month: Int) {
    let endDateComponents = DateComponents(month: 1, second: -1)
    let startDateComponents = DateComponents(year: year, month: month, day: 1)
    
    let calendar = Calendar.gmtTimeZoneCalendar
    guard let start = calendar.date(from: startDateComponents),
      let end = calendar.date(byAdding: endDateComponents, to: start)
      else { return nil }

    self.start = start
    self.end = end
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
