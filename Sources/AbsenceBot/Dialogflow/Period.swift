import Foundation
import Prelude
import Optics

public struct Period {
    public var startedAt: Date
    public var finishedAt: Date
    
    public var isAllDay: Bool {
        let dateComponentsA = Calendar.gmtTimeZoneCalendar
            .dateComponents([.hour, .minute, .second], from: startedAt)
        let dateComponentsB = Calendar.gmtTimeZoneCalendar
            .dateComponents([.hour, .minute, .second], from: finishedAt)
        
        return dateComponentsA == dateComponentsB
    }
    
    private init(startedAt: Date, finishedAt: Date) {
        self.startedAt = startedAt
        self.finishedAt = finishedAt
    }
    
    public init(dates: (Date, Date)) {
        let sortedDates = [dates.0, dates.1]
            .sorted(by: <)
        
        self.startedAt = sortedDates.first!
        self.finishedAt = sortedDates.last!
    }
    
    internal func applyTimeZoneOffsetFix(timeZone: TimeZone, calendar: Calendar = Calendar(identifier: .gregorian)) -> Period? {
        return zip(with: { .init(startedAt: $0, finishedAt: $1) })(
            self.startedAt.dateByReplacingTimeZone(timeZone: timeZone),
            self.finishedAt.dateByReplacingTimeZone(timeZone: timeZone)
        )
    }
}

extension Period {
    static let daysRangeFormatter: (TimeZone) -> DateFormatter = { timeZone in
        return DateFormatter()
            |> \.locale .~ Locale(identifier: "en_US_POSIX")
            |> \.timeZone .~ timeZone
            |> \.dateStyle .~ .long
            |> \.timeStyle .~ .none
    }
    
    static let dateTimeRangeFormatter: (TimeZone) -> DateFormatter = { timeZone in
        return DateFormatter()
            |> \.locale .~ Locale(identifier: "en_US_POSIX")
            |> \.timeZone .~ timeZone
            |> \.dateStyle .~ .long
            |> \.timeStyle .~ .short
    }
    
    func dates(timeZone: TimeZone) -> [String] {
        let sortedDates = Array(Set([self.startedAt, self.finishedAt]))
            .sorted(by: <)
        
        if self.isAllDay {
            return sortedDates
                .compactMap { Period.daysRangeFormatter(timeZone).string(from: $0) }
        } else {
            return sortedDates
                .compactMap { Period.dateTimeRangeFormatter(timeZone).string(from: $0) }
        }
    }
}

extension Period: Codable {}
