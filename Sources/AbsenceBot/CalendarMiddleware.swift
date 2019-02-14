import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple

let calendarMiddleware: Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageAction, Data> =
//  rejectionMiddleware
  
  validateSlackSignature(signature: Current.envVars.slack.signature)
    <<< acceptanceComponentsMiddleware
    <<< acceptanceCalendarEventMiddleware
    <<< acceptanceMessagesMiddleware
    <| writeStatus(.ok) >=> respond(encoder: JSONEncoder())

public func validateSlackSignature<A>(
  signature: String,
  failure: @escaping Middleware<HeadersOpen, ResponseEnded, A, Data> = respond(text: "Wrong signature.")
  )
  -> (@escaping Middleware<StatusLineOpen, ResponseEnded, A, Data>)
  -> Middleware<StatusLineOpen, ResponseEnded, A, Data> {
    return { middleware in
      return { conn in
        guard let header = conn.request.allHTTPHeaderFields?.first(where: { $0.key == "X-Slack-Signature" }), header.value == signature
          else { return conn |> unprocessableEntityError(failure) }
        
        return middleware(conn)
      }
    }
}

public func requireSome<A>(_ e: Either<Error, A?>) -> Either<Error, A> {
  switch e {
  case let .left(e):
    return .left(e)
  case let .right(a):
    return a.map(Either.right) ?? .left(unit)
  }
}

private func googleAccessTokenMiddleware<A>(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T3<InteractiveMessageAction, GoogleCalendar.AccessToken, A>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<InteractiveMessageAction, A>, Data> {

  return { conn in
    return Current.calendar.fetchAuthToken()
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case let .right(.right(token)):
          return conn.map(const(conn.data.first .*. token .*. conn.data.second))
            |> middleware
          
        case let .right(.left(e)):
          return conn
            |> internalServerError(respond(text: e.error.rawValue))
          
        case let .left(e):
          return conn
            |> internalServerError(respond(text: e.localizedDescription))
        }
    }
  }
}

private func slackUserMiddleware<A>(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T3<InteractiveMessageAction, Slack.User, A>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<InteractiveMessageAction, A>, Data> {
  
  return { conn in
    return Current.slack.fetchUser(conn.data.first.user.id)
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case let .right(.right(payload)):
          return conn.map(const(conn.data.first .*. payload.user .*. conn.data.second))
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

private func rejectionMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageFallback, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageAction, Data> {
  
  return { conn in
    guard let absence = conn.data.absence else {
      return conn
        |> internalServerError(respond(text: "Can't decode absence payload data."))
    }

    return Current.slack.postMessage(.rejectionNotificationMessage(requester: absence.requesterId))
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case .right(.right):
          // send fallback message about action result
          return conn.map(const(conn.data.rejectionFallback(requester: absence.requesterId)))
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

private func acceptanceComponentsMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T3<Absence, GoogleCalendar.AccessToken, InteractiveMessageAction>, Data>
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
        
//        zip(with: {
//          let updatedAbsence = absence
//            |> \.user .~ $0
//
//          return conn.map(const(updatedAbsence .*. $2 .*. conn.data))
//            |> middleware
//        })(c.0, c.1, c.2)
//
//        guard let x = zip(c.0, zip(c.1, c.2)).map ({ ($0.0, $0.1.0, $0.1.1)}) else {
//          fatalError()
//        }
        
        guard let requesterUser = x.0
          else { return conn |> internalServerError(respond(text: "Can't fetch user.")) }

        guard let reviewerUser = x.1
          else { return conn |> internalServerError(respond(text: "Can't fetch user.")) }

        guard let token = x.2
          else { return conn |> internalServerError(respond(text: "Can't fetch token.")) }

        let updatedAbsence = absence
          |> \.requester .~ .right(requesterUser)
          |> \.reviewer .~ reviewerUser

        return conn.map(const(updatedAbsence .*. token .*. conn.data))
          |> middleware
      }
  }
}

private func acceptanceCalendarEventMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T3<InteractiveMessageAction, Absence, GoogleCalendar.Event>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T3<Absence, GoogleCalendar.AccessToken, InteractiveMessageAction>, Data> {
  
  return { conn in
    let (absence, token, action) = (get1(conn.data), get2(conn.data), rest(conn.data))
    let event = calendarEvent(from: absence)

    return Current.calendar.createEvent(token, event)
      .run
      .flatMap { errorOrEvent in
        switch errorOrEvent {
        case let .right(event):
          return conn.map(const(action .*. absence .*. event))
            |> middleware
          
        case let .left(e):
          return conn
            |> internalServerError(respond(text: e.localizedDescription))
        }
    }
  }
}

private func acceptanceMessagesMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageFallback, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T3<InteractiveMessageAction, Absence, GoogleCalendar.Event>, Data> {
  
  return { conn in
    let (action, absence, event) = (get1(conn.data), get2(conn.data), rest(conn.data))

    return Current.slack
      .postMessage(.acceptanceNotificationMessage(channel: absence.requesterId.rawValue, eventLink: event.htmlLink, reason: absence.reason))
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case .right(.right):
          // send fallback message about action result
          return conn.map(const(action.acceptanceFallback(requester: absence.requesterId, eventLink: event.htmlLink)))
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

private func calendarEvent(from absence: Absence) -> GoogleCalendar.Event {
  return .init(
    id: nil,
    colorId: "2",
    htmlLink: nil,
    created: nil,
    updated: nil,
    summary: "\(absence.requester.right!.profile!.name) - \(absence.reason.rawValue)",
    description: nil,
    start: startDateTime(from: absence.period),
    end: endDateTime(from: absence.period),
    attendees: [
      .init(email: absence.requester.right!.profile!.email, displayName: absence.requester.right!.profile!.name),
      .init(email: absence.reviewer!.profile!.email, displayName: absence.reviewer!.profile!.name)
    ]
  )
}

private func startDateTime(from period: Absence.Period) -> GoogleCalendar.Event.DateTime {
  if period.isAllDay {
    return .init(date: period.startedAt, dateTime: nil)
  }
  return .init(date: nil, dateTime: period.startedAt)
}

private func endDateTime(from period: Absence.Period) -> GoogleCalendar.Event.DateTime {
  if period.isAllDay {
    return .init(date: period.finishedAt, dateTime: nil)
  }
  return .init(date: nil, dateTime: period.finishedAt)
}
