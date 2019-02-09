import ApplicativeRouterHttpPipelineSupport
import Either
import Foundation
import HttpPipeline
import Optics
import Prelude
import Tuple
import Html

public let appMiddleware: Middleware<StatusLineOpen, ResponseEnded, Prelude.Unit, Data> =
  requestLogger { Current.logger.info($0) }
    <<< responseTimeout(25)
    <<< requireHttps(allowedInsecureHosts: allowedInsecureHosts)
    <<< route(router: router)
    <| render(conn:)

public func internalServerError<A>(_ middleware: @escaping Middleware<HeadersOpen, ResponseEnded, A, Data>)
  -> Middleware<StatusLineOpen, ResponseEnded, A, Data> {
    return writeStatus(.internalServerError)
      >=> middleware
}

public func unprocessableEntityError<A>(_ middleware: @escaping Middleware<HeadersOpen, ResponseEnded, A, Data>)
  -> Middleware<StatusLineOpen, ResponseEnded, A, Data> {
    return writeStatus(.unprocessableEntity)
      >=> middleware
}

private func render(conn: Conn<StatusLineOpen, Route>)
  -> IO<Conn<ResponseEnded, Data>> {

    switch conn.data {
    case .hello:
      return conn.map(const(unit))
        |> writeStatus(.ok)
        >=> respond(text: "Hello world!")
    case .slack(let message):
      return conn.map(const(unit))
        |> writeStatus(.ok)
        >=> respond(text: "Slack!")
    case .dialogflow(let payload):
      return conn.map(const(payload))
        |> dialogflowMiddleware
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
            |> internalServerError(respond(text: "Response Time-out"))
          )
          .delay(interval)
          .parallel

        return timeout.sequential
      }
    }
}

public func respond<A>(json: Data) -> Middleware<HeadersOpen, ResponseEnded, A, Data> {
  return respond(data: json, contentType: .json)
}

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

//private func postSlackMiddleware(
//  _ middleware: @escaping Middleware<StatusLineOpen, ResponseEnded, Slack.StatusPayload, Data>
//  ) -> Middleware<StatusLineOpen, ResponseEnded, Slack.Message, Data> {
//
//  return { conn in
//    return Current.slack.postMessage(conn.data)
//      .run
//      .flatMap { errorOrMessage in
//        switch errorOrMessage {
//        case let .right(.right(payload)):
//          return conn.map(const(payload))
//            |> middleware
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
//  }
//}

//private func uploadFileSlackMiddleware(
//  _ conn: Conn<StatusLineOpen, String>
//  )
//  -> IO<Conn<ResponseEnded, Data>> {
//    let file = Slack.File(
//      content: Data(base64Encoded: "dGV4dA==")!, channels: "U029V5Q4E", filename: "file.txt", filetype: "txt", title: "title")
//
//    return Current.slack.uploadFile(file)
//      .run
//      .flatMap { errorOrMessage in
//        switch errorOrMessage {
//        case let .right(.right(payload)):
//          return conn
//            |> writeStatus(.ok)
//            >=> respond(text: "\(payload.ok)")
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
