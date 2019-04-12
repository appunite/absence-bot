import Foundation

public var Current = Environment()

public struct Environment {
  public private(set) var logger = Logger()
  public private(set) var slack = Slack.live
  public private(set) var calendar = GoogleCalendar.live
  public private(set) var envVars = EnvVars()
  public private(set) var date: () -> Date = Date.init
  public private(set) var uuid: () -> UUID = UUID.init
  public private(set) var hqTimeZone: () -> TimeZone = { TimeZone(identifier: "Europe/Warsaw")! }
  public private(set) var dialogflowTimeZone: () -> TimeZone = { TimeZone(identifier: "Europe/Madrid")! }
}
