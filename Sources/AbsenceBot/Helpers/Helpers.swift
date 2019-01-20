import Either
import Foundation
import Optics
import Prelude
import UrlFormEncoding

// PreludeFoundation

private let guaranteeHeaders = \URLRequest.allHTTPHeaderFields %~ {
  $0 ?? [:]
}

let setHeader = { name, value in
  guaranteeHeaders
    <> (\.allHTTPHeaderFields <<< map <<< \.[name] .~ value)
}

func attachBasicAuth(username: String = "", password: String = "") -> (URLRequest) -> URLRequest {
  let encoded = Data((username + ":" + password).utf8).base64EncodedString()
  return setHeader("Authorization", "Basic " + encoded)
}

let attachFormData =
  urlFormEncode(value:)
    >>> ^\.utf8
    >>> Data.init(_:)
    >>> set(\URLRequest.httpBody)

// Prelude

public func concat<A>(_ fs: [(A) -> A]) -> (A) -> A {
  return { a in
    fs.reduce(a) { a, f in f(a) }
  }
}

public func concat<A>(_ fs: ((A) -> A)..., and fz: @escaping (A) -> A = id) -> (A) -> A {
  return concat(fs + [fz])
}

public func concat<A>(_ fs: [(inout A) -> Void]) -> (inout A) -> Void {
  return { a in
    fs.forEach { f in f(&a) }
  }
}

public func concat<A>(_ fs: ((inout A) -> Void)..., and fz: @escaping (inout A) -> Void = { _ in })
  -> (inout A) -> Void {
    
    return concat(fs + [fz])
}

// Prelude / Overture

public func update<A>(_ value: inout A, _ changes: ((A) -> A)...) {
  value = value |> concat(changes)
}

public func update<A>(_ value: inout A, _ changes: ((inout A) -> Void)...) {
  concat(changes)(&value)
}

func zip2<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
  guard let a = a, let b = b else { return nil }
  return (a, b)
}
