// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import XCTest

@testable import AbsenceBotTests;
extension AppMiddlewareTests {
  static var allTests: [(String, (AppMiddlewareTests) -> () throws -> Void)] = [
    ("testWithHttps", testWithHttps)
  ]
}
extension DialogflowMiddlewareTests {
  static var allTests: [(String, (DialogflowMiddlewareTests) -> () throws -> Void)] = [
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
extension ReportMiddlewareTests {
  static var allTests: [(String, (ReportMiddlewareTests) -> () throws -> Void)] = [
    ("testBasicReportGeneration", testBasicReportGeneration)
  ]
}
extension SlackMiddlewareTests {
  static var allTests: [(String, (SlackMiddlewareTests) -> () throws -> Void)] = [
    ("testAcceptedInteractiveMessage", testAcceptedInteractiveMessage),
    ("testAcceptedNotificationMessage", testAcceptedNotificationMessage),
    ("testSilentlyAcceptedInteractiveMessage", testSilentlyAcceptedInteractiveMessage),
    ("testSilentlyAcceptedNotificationMessage", testSilentlyAcceptedNotificationMessage),
    ("testRejectedInteractiveMessage", testRejectedInteractiveMessage),
    ("testRejectedNotificationMessage", testRejectedNotificationMessage),
    ("testGoogleCalendarEventRange", testGoogleCalendarEventRange),
    ("testGoogleCalendarEventAttendeesCountForSilectAcceptAction", testGoogleCalendarEventAttendeesCountForSilectAcceptAction),
    ("testGoogleCalendarEventAttendeesCountForNormalAcceptAction", testGoogleCalendarEventAttendeesCountForNormalAcceptAction)
  ]
}

// swiftlint:disable trailing_comma
XCTMain([
  testCase(AppMiddlewareTests.allTests),
  testCase(DialogflowMiddlewareTests.allTests),
  testCase(EnvVarTests.allTests),
  testCase(ReportMiddlewareTests.allTests),
  testCase(SlackMiddlewareTests.allTests),
])
// swiftlint:enable trailing_comma
