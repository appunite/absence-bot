import Foundation

public struct Context: Codable, Equatable {
  public private(set) var name: String
  public private(set) var lifespanCount: Int
  public private(set) var parameters: Parameters
  
  public struct Parameters: Codable, Equatable {
    // @reason
    public private(set) var reason: String?
    // @sys.date-period
    public private(set) var datePeriod: Period?
    // @sys.date
    public private(set) var date: Date?
    // @sys.date
    public private(set) var dateStart: Date?
    // @sys.date
    public private(set) var dateEnd: Date?
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
    
    public init() {}
    
    public struct Period: Codable, Equatable {
      public private(set) var startDate: Date
      public private(set) var endDate: Date
    }
    
    enum CodingKeys: String, CodingKey {
      case reason
      case datePeriod = "date-period"
      case date
      case dateStart = "date-start"
      case dateEnd = "date-end"
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
    self.reason = _reason.flatMap { $0 }
    
    let _datePeriod = try? container.decode(Period.self, forKey: .datePeriod)
    self.datePeriod = _datePeriod.flatMap({ $0 })
    
    let _dates = try? container.decodeIfPresent([Date].self, forKey: .dates)
    self.dates = _dates.flatMap { $0 }
    
    let _timeStart = try? container.decode(Date?.self, forKey: .timeStart)
    self.timeStart = _timeStart.flatMap({ $0 })
    
    let _timeEnd = try? container.decode(Date?.self, forKey: .timeEnd)
    self.timeEnd = _timeEnd.flatMap { $0 }
    
    /*
     "parameters": {
     "date": "2018-10-26T12:00:00+02:00"
     }*/
    
    let _date = try? container.decodeIfPresent(Date.self, forKey: .date)
    self.date = _date.flatMap { $0 }
    
    /*
     "parameters": {
     "date-start": "2018-10-26T12:00:00+02:00",
     "date-end": "2018-10-31T12:00:00+02:00"
     }*/
    
    let _dateStart = try? container.decode(Date?.self, forKey: .dateStart)
    self.dateStart = _dateStart.flatMap({ $0 })
    
    let _dateEnd = try? container.decode(Date?.self, forKey: .dateEnd)
    self.dateEnd = _dateEnd.flatMap { $0 }
    
    /*
     "parameters": {
     "date-time-start": "2018-10-26T12:00:00+02:00",
     "date-time-end": "2018-10-31T12:00:00+02:00"
     }*/
    
    let _dateTimeStart = try? container.decode(Date?.self, forKey: .dateTimeStart)
    self.dateTimeStart = _dateTimeStart.flatMap({ $0 })
    
    let _dateTimeEnd = try? container.decode(Date?.self, forKey: .dateTimeEnd)
    self.dateTimeEnd = _dateTimeEnd.flatMap { $0 }
    
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
        self.dateTimeStart = _dateTimeStart.flatMap({ $0 })
      }
    }
    
    if dateTimeEnd == nil {
      let nestedContainer = try? container
        .nestedContainer(keyedBy: CustomeCodingKeys.self, forKey: .dateTimeEnd)
      if let nestedContainer = nestedContainer {
        let _dateTimeEnd = try? nestedContainer
          .decode(Date?.self, forKey: CustomeCodingKeys(stringValue: "date_time")!)
        self.dateTimeEnd = _dateTimeEnd.flatMap({ $0 })
      }
    }
  }
}
