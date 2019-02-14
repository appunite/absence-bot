import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple
import Cryptor

let slackInteractiveMessageActionMiddleware: Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageAction, Data> =
  validateSlackSignature(signature: Current.envVars.slack.secret)
    <<< filter(
      ^\.isAccepted,
      or: sendRejectionMessagesMiddleware
        <| writeStatus(.ok) >=> respond(encoder: JSONEncoder()))
    <<< fetchAcceptanceComponentsMiddleware
    <<< createCalendarEventMiddleware
    <<< sendAcceptanceMessagesMiddleware
    <| writeStatus(.ok) >=> respond(encoder: JSONEncoder())

public func validateSlackSignature<A>(
  signature: String,
  failure: @escaping Middleware<HeadersOpen, ResponseEnded, A, Data> = respond(text: "Wrong signature.")
  )
  -> (@escaping Middleware<StatusLineOpen, ResponseEnded, A, Data>)
  -> Middleware<StatusLineOpen, ResponseEnded, A, Data> {
    return { middleware in
      return { conn in
        let signatureBasicString = zip(with: { "v0:\($0):\($1)" })(
          conn.request.httpHeaderFieldsValue("X-Slack-Request-Timestamp"),
          conn.request.httpBody.flatMap { String(data: $0, encoding: .utf8) }
        ).flatMap { $0.data(using: .utf8) }

        let signature = signature
          .data(using: .utf8)
          .flatMap { HMAC(using: .sha256, key: $0).update(data: signatureBasicString!)?.final() }
          .flatMap { Data(bytes: $0).hexEncodedString() }
          .map {"v0=\($0)" }

        if conn.request.httpHeaderFieldsValue("X-Slack-Signature") == signature {
          return middleware(conn)
        }

        return conn |> unprocessableEntityError(failure)
      }
    }
}

private func sendRejectionMessagesMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageFallback, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageAction, Data> {
  
  return { conn in
    guard let absence = conn.data.absence else {
      return conn
        |> internalServerError(respond(text: "Can't decode absence payload data."))
    }

    return Current.slack.postMessage(.rejectionNotificationMessage(absence: absence))
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case .right(.right):
          // send fallback message about action result
          return conn.map(const(.rejectionFallback(absence: absence)))
            |> middleware

        case let .right(.left(e)):
          return conn
            |> internalServerError(respond(text: e.error))
          
        case let .left(e):
          return conn
            |> internalServerError(respond(text: e.localizedDescription))
        }
    }
  }
}

private func fetchAcceptanceComponentsMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<GoogleCalendar.AccessToken, Absence>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageAction, Data> {
  
  return { conn in
    guard let absence = conn.data.absence else {
      return conn |> internalServerError(respond(text: "Can't decode absence payload data."))
    }

    // fetch requester user
    let requesterUser = Current.slack.fetchUser(absence.requesterId)
      .run
      .parallel
      .map { $0.right?.right?.user }

    // fetch requester user
    let reviewerUser = Current.slack.fetchUser(conn.data.user.id)
      .run
      .parallel
      .map { $0.right?.right?.user }

    // fetch token
    let token = Current.calendar.fetchAuthToken()
      .run
      .parallel
      .map { $0.right?.right }

    return zip3(requesterUser, reviewerUser, token)
      .sequential
      .flatMap { x in
        guard let requesterUser = x.0
          else { return conn |> internalServerError(respond(text: "Can't fetch requester slack user.")) }

        guard let reviewerUser = x.1
          else { return conn |> internalServerError(respond(text: "Can't fetch reviewer slack user.")) }

        guard let token = x.2
          else { return conn |> internalServerError(respond(text: "Can't fetch google auth token.")) }

        let updatedAbsence = absence
          |> \.requester .~ .right(requesterUser)
          |> \.reviewer .~ reviewerUser

        return conn.map(const(token .*. updatedAbsence))
          |> middleware
      }
  }
}

private func createCalendarEventMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, Absence, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<GoogleCalendar.AccessToken, Absence>, Data> {
  
  return { conn in
    let (token, absence) = (get1(conn.data), rest(conn.data))
    let event = calendarEvent(from: absence)

    return Current.calendar.createEvent(token, event)
      .run
      .flatMap { errorOrEvent in
        switch errorOrEvent {
        case let .right(event):
          let updatedAbsence = absence
            |> \.event .~ event

          return conn.map(const(updatedAbsence))
            |> middleware
          
        case let .left(e):
          return conn
            |> internalServerError(respond(text: e.localizedDescription))
        }
    }
  }
}

private func sendAcceptanceMessagesMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageFallback, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, Absence, Data> {
  
  return { conn in
    return Current.slack
      .postMessage(.acceptanceNotificationMessage(absence: conn.data))
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case .right(.right):
          // send fallback message about action result
          return conn.map(const(.acceptanceFallback(absence: conn.data)))
            |> middleware
          
        case let .right(.left(e)):
          return conn
            |> internalServerError(respond(text: e.error))
          
        case let .left(e):
          return conn
            |> internalServerError(respond(text: e.localizedDescription))
        }
    }
  }
}
