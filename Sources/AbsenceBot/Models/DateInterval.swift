import Either
import Foundation
import Prelude
import Optics

public struct DateInterval {
  public var start: Date
  public var end: Date
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
  func dateRange(tz: TimeZone, bolded: Bool = true) -> String {
    guard #available(OSX 10.12, *) else { fatalError() }

    let formatter = self.isAllDay
      ? fullDaysDateIntervalFormatter(tz)
      : dateTimeDateIntervalFormatter(tz)

    let raw = formatter
      .string(from: self.start, to: self.end)
      
      // fixing issue with tests on linux
      .replacingOccurrences(of: " ", with: " ")
      .replacingOccurrences(of: "–", with: "-")

    return raw
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

private let fullDaysDateIntervalFormatter: (TimeZone) -> DateIntervalFormatter = { timeZone in
  return DateIntervalFormatter()
    |> \.dateStyle .~ .medium
    |> \.timeStyle .~ .none
    |> \.calendar .~ Calendar.gmtTimeZoneCalendar
    |> \.locale .~ Locale(identifier: "en_US_POSIX")
    |> \.timeZone .~ timeZone
}

private let dateTimeDateIntervalFormatter: (TimeZone) -> DateIntervalFormatter = { timeZone in
  return DateIntervalFormatter()
    |> \.dateStyle .~ .medium
    |> \.timeStyle .~ .short
    |> \.calendar .~ Calendar.gmtTimeZoneCalendar
    |> \.locale .~ Locale(identifier: "en_US_POSIX")
    |> \.timeZone .~ timeZone
}
