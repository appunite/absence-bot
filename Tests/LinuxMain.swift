// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

import XCTest

@testable import AbsenceBotTests;
extension AppMiddlewareTests {
  static var allTests: [(String, (AppMiddlewareTests) -> () throws -> Void)] = [
    ("testWithHttps", testWithHttps)
  ]
}
extension DateIntervalTests {
  static var allTests: [(String, (DateIntervalTests) -> () throws -> Void)] = [
    ("testDateIntervalWithTimeStartAndEnd", testDateIntervalWithTimeStartAndEnd),
    ("testDateIntervalWithTimePeriod", testDateIntervalWithTimePeriod),
    ("testDateIntervalWithJustDate", testDateIntervalWithJustDate),
    ("testDateIntervalWithDateTimeStartAndEnd", testDateIntervalWithDateTimeStartAndEnd),
    ("testDateIntervalWithDatePeriod", testDateIntervalWithDatePeriod),
    ("testDateIntervalWithDateStartAndEnd", testDateIntervalWithDateStartAndEnd),
    ("testDateIntervalWithDateTimeStartAndDateEnd", testDateIntervalWithDateTimeStartAndDateEnd),
    ("testDateIntervalWithDateStartAndDateTimeEnd", testDateIntervalWithDateStartAndDateTimeEnd)
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
extension ReportResultTests {
  static var allTests: [(String, (ReportResultTests) -> () throws -> Void)] = [
    ("testReasonRegexParsingWithFullNameAndEmoji", testReasonRegexParsingWithFullNameAndEmoji),
    ("testReasonRegexParsingWithFullNameWithoutEmoji", testReasonRegexParsingWithFullNameWithoutEmoji),
    ("testReasonRegexParsingWithEmailWithoutEmoji", testReasonRegexParsingWithEmailWithoutEmoji),
    ("testReasonRegexParsingWithEmailWithoutEmojiAndSomeExtraSuffix", testReasonRegexParsingWithEmailWithoutEmojiAndSomeExtraSuffix),
    ("testReasonRegexParsingWithNameWithoutEmoji", testReasonRegexParsingWithNameWithoutEmoji)
  ]
}
extension SlackMiddlewareTests {
  static var allTests: [(String, (SlackMiddlewareTests) -> () throws -> Void)] = [
    ("testAcceptedInteractiveMessage", testAcceptedInteractiveMessage),
    ("testAcceptedNotificationMessage", testAcceptedNotificationMessage),
    ("testRejectedInteractiveMessage", testRejectedInteractiveMessage),
    ("testRejectedNotificationMessage", testRejectedNotificationMessage),
    ("testGoogleCalendarEventRange", testGoogleCalendarEventRange),
    ("testGoogleCalendarEventAttendeesCountForNormalAcceptAction", testGoogleCalendarEventAttendeesCountForNormalAcceptAction)
  ]
}

// swiftlint:disable trailing_comma
XCTMain([
  testCase(AppMiddlewareTests.allTests),
  testCase(DateIntervalTests.allTests),
  testCase(DialogflowMiddlewareTests.allTests),
  testCase(EnvVarTests.allTests),
  testCase(ReportMiddlewareTests.allTests),
  testCase(ReportResultTests.allTests),
  testCase(SlackMiddlewareTests.allTests),
])
// swiftlint:enable trailing_comma
