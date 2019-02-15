import Cryptor
import Either
import Foundation
import Html
import HttpPipeline
import HttpPipelineTestSupport
import Optics
import Prelude
import SnapshotTesting
@testable import AbsenceBot

extension TimeZone {
  public static let mock = TimeZone(secondsFromGMT: 0)!
}

extension Logger {
  public static let mock = Logger.init(level: .debug, output: .null, error: .null)
}

extension EnvVars {
  public static var mock: EnvVars {
    return EnvVars()
      |> \.appEnv .~ EnvVars.AppEnv.testing
      |> \.postgres.databaseUrl .~ "postgres://pointfreeco:@localhost:5432/pointfreeco_test"
  }
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
    requester: .left("JAKKOW"),
    period: .mock,
    reason: .holiday,
    status: .approved,
    reviewer: .left("JAKKOW"),
    event: .mock
  )
}

extension Absence.Period {
  public static let mock = Absence.Period(
    startedAt: Date(timeIntervalSince1970: 1546344000),
    finishedAt: Date(timeIntervalSince1970: 1546430400)
  )
}

extension InteractiveMessageAction {
  public static let mock = InteractiveMessageAction.init(
    actions: [.mock],
    callbackId: "id", // todo
    user: .mock,
    responseURL: URL(string: "https://api.absencebot.com/slack")!,
    originalMessage: .mock
  )
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
  public static let mock = Slack.User.Profile(name: "Jan Kowlaski", email: "jan@kowalski.com")
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
    text: "some text",
    fallback: "fallback",
    callbackId: "1",
    actions: nil)
}

extension Slack.Message.Attachment.InteractiveAction {
  public static let mock = Slack.Message.Attachment.InteractiveAction(
    name: "accept",
    text: "accept",
    type: "button",
    value: .accept
  )
}

extension Slack.SlackError {
  public static let mock = Slack.SlackError.init(error: "error")
}

extension Fulfillment {
  public static let mock = Fulfillment(text: "text", contexts: [.mock])
}

extension Context {
  public static let mock = Context(
    name: URL(string: "/context/1/absenceday-full")!,
    lifespanCount: 1,
    parameters: .mock
  )
}

extension Context.Parameters {
  public static let mock = Context.Parameters.init() //todo
}

extension Context.Parameters.Period {
  public static let mock = Context.Parameters.Period(
    startDate: Date(timeIntervalSince1970: 1546344000),
    endDate: Date(timeIntervalSince1970: 1546430400)
  )
}

extension Webhook {
  public static let mock = Webhook(
    session: URL(string: "/context/1")!,
    user: "U456V5Q4E",
    action: .full,
    outputContexts: [.mock]
  )
}
