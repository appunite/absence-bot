import Either
import Foundation
import Html
import HttpPipeline
import HttpPipelineTestSupport
import Optics
import Prelude
import SnapshotTesting
@testable import AbsenceBot

extension Environment {
  public static let mock = Environment(
    logger: .mock,
    slack: .mock,
    calendar: .mock,
    envVars: .mock,
    date: unzurry(.mock),
    uuid: unzurry(.mock),
    calendarTimeZone: unzurry(.mock),
    dialogflowTimeZone: unzurry(.mock)
  )
}

extension Logger {
  public static let mock = Logger(level: .debug, output: .null, error: .null)
}

extension EnvVars {
  public static var mock: EnvVars {
    return EnvVars()
      |> \.appEnv .~ EnvVars.AppEnv.testing
      |> \.postgres.databaseUrl .~ "postgres://absencebot:@localhost:5432/absencebot_test"
  }
}

extension GoogleCalendar {
  public static let mock = GoogleCalendar(
    fetchAuthToken: { pure(pure(.mock)) },
    createEvent: { _, _ in pure(.mock) },
    fetchEvents: { _, _ in pure(.mock) }
  )
}

extension GoogleCalendar.AccessToken {
  public static let mock = GoogleCalendar.AccessToken(
    accessToken: "token",
    expiresIn: 3600,
    tokenType: "oauth"
  )
}

extension GoogleCalendar.OAuthError {
  public static let mock = GoogleCalendar.OAuthError(
    description: "error",
    error: .invalidGrant
  )
}

extension GoogleCalendar.Event {
  public static let mock = GoogleCalendar.Event(
    id: "1",
    colorId: "1",
    htmlLink: URL(string: "https://www.google.com/calendar/event?eid=bDZhMjZxNGI2YmJwN2NkaWk4a2ltZDFoYWcgYXBwdW5pdGUuY29tXzU4OW05dnVrOTF2dWJsbDUwamZmY2R1anZzQGc"),
    created: Date(timeIntervalSince1970: 1546300800),
    updated: Date(timeIntervalSince1970: 1546300800),
    summary: "Jan Kowalski - holiday 🌴",
    description: nil,
    start: .mock,
    end: .mock,
    attendees: [.mock]
  )
}

extension GoogleCalendar.Event.Actor {
  public static let mock = GoogleCalendar.Event.Actor(
    email: "jan@kowalski.com",
    displayName: "Jan Kowlaski"
  )
}

extension GoogleCalendar.Event.DateTime {
  public static let mock = GoogleCalendar.Event.DateTime(
    date: Date(timeIntervalSince1970: 1546344000),
    dateTime: nil
  )
}

extension GoogleCalendar.EventsEnvelope {
  public static let mock = GoogleCalendar.EventsEnvelope(
    token: "token",
    events: [.mock]
  )
}

extension GoogleCalendar.OAuthPayload {
  public static let mock = GoogleCalendar.OAuthPayload(
    iss: "bot@absence.google.com",
    scope: "https://www.googleapis.com/auth/calendar.events",
    aud: "https://www.googleapis.com/oauth2/v4/token",
    iat: Date(timeIntervalSince1970: 1546300800),
    exp: Date(timeIntervalSince1970: 1546300800).addingTimeInterval(3600)
  )
}

extension Absence {
  public static let mock = Absence(
    status: .accepted,
    requester: .left("JAKKOW"),
    interval: .mock,
    reason: .holiday,
    channel: "DDNGJ2SLE",
    reviewer: .left("JAKKOW"),
    event: .mock
  )

  public static let interactiveMessageActionPayloadMock = Absence(
    status: .pending,
    requester: .left("JAKKOW"),
    interval: .mock,
    reason: .holiday,
    channel: "DDNGJ2SLE",
    reviewer: nil,
    event: nil
  )
}

extension AbsenceBot.DateInterval {
  public static let mock = AbsenceBot.DateInterval(
    start: Date(timeIntervalSince1970: 1546344000),
    end: Date(timeIntervalSince1970: 1546430400)
  )
}

extension InteractiveMessageAction {
  public static let mock = InteractiveMessageAction(
    actions: [],
    callbackId: "",
    user: .mock,
    responseURL: URL(string: "https://api.absencebot.com/slack")!,
    originalMessage: .mock
  )

  public static let accept = mock
    |> \.actions .~ [.accept]
    |> \.callbackId .~ ((try? JSONEncoder()
      .encode(Absence.interactiveMessageActionPayloadMock)
      .base64EncodedString()) ?? "")

