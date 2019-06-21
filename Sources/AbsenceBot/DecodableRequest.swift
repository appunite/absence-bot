import Foundation
import Either
import Optics
import Prelude
import Tagged

enum JSONError: Error {
  case error(String, Error)
}

public typealias DecodableRequest<A> = Tagged<A, URLRequest> where A: Decodable

public func jsonDataTask<A>(with request: URLRequest, decoder: JSONDecoder? = nil)
  -> EitherIO<Error, A>
  where A: Decodable {

    return dataTask(with: request)
      .map(first)
      .flatMap { data in
        .wrap {
          do {
            return try (decoder ?? defaultDecoder).decode(A.self, from: data)
          } catch {
            throw JSONError.error(String(decoding: data, as: UTF8.self), error)
          }
        }
    }
}

public func dataTask(with request: URLRequest) -> EitherIO<Error, (Data, URLResponse)> {
  return .init(
    run: .init { callback in
      let session = URLSession(configuration: .default)
      session
        .dataTask(with: request) { data, response, error in
          defer { session.finishTasksAndInvalidate() }
          if let error = error {
            callback(.left(error))
          }
          if let data = data, let response = response {
            callback(.right((data, response)))
          }
        }
        .resume()
    }
  )
}

private let defaultDecoder = JSONDecoder()
