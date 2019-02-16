import Foundation
import Prelude

public struct Context: Codable, Equatable {
  public private(set) var name: URL
  public private(set) var lifespanCount: Int
  public private(set) var parameters: Parameters
  
  internal enum Identifier: String {
    case followup = "absenceday-followup"
    case full = "absenceday-full"
    case report = "absence-report-followup"
  }

  internal var identifier: Identifier? {
    return Identifier(rawValue: name.lastPathComponent)
  }

  public struct Parameters: Codable, Equatable {
    // @reason
    public private(set) var reason: String?
    // @sys.date-period
    public private(set) var datePeriod: DatePeriod?
    // @sys.date
    public private(set) var date: Date?
    // @sys.date
    public private(set) var dateStart: Date?
    // @sys.date
    public private(set) var dateEnd: Date?
    // @sys.time-period
    public private(set) var timePeriod: TimePeriod?
    // @sys.time
    public private(set) var timeStart: Date?
    // @sys.time
    public private(set) var timeEnd: Date?
    // @sys.date-time
    public private(set) var dateTimeStart: Date?
    // @sys.date-time
    public private(set) var dateTimeEnd: Date?
    // @sys.date
    public private(set) var dates: [Date]?

    public struct DatePeriod: Codable, Equatable {
      public private(set) var startDate: Date
      public private(set) var endDate: Date
    }

    public struct TimePeriod: Codable, Equatable {
      public private(set) var startTime: Date
      public private(set) var endTime: Date
    }

    enum CodingKeys: String, CodingKey {
      case reason
      case datePeriod = "date-period"
      case date
      case dateStart = "date-start"
      case dateEnd = "date-end"
      case timePeriod = "time-period"
      case timeStart = "time-start"
      case timeEnd = "time-end"
      case dateTimeStart = "date-time-start"
      case dateTimeEnd = "date-time-end"
      case dates = "date-list"
    }
  }
}

extension Context.Parameters {
  private struct CustomeCodingKeys: CodingKey {
    var stringValue: String
    init?(stringValue: String) {
      self.stringValue = stringValue
    }
    
    var intValue: Int?
    init?(intValue: Int) {
      return nil
    }
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    
    let _reason = try? container.decodeIfPresent(String.self, forKey: .reason)
    self.reason = _reason.flatMap(id)
    
    let _datePeriod = try? container.decode(DatePeriod.self, forKey: .datePeriod)
    self.datePeriod = _datePeriod.flatMap(id)

    let _timePeriod = try? container.decode(TimePeriod.self, forKey: .timePeriod)
    self.timePeriod = _timePeriod.flatMap(id)

    let _dates = try? container.decodeIfPresent([Date].self, forKey: .dates)
    self.dates = _dates.flatMap(id)
    
    let _timeStart = try? container.decode(Date?.self, forKey: .timeStart)
    self.timeStart = _timeStart.flatMap(id)
    
    let _timeEnd = try? container.decode(Date?.self, forKey: .timeEnd)
    self.timeEnd = _timeEnd.flatMap(id)
    
    /*
     "parameters": {
     "date": "2018-10-26T12:00:00+02:00"
     }*/
    
    let _date = try? container.decodeIfPresent(Date.self, forKey: .date)
    self.date = _date.flatMap(id)
    
    /*
     "parameters": {
     "date-start": "2018-10-26T12:00:00+02:00",
     "date-end": "2018-10-31T12:00:00+02:00"
     }*/
    
    let _dateStart = try? container.decode(Date?.self, forKey: .dateStart)
    self.dateStart = _dateStart.flatMap(id)
    
    let _dateEnd = try? container.decode(Date?.self, forKey: .dateEnd)
    self.dateEnd = _dateEnd.flatMap(id)
    
    /*
     "parameters": {
     "date-time-start": "2018-10-26T12:00:00+02:00",
     "date-time-end": "2018-10-31T12:00:00+02:00"
     }*/
    
    let _dateTimeStart = try? container.decode(Date?.self, forKey: .dateTimeStart)
    self.dateTimeStart = _dateTimeStart.flatMap(id)
    
    let _dateTimeEnd = try? container.decode(Date?.self, forKey: .dateTimeEnd)
    self.dateTimeEnd = _dateTimeEnd.flatMap(id)
    
    /*
     "parameters": {
     "date-time-start": { "date_time": "2018-10-26T12:00:00+02:00" },
     "date-time-end": { "date_time": "2018-10-31T12:00:00+02:00" }
     }*/
    
    if dateTimeStart == nil {
      let nestedContainer = try? container
        .nestedContainer(keyedBy: CustomeCodingKeys.self, forKey: .dateTimeStart)
      if let nestedContainer = nestedContainer {
        let _dateTimeStart = try? nestedContainer
          .decode(Date?.self, forKey: CustomeCodingKeys(stringValue: "date_time")!)
        self.dateTimeStart = _dateTimeStart.flatMap(id)
      }
    }
    
    if dateTimeEnd == nil {
      let nestedContainer = try? container
        .nestedContainer(keyedBy: CustomeCodingKeys.self, forKey: .dateTimeEnd)
      if let nestedContainer = nestedContainer {
        let _dateTimeEnd = try? nestedContainer
          .decode(Date?.self, forKey: CustomeCodingKeys(stringValue: "date_time")!)
        self.dateTimeEnd = _dateTimeEnd.flatMap(id)
      }
    }
  }
}