  public static let silentAccept = mock
    |> \.actions .~ [.silentAccept]
    |> \.callbackId .~ ((try? JSONEncoder()
      .encode(Absence.interactiveMessageActionPayloadMock)
      .base64EncodedString()) ?? "")

  public static let reject = mock
    |> \.actions .~ [.reject]
    |> \.callbackId .~ ((try? JSONEncoder()
      .encode(Absence.interactiveMessageActionPayloadMock)
      .base64EncodedString()) ?? "")
}

extension InteractiveMessageAction.Message {
  public static let mock = InteractiveMessageAction.Message(text: "Some text")
}

extension InteractiveMessageAction.User {
  public static let mock = InteractiveMessageAction.User(id: "U456V5Q4E")
}

extension InteractiveMessageFallback {
  public static let mock = InteractiveMessageFallback(
    text: "text",
    attachments: [.mock],
    responseType: "ephemeral",
    replaceOriginal: true)
}

extension Slack {
  public static let mock = Slack(
    fetchUser: const(pure(pure(.mock))),
    uploadFile: const(pure(pure(.mock))),
    postMessage: const(pure(pure(.mock)))
  )
}

extension Slack.StatusPayload {
  public static let mock = Slack.StatusPayload(ok: true)
}

extension Slack.UserPayload {
  public static let mock = Slack.UserPayload(user: .mock)
}

extension Slack.User {
  public static let mock = Slack.User(
    id: "U456V5Q4E",
    profile: .mock,
    tz: .mock
  )
}

extension Slack.User.Profile {
  public static let mock = Slack.User.Profile(
    name: "Jan Kowlaski",
    email: "jan@kowalski.com"
  )
}

extension Slack.File {
  public static let mock = Slack.File(
    content: Data(),
    channels: "#random",
    filename: "file.txt",
    filetype: "plain/text",
    title: "file")
}

extension Slack.Message {
  public static let mock = Slack.Message(
    text: "some text",
    channel: "#random",
    attachments: [.mock])
}

extension Slack.Message.Attachment {
  public static let mock = Slack.Message.Attachment(
    title: "some title",
    text: "some text",
    footer: "footer",
    ts: .mock,
    color: "#123456",
    fallback: "fallback",
    callbackId: "1",
    fields: [.mock],
    actions: [.mock])
}

extension Slack.Message.Attachment.InteractiveAction {
  public static let mock = Slack.Message.Attachment.InteractiveAction(
    name: "accept",
    type: "button",
    style: nil,
    text: nil,
    value: .accept
  )

  public static let accept = mock
    |> \.name .~ "accept"
    |> \.value .~ .accept

  public static let silentAccept = mock
    |> \.name .~ "silentAccept"
    |> \.value .~ .silentAccept

  public static let reject = mock
    |> \.name .~ "reject"
    |> \.value .~ .reject
}

extension Slack.Message.Attachment.Field {
  public static let mock = Slack.Message.Attachment.Field(title: "title", value: "value", short: true)
}

extension Slack.SlackError {
  public static let mock = Slack.SlackError(error: "error")
}

extension Fulfillment {
  public static let mock = Fulfillment(text: "text", contexts: [.mock])
}

extension Context {
  public static let mock = Context(
    name: URL(string: "projects/absencebot/agent/sessions/676f5d76-6466-4fa6-9df4-659ba7bad991/contexts/absenceday-followup")!,
    lifespanCount: 5,
    parameters: .mock
  )
}

extension Context.Parameters {
  public static let mock = Context.Parameters()

  public static let illnessWithoutDate = mock
    |> \.reason .~ Absence.Reason.illness.rawValue

  public static let illness = mock
    |> \.reason .~ Absence.Reason.illness.rawValue
    |> \.date .~ Date(timeIntervalSince1970: 1546344000)

  public static let holiday = mock
    |> \.reason .~ Absence.Reason.holiday.rawValue
    |> \.date .~ Date(timeIntervalSince1970: 1546344000)

  public static let remote = mock
    |> \.reason .~ Absence.Reason.remote.rawValue
    |> \.date .~ Date(timeIntervalSince1970: 1546344000)

  public static let conference = mock
    |> \.reason .~ Absence.Reason.conference.rawValue
    |> \.date .~ Date(timeIntervalSince1970: 1546344000)

