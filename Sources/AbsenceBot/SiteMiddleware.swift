import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple

public let siteMiddleware: Middleware<StatusLineOpen, ResponseEnded, Prelude.Unit, Data> =
  requestLogger { Current.logger.info($0) }
    <<< responseTimeout(25)
    <<< requireHttps(allowedInsecureHosts: allowedInsecureHosts)
    <<< route(router: router)
    <| render(conn:)

private func render(conn: Conn<StatusLineOpen, Route>)
  -> IO<Conn<ResponseEnded, Data>> {

    switch conn.data {
    case .hello:
      return conn.map(const(unit))
        |> writeStatus(.ok)
        >=> respond(text: "Hello world!")
    case .slack:
      return conn.map(const(unit))
        |> writeStatus(.ok)
        >=> respond(text: "Slack!")
    case .dialogflow(let payload):
      return conn.map(const(payload))
        |> testMiddleware

//      return x |> postSlackMiddleware
//        |> fetchSlackUserMiddleware
//        |> postSlackMiddleware
//        |> uploadFileSlackMiddleware
//        |> fetchAccessTokenGoogleMiddleware
//        >>> requireAccessToken
//        |> addEventGoogleMiddleware
    }
}

private let allowedInsecureHosts: [String] = [
  "127.0.0.1",
  "0.0.0.0",
  "localhost"
]

public func responseTimeout(_ interval: TimeInterval)
  -> (@escaping Middleware<StatusLineOpen, ResponseEnded, Prelude.Unit, Data>)
  -> Middleware<StatusLineOpen, ResponseEnded, Prelude.Unit, Data> {
    
    return { middleware in
      return { conn in
        let timeout = middleware(conn).parallel <|> (
          conn
            |> writeStatus(.internalServerError)
            >=> respond(text: "Response Time-out")
          )
          .delay(interval)
          .parallel
        
        return timeout.sequential
      }
    }
}

import Html
public func respond<A>(json: Data) -> Middleware<HeadersOpen, ResponseEnded, A, Data> {
  return respond(data: json, contentType: .json)
}

//import MediaType
public func respond<A>(data: Data, contentType: MediaType)
  -> Middleware<HeadersOpen, ResponseEnded, A, Data> {
    
    return map(const(data)) >>> pure
      >=> writeHeader(.contentType(contentType))
      >=> writeHeader(.contentLength(data.count))
      >=> closeHeaders
      >=> end
}

public func respond<A: Encodable>(encoder: JSONEncoder) -> Middleware<HeadersOpen, ResponseEnded, A, Data> {
  return { conn in
    conn |> respond(json: try! JSONEncoder().encode(conn.data))
  }
}

let testMiddleware: Middleware<StatusLineOpen, ResponseEnded, Dialogflow, Data> =
  fulfillmentMiddlleware
    >>> requireSlackUserAndDialogflowResponse
    <| writeStatus(.ok) >=> respond(encoder: JSONEncoder())


public func testFetchUser(_ conn: Conn<StatusLineOpen, Dialogflow>)
  -> IO<Conn<StatusLineOpen, Slack.User>> {
    
    return Current.slack.fetchUser(conn.data.user!)
      .run
      .map(^\.right)
      .map { conn.map(const($0!.right!.user)) }
}


//func requireSlack<A>(
//  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<Database.User, A>, Data>
//  )
//  -> Middleware<StatusLineOpen, ResponseEnded, T2<Database.User?, A>, Data> {
//
//    return filterMap(require1 >>> pure, or: loginAndRedirect)
//      <<< filter(get1 >>> ^\.isAdmin, or: redirect(to: .home))
//      <| middleware
//}


public func fetchUser<A>(_ conn: Conn<StatusLineOpen, T2<String, A>>)
  -> IO<Conn<StatusLineOpen, T2<Slack.User?, A>>> {
    
    return Current.slack.fetchUser(get1(conn.data))
      .run
      .map(^\.right)
      .map { conn.map(const($0?.right?.user .*. conn.data.second)) }
}

private func fulfillmentMiddlleware(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, Fulfillment, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, T2<Dialogflow, Slack.User?>, Data> {

  return { conn in
    switch interprete(payload: get1(conn.data), timeZone: TimeZone.current) {
    case let .complete(_, _, fulfillment):
      return conn.map(const(fulfillment))
        |> middleware
    case let .incomplete(fulfillment):
      return conn.map(const(fulfillment))
        |> middleware
    case .report(_, _):
      fatalError()
    }
  }
}

private func requireSlackUserAndDialogflowResponse(
  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<Dialogflow, Slack.User?>, Data>
  ) -> Middleware<StatusLineOpen, ResponseEnded, Dialogflow, Data> {
  
  return { conn in
    guard let user = conn.data.user else {
      return conn |>
        writeStatus(.internalServerError) >=>
        respond(text: "Missing slack user.")
    }

    return Current.slack.fetchUser(user)
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case let .right(.right(payload)):
          return conn.map(const(conn.data .*. payload.user))
            |> middleware
          
        case let .right(.left(e)):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.error)
          
        case let .left(e):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.localizedDescription)
        }
    }
  }
}

