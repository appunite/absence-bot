import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple

let calendarMiddleware: Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageAction, Data> =
//  pendingMiddleware
  rejectionMiddleware
//    >>> validateSlackSignature(signature: Current.envVars.slack.signature)
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

private func pendingMiddleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageFallback, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, InteractiveMessageAction, Data> {
  
  return { conn in
    guard let value = conn.data.actions.first?.value else {
      return conn
        |> internalServerError(respond(text: "WTF"))
    }

    switch value {
    case .accept:
      print("accept")
    case .reject:
      print("reject")
    }

    //
    parallel(slack(conn.data.user.id).run)
      .run { x in print(x.right) }

    //
    return conn.map(const(conn.data.pendingFallback()))
      |> middleware
  }
}

private func slack(_ id: String)
  -> EitherIO<Error, Slack.User> {
    return Current.slack.fetchUser(id)
      .flatMap { errorOrUser in
        
        switch errorOrUser {
        case let .right(payload):
          return EitherIO.init(
            run: .init { callback in callback(.right(payload.user)) }
          )

        case let .left(e):
          return EitherIO.init(
            run: .init { callback in callback(.left(NSError.init(domain: "error", code: 0))) } //e.error
          )
//          return EitherIO.init(
//            run: .init { callback in callback(.left(e)) }
//          )
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

private func eventGoogleMiddleware(absence: Absence)
  -> EitherIO<Error, GoogleCalendar.Event> {
    
    let event = GoogleCalendar.Event(
      id: nil,
      colorId: 1,
      htmlLink: nil,
      created: nil,
      updated: nil,
      summary: "T##String?",
      description: "T##String?",
      attendees: [.init(email: "emil@appunite.com", displayName: "Emil Wojtaszek")],
      start: GoogleCalendar.Event.DateTime.init(date: Date(), dateTime: nil),
      end: GoogleCalendar.Event.DateTime.init(date: Date(), dateTime: nil))
    
    
//    return Current.calendar.fetchAuthToken()
//      .flatMap { errorOrToken in
//        switch errorOrToken {
//        case let .right(token):
//          return Current.calendar.createEvent(token, event)
//            .run
//            .flatMap { event in
//              let t = lift(Either<Error, GoogleCalendar.Event>.right(event))
//
//              fatalError()
//          }
//        case let .left(e):
//          return EitherIO.init(
//            run: .init { callback in callback(.left(e.error)) }
//          )
//        }
//      }

//        x
//      .flatMap
//    return Current.calendar.createEvent(conn.data, event)
//      .run
//      .flatMap { errorOrMessage in
//        switch errorOrMessage {
//        case let .right(payload):
//          return conn
//            |> writeStatus(.ok)
//            >=> respond(text: "\(payload.summary)")
//
//        case let .left(e):
//          return conn
//            |> writeStatus(.internalServerError)
//            >=> respond(text: e.localizedDescription)
//        }
//    }
    
    fatalError()
}

private func googleAccessToken()
  -> EitherIO<Error, Either<GoogleCalendar.OAuthError, GoogleCalendar.AccessToken>> {
fatalError()
//    return Current.calendar.fetchAuthToken()
//      .run
//      .flatMap { errorOrToken in
//        switch errorOrToken {
//        case let .right(.right(payload)):
//          return EitherIO.init(
//            run: .init { callback in callback(.right(payload)) }
//          )
//
//        case let .right(.left(e)):
//          return EitherIO.init(
//            run: .init { callback in callback(.left(NSError.init(domain: "error", code: 0))) } //e.error
//          )
//
//        case let .left(e):
//          return EitherIO.init(
//            run: .init { callback in callback(.left(NSError.init(domain: "error", code: 0))) } //e.error
//          )
//        }
//    }
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

private func createCalendarEventMiddleware<A>(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T3<InteractiveMessageAction, GoogleCalendar.Event, A>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T3<InteractiveMessageAction, GoogleCalendar.AccessToken, A>, Data> {
  
  return { conn in
    
    let (action, token) = (get1(conn.data), get2(conn.data))

    let event = GoogleCalendar.Event(
      id: nil,
      colorId: 1,
      htmlLink: nil,
      created: nil,
      updated: nil,
      summary: "T##String?",
      description: "T##String?",
      attendees: [.init(email: "emil@appunite.com", displayName: "Emil Wojtaszek")],
      start: GoogleCalendar.Event.DateTime.init(date: Date(), dateTime: nil),
      end: GoogleCalendar.Event.DateTime.init(date: Date(), dateTime: nil))

    return Current.calendar.createEvent(token, event)
      .run
      .flatMap { errorOrEvent in
        switch errorOrEvent {
        case let .right(event):
          return conn.map(const(action .*. event .*. rest(conn.data)))
            |> middleware

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

    return Current.slack.postMessage(.rejectionNotificationMessage(requester: absence.user.id))
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case .right(.right):
          // send fallback message about action result
          return conn.map(const(conn.data.rejectionFallback(requester: absence.user.id)))
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
