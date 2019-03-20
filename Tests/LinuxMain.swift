// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import XCTest

extension AppMiddlewareTests {
  static var allTests: [(String, (AppMiddlewareTests) -> () throws -> Void)] = [
    ("testWithHttps", testWithHttps)
  ]
}
extension DialogflowTests {
  static var allTests: [(String, (DialogflowTests) -> () throws -> Void)] = [
    ("testFillDateContextDialogflow", testFillDateContextDialogflow),
    ("testFullActionDialogflow", testFullActionDialogflow),
    ("testFullActionDialogflowWithTodayAndTimePeriod", testFullActionDialogflowWithTodayAndTimePeriod),
    ("testFullActionDialogflowWithDatePeriod", testFullActionDialogflowWithDatePeriod)
  ]
}
extension EnvVarTests {
  static var allTests: [(String, (EnvVarTests) -> () throws -> Void)] = [
    ("testDecoding", testDecoding)
  ]
}
extension SlackTests {
  static var allTests: [(String, (SlackTests) -> () throws -> Void)] = [
    ("testAcceptedInteractiveMessage", testAcceptedInteractiveMessage),
    ("testAcceptedNotificationMessage", testAcceptedNotificationMessage),
    ("testRejectedInteractiveMessage", testRejectedInteractiveMessage),
    ("testRejectedNotificationMessage", testRejectedNotificationMessage),
    ("testGoogleCalendarEventRange", testGoogleCalendarEventRange)
  ]
}

// swiftlint:disable trailing_comma
XCTMain([
  testCase(AppMiddlewareTests.allTests),
  testCase(DialogflowTests.allTests),
  testCase(EnvVarTests.allTests),
  testCase(SlackTests.allTests),
])
// swiftlint:enable trailing_comma
