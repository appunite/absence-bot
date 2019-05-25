import Foundation

public var Current = Environment()

public struct Environment {
  public var logger = Logger()
  public var slack = Slack.live
  public var calendar = GoogleCalendar.live
  public var envVars = EnvVars()
  public var date: () -> Date = Date.init
  public var uuid: () -> UUID = UUID.init
  // time zone used in google calendar
  public var calendarTimeZone: () -> TimeZone = { TimeZone(identifier: "Europe/Warsaw")! }
  // timezone defined is settings of dialogflow
  public var dialogflowTimeZone: () -> TimeZone = { TimeZone(identifier: "Europe/Madrid")! }
}
