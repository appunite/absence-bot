import Foundation

public struct Dialogflow: Codable, Equatable {
  public private(set) var session: String
  public private(set) var user: String?
  public private(set) var action: Dialogflow.Action
  public private(set) var outputContexts: [Context]
  
  private enum OriginalDetectIntentRequestCodingKeys: String, CodingKey {
    case payload
  }

  private enum SlackPayloadCodingKeys: String, CodingKey {
    case data
  }

  private enum SlackDataCodingKeys: String, CodingKey {
    case event
  }

  private enum SlackEventCodingKeys: String, CodingKey {
    case user
  }

  private enum CustomCodingKeys: String, CodingKey {
    case session
    case queryResult
    case originalDetectIntentRequest
  }

  private enum QueryResultCodingKeys: String, CodingKey {
    case action
    case outputContexts
  }

  public enum Action: String, Codable, Equatable {
    case full = "absenceday.absenceday-full"
    case fillDate = "absenceday.absenceday-fill-date"
    case accept = "absenceday.absenceday-yes"
    case report = "absenceday.absence-report"
  }
  
  public enum Reason: String, Codable, Equatable {
    case illness
    case holiday
    case remote
    case conference
    case school
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CustomCodingKeys.self)

    // session indetifier
    let _session = try container.decode(String.self, forKey: .session)
    self.session = _session

    // contextes
    let queryResult = try container.nestedContainer(keyedBy: QueryResultCodingKeys.self, forKey: .queryResult)
    self.action = try queryResult.decode(Dialogflow.Action.self, forKey: .action)
    self.outputContexts = try queryResult
      .decodeIfPresent([Throwable<Context>].self, forKey: .outputContexts)?
      .compactMap ({ $0.value }) ?? []

    // slack data
    let originalDetectIntentRequest = try container
      .nestedContainer(keyedBy: Dialogflow.OriginalDetectIntentRequestCodingKeys.self, forKey: .originalDetectIntentRequest)
    let payload = try originalDetectIntentRequest
      .nestedContainer(keyedBy: Dialogflow.SlackPayloadCodingKeys.self, forKey: .payload)
    let event = try payload
      .nestedContainer(keyedBy: Dialogflow.SlackDataCodingKeys.self, forKey: .data)
    let user = try event
      .nestedContainer(keyedBy: Dialogflow.SlackEventCodingKeys.self, forKey: .event)
    self.user = try user.decodeIfPresent(String.self, forKey: .user)
  }
}

public struct Context: Codable, Equatable {
  public private(set) var name: ContextName
  public private(set) var lifespanCount: Int
  public private(set) var parameters: Parameters
  
  public struct Parameters: Codable, Equatable {
    // @reason
    public private(set) var reason: Dialogflow.Reason?
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
    
    let _reason = try? container.decodeIfPresent(Dialogflow.Reason.self, forKey: .reason)
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

public struct ContextName: RawRepresentable, Equatable {
  public enum Identifier: String {
    case followup = "absenceday-followup"
    case full = "absenceday-full"
    case report = "absence-report-followup"
  }
  
  public private(set) var rawValue: String
  public init?(rawValue: String) {
    self.rawValue = rawValue
  }
  
  public var identifier: Identifier? {
    return URL(string: rawValue)
      .flatMap { Identifier(rawValue: $0.lastPathComponent) }
  }
  
  public init?(session: String, identifier: Identifier) {
    guard let rawValue = URL(string: session)?
      .appendingPathComponent("contexts")
      .appendingPathComponent(identifier.rawValue)
      .absoluteString else { return nil }
    
    self.rawValue = rawValue
  }
}

extension ContextName: Codable {
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(self.rawValue)
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let value = try container.decode(String.self)
    
    //
    guard let initialized = type(of: self).init(rawValue: value)
      else { throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Can't initialize ContextName structure.") }
    self = initialized
  }
}

