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
    case .dialogflow(let payload):
      return conn.map(const(payload))
        |> dialogflowMiddleware
    case .slack(let message):
      return conn.map(const(message))
        |> slackInteractiveMessageActionMiddleware
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