  public static let school = mock
    |> \.reason .~ Absence.Reason.school.rawValue
    |> \.date .~ Date(timeIntervalSince1970: 1546344000)
}

extension Context.Parameters.DatePeriod {
  public static let mock = Context.Parameters.DatePeriod(
    startDate: Date(timeIntervalSince1970: 1546344000),
    endDate: Date(timeIntervalSince1970: 1546430400)
  )
}

extension Context.Parameters.TimePeriod {
  public static let mock = Context.Parameters.TimePeriod(
    startTime: Date(timeIntervalSince1970: 1546344000),
    endTime: Date(timeIntervalSince1970: 1546430400)
  )
}

extension Webhook {
  public static let mock = Webhook(
    session: URL(string: "projects/absencebot/agent/sessions/676f5d76-6466-4fa6-9df4-659ba7bad991")!,
    user: "U456V5Q4E",
    channel: "DDNGJ2SLE",
    action: .fillDate,
    outputContexts: [.mock]
  )

  public static let fillDate = mock
    |> \.action .~ .fillDate
    |> \.outputContexts <<< map <<< \.parameters .~ .illnessWithoutDate

  public static let full = mock
    |> \.action .~ .full
    |> \.outputContexts <<< map <<< \.parameters .~ .illness
}

extension ReportResult {
  public static let mock = ReportResult(event: .mock)
}

extension TimeZone {
  public static let mock = TimeZone(secondsFromGMT: 0)!
}

extension UUID {
  public static let mock = UUID(uuidString: "DEADBEEF-DEAD-BEEF-DEAD-BEEFDEADBEEF")!
}

extension Date {
  public static let mock = Date(timeIntervalSince1970: 1546344000)
}

extension Snapshotting {
  public static var ioConn: Snapshotting<IO<Conn<ResponseEnded, Data>>, String> {
    return Snapshotting<Conn<ResponseEnded, Data>, String>.conn.pullback { io in
      return io.perform()
    }
  }
}

#if os(Linux)
extension SnapshotTestCase {
  public func assertSnapshots<A, B>(
    matching value: A,
    as strategies: [String: Snapshotting<A, B>],
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {
    
    strategies.forEach { name, strategy in
      assertSnapshot(
        matching: value,
        as: strategy,
        named: name,
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
      )
    }
  }
  
  public func assertSnapshots<A, B>(
    matching value: A,
    as strategies: [Snapshotting<A, B>],
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
    ) {
    
    strategies.forEach { strategy in
      assertSnapshot(
        matching: value,
        as: strategy,
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
      )
    }
  }
}
#else
public func assertSnapshots<A, B>(
  matching value: A,
  as strategies: [String: Snapshotting<A, B>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  ) {
  
  strategies.forEach { name, strategy in
    assertSnapshot(
      matching: value,
      as: strategy,
      named: name,
      record: recording,
      timeout: timeout,
      file: file,
      testName: testName,
      line: line
    )
  }
}

public func assertSnapshots<A, B>(
  matching value: A,
  as strategies: [Snapshotting<A, B>],
  record recording: Bool = false,
  timeout: TimeInterval = 5,
  file: StaticString = #file,
  testName: String = #function,
  line: UInt = #line
  ) {
  
  strategies.forEach { strategy in
    assertSnapshot(
      matching: value,
      as: strategy,
      record: recording,
      timeout: timeout,
      file: file,
      testName: testName,
      line: line
    )
  }
}
#endif

public func request(
  with baseRequest: URLRequest,
  basicAuth: Bool = false
  ) -> URLRequest {
  
  var request = baseRequest
  
  // NB: This `httpBody` dance is necessary due to a strange Foundation bug in which the body gets cleared
  //     if you edit fields on the request.
  //     See: https://bugs.swift.org/browse/SR-6687
  let httpBody = request.httpBody
  request.httpBody = httpBody
  request.httpMethod = request.httpMethod?.uppercased()
  
  if basicAuth {
    let username = Current.envVars.basicAuth.username
    let password = Current.envVars.basicAuth.password
    request.allHTTPHeaderFields = request.allHTTPHeaderFields ?? [:]
    request.allHTTPHeaderFields?["Authorization"] =
      "Basic " + Data("\(username):\(password)".utf8).base64EncodedString()
  }

  return request
}

public func request(to route: Route, basicAuth: Bool = false) -> URLRequest {
  return request(
    with: router.request(for: route, base: URL(string: "http://localhost:8080"))!,
    basicAuth: basicAuth
  )
}