//private func dialogflowInterpreterMiddleware(
//  _ conn: Conn<StatusLineOpen, Dialogflow>
//  )
//  -> IO<Conn<ResponseEnded, Data>> {
//    return Current.slack.fetchUser(conn.data)
//      .run
//      .flatMap { errorOrUser in
//        switch errorOrUser {
//        case let .right(.right(payload)):
//          return conn
//            |> writeStatus(.ok)
//            >=> respond(text: "\(payload.user.name)")
//
//        case let .right(.left(e)):
//          return conn
//            |> writeStatus(.internalServerError)
//            >=> respond(text: e.error)
//
//        case let .left(e):
//          return conn
//            |> writeStatus(.internalServerError)
//            >=> respond(text: e.localizedDescription)
//        }
//    }
//}


private func fetchSlackUserMiddleware(
  _ conn: Conn<StatusLineOpen, String>
  )
  -> IO<Conn<ResponseEnded, Data>> {
    return Current.slack.fetchUser(conn.data)
      .run
      .flatMap { errorOrUser in
        switch errorOrUser {
        case let .right(.right(payload)):
          return conn
            |> writeStatus(.ok)
            >=> respond(text: "\(payload.user.name)")

        case let .right(.left(e)):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.error)

        case let .left(e):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.localizedDescription)
        }
    }
}

private func postSlackMiddleware(
  _ conn: Conn<StatusLineOpen, String>
  )
  -> IO<Conn<ResponseEnded, Data>> {
    return Current.slack.postMessage(conn.data, "aU029V5Q4E")
      .run
      .flatMap { errorOrMessage in
        switch errorOrMessage {
        case let .right(.right(payload)):
          return conn
            |> writeStatus(.ok)
            >=> respond(text: "\(payload.ok)")

        case let .right(.left(e)):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.error)

        case let .left(e):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.localizedDescription)
        }
    }
}

private func uploadFileSlackMiddleware(
  _ conn: Conn<StatusLineOpen, String>
  )
  -> IO<Conn<ResponseEnded, Data>> {
    let file = Slack.File(
      content: Data(base64Encoded: "dGV4dA==")!, channels: "U029V5Q4E", filename: "file.txt", filetype: "txt", title: "title")

    return Current.slack.uploadFile(file)
      .run
      .flatMap { errorOrMessage in
        switch errorOrMessage {
        case let .right(.right(payload)):
          return conn
            |> writeStatus(.ok)
            >=> respond(text: "\(payload.ok)")
          
        case let .right(.left(e)):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.error)
          
        case let .left(e):
          return conn
            |> writeStatus(.internalServerError)
            >=> respond(text: e.localizedDescription)
        }
    }
}






//private func fetchAccessTokenGoogleMiddleware(
//  _ conn: Conn<StatusLineOpen, String>
//  )
//  -> IO<Conn<ResponseEnded, Calendar.AccessToken>> {
//    
//    return Current.calendar.fetchAuthToken()
//      .run
//      .flatMap { errorOrMessage in
//        switch errorOrMessage {
//        case let .right(.right(payload)):
//          return conn
//            |> writeStatus(.ok)
//            >=> respond(text: "\(payload.accessToken)")
//          
//        case let .right(.left(e)):
//          return conn
//            |> writeStatus(.internalServerError)
//            >=> respond(text: e.error.rawValue)
//          
//        case let .left(e):
//          return conn
//            |> writeStatus(.internalServerError)
//            >=> respond(text: e.localizedDescription)
//        }
//    }
//}
//
//private func requireAccessToken<A>(
//  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, T2<Calendar.AccessToken, A>, Data>
//  )
//  -> Middleware<StatusLineOpen, ResponseEnded, A, Data> {
//
//    return { conn in
//      return Current.calendar.fetchAuthToken()
//        .run
//        .flatMap { errorOrToken in
//          switch errorOrToken {
//          case let .right(.right(payload)):
//            return conn.map(const(payload.accessToken))
//              |> middleware
//
//          case let .right(.left(e)):
//            return conn
//              |> writeStatus(.internalServerError)
//              >=> respond(text: e.error.rawValue)
//
//          case let .left(e):
//            return conn
//              |> writeStatus(.internalServerError)
//              >=> respond(text: e.localizedDescription)
//          }
//      }
//    }
//}
//
//private func addEventGoogleMiddleware(
//  _ conn: Conn<StatusLineOpen, Calendar.AccessToken>
//  )
//  -> IO<Conn<ResponseEnded, Data>> {
//
//    let event = Calendar.Event(
//      id: nil,
//      colorId: 1,
//      htmlLink: nil,
//      created: nil,
//      updated: nil,
//      summary: "T##String?",
//      description: "T##String?",
//      attendees: [.init(email: "emil@appunite.com", displayName: "Emil Wojtaszek")],
//      start: Calendar.Event.DateTime.init(date: Date(), dateTime: nil),
//      end: Calendar.Event.DateTime.init(date: Date(), dateTime: nil))
//    
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
//}
