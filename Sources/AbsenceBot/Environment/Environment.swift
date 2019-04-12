import Foundation

public var Current = Environment()

public struct Environment {
  public private(set) var logger = Logger()
  public private(set) var slack = Slack.live
  public private(set) var calendar = GoogleCalendar.live
  public private(set) var envVars = EnvVars()
  public private(set) var date: () -> Date = Date.init
  public private(set) var uuid: () -> UUID = UUID.init
  // time zone used in google calendar
  public private(set) var calendarTimeZone: () -> TimeZone = { TimeZone(identifier: "Europe/Warsaw")! }
  // timezone defined is settings of dialogflow
  public private(set) var dialogflowTimeZone: () -> TimeZone = { TimeZone(identifier: "Europe/Madrid")! }
}
