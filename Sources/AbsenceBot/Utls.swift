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

public func zip<A, B>(_ a: A?, _ b: B?) -> (A, B)? {
  guard let a = a, let b = b else { return nil }
  return (a, b)
}

public func zip<A, B, C>(_ a: A?, _ b: B?, _ c: C?) -> (A, B, C)? {
  return zip(a, zip(b, c)).map ({ ($0.0, $0.1.0, $0.1.1)})
}

public func zip<A, B, C>(with transform: @escaping (A, B) -> C) -> (A?, B?) -> C? {
  return { zip($0, $1).map(transform) }
}

public func zip<A, B, C, D>(with transform: @escaping (A, B, C) -> D) -> (A?, B?, C?) -> D? {
  return { zip($0, $1, $2).map(transform) }
}

public func zip2<A, B>(_ lhs: Parallel<A>, _ rhs: Parallel<B>) -> Parallel<(A, B)> {
  return tuple <¢> lhs <*> rhs
}

public func zip3<A, B, C>(_ a: Parallel<A>, _ b: Parallel<B>, _ c: Parallel<C>) -> Parallel<(A, B, C)> {
  return tuple3 <¢> a <*> b <*> c
}

// Calendar

extension Calendar {
  static let currentTimeZoneCalendar = Calendar(identifier: .iso8601)
    |> \.timeZone .~ TimeZone.current
  
  static let gmtTimeZoneCalendar = Calendar(identifier: .iso8601)
    |> \.timeZone .~ TimeZone(secondsFromGMT: 0)!
}

// Date

extension Date {
  internal func startOfDay(calendar: Calendar? = nil) -> Date {
    return (calendar ?? Calendar.currentTimeZoneCalendar)
      .startOfDay(for: self)
  }
  
  internal func endOfDay(calendar: Calendar? = nil) -> Date {
    let _calendar = calendar ?? Calendar.currentTimeZoneCalendar
    
    let endComponents = DateComponents()
      |> \.day .~ 1
      |> \.second .~ -1
    
    let startOfDay = self.startOfDay(calendar: _calendar)
    return _calendar.date(byAdding: endComponents, to: startOfDay)!
  }
}

extension Date {
  internal func dateByReplacingTime(from sourceDate: Date) -> Date? {
    let calendar = Calendar.gmtTimeZoneCalendar
    
    // get dates components
    let dateComponentsB = calendar.dateComponents(
      [.hour, .minute, .second], from: sourceDate)
    let dateComponentsA = calendar.dateComponents(
      [.year, .month, .day], from: self)
    
    // create combined date components
    let combinedDateComponents = DateComponents(
      calendar: calendar,
      timeZone: TimeZone(secondsFromGMT: 0),
      year: dateComponentsA.year,
      month: dateComponentsA.month,
      day: dateComponentsA.day,
      hour: dateComponentsB.hour,
      minute: dateComponentsB.minute,
      second: dateComponentsB.second)
    
    // return new date
    return calendar.date(from: combinedDateComponents)
  }
  
  internal func dateByReplacingTimeZone(timeZone: TimeZone) -> Date? {
    let calendar = Calendar.gmtTimeZoneCalendar
    
    // get dates components
    let dateComponentsA = calendar.dateComponents(
      [.year, .month, .day, .hour, .minute, .second], from: self)
    
    // create combined date components
    let dateComponentsB = DateComponents(
      calendar: calendar,
      timeZone: timeZone,
      year: dateComponentsA.year,
      month: dateComponentsA.month,
      day: dateComponentsA.day,
      hour: dateComponentsA.hour,
      minute: dateComponentsA.minute,
      second: dateComponentsA.second
    )
    
    // return new date
    return calendar.date(from: dateComponentsB)
  }
}
