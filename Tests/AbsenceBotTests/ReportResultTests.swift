import XCTest
import Either
import Html
import HttpPipeline
import Prelude
import Optics
import SnapshotTesting
import AbsenceBotTestSupport
@testable import AbsenceBot

class ReportResultTests: XCTestCase {
  func testReasonRegexParsingWithFullNameAndEmoji() {
    let event = GoogleCalendar.Event.mock
      |> \.summary .~ "Jan Kowalski - school 🎓"
    
    let reportResult = ReportResult(event: event)
    XCTAssertEqual(reportResult.reason, .school)
  }
  
  func testReasonRegexParsingWithFullNameWithoutEmoji() {
    let event = GoogleCalendar.Event.mock
      |> \.summary .~ "Jan kowalski - holiday"
    
    let reportResult = ReportResult(event: event)
    XCTAssertEqual(reportResult.reason, .holiday)
  }
  
  func testReasonRegexParsingWithEmailWithoutEmoji() {
    let event = GoogleCalendar.Event.mock
      |> \.summary .~ "jak.kowalski@gmail.com - remote"
    
    let reportResult = ReportResult(event: event)
    XCTAssertEqual(reportResult.reason, .remote)
  }
  
  func testReasonRegexParsingWithEmailWithoutEmojiAndSomeExtraSuffix() {
    let event = GoogleCalendar.Event.mock
      |> \.summary .~ "jak.kowalski@gmail.com - illness xxx-yyy"
    
    let reportResult = ReportResult(event: event)
    XCTAssertEqual(reportResult.reason, .illness)
  }
  
  func testReasonRegexParsingWithNameWithoutEmoji() {
    let event = GoogleCalendar.Event.mock
      |> \.summary .~ "Jan - conference"
    
    let reportResult = ReportResult(event: event)
    XCTAssertEqual(reportResult.reason, .conference)
  }
}

