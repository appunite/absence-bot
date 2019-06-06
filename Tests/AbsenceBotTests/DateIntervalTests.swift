import XCTest
import Either
import Html
import HttpPipeline
import Prelude
import Optics
import SnapshotTesting
import AbsenceBotTestSupport
@testable import AbsenceBot

class DateIntervalTests: TestCase {

  override func setUp() {
    super.setUp()
    Current = .mock
  }
  
  func testDateIntervalWithTimeStartAndEnd() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )

    let params = Context.Parameters()
      |> \.date .~ Date(timeIntervalSince1970: 1559815200)      // 6.06.2019 12:00:00 GMT+02:00
      |> \.timeStart .~ Date(timeIntervalSince1970: 1559800800) // 6.06.2019 08:00:00 GMT+02:00
      |> \.timeEnd .~ Date(timeIntervalSince1970: 1559829600)   // 6.06.2019 16:00:00 GMT+02:00

    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)

    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1559800800))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1559829600))
  }

  func testDateIntervalWithTimePeriod() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )
    
    let params = Context.Parameters()
      |> \.date .~ Date(timeIntervalSince1970: 1559815200)  // 6.06.2019 12:00:00 GMT+02:00
      |> \.timePeriod .~ .init(
        startTime: Date(timeIntervalSince1970: 1559800800),  // 6.06.2019 08:00:00 GMT+02:00
        endTime: Date(timeIntervalSince1970: 1559829600))   // 6.06.2019 16:00:00 GMT+02:00

    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)
    
    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1559800800))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1559829600))
  }

  func testDateIntervalWithJustDate() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )
    
    let params = Context.Parameters()
      |> \.date .~ Date(timeIntervalSince1970: 1559815200)  // 6.06.2019 12:00:00 GMT+02:00
    
    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)
    
    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1559822400))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1559822400))
  }
  
  func testDateIntervalWithDateTimeStartAndEnd() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )
    
    let params = Context.Parameters()
      |> \.dateTimeStart .~ Date(timeIntervalSince1970: 1559800800) // 6.06.2019 08:00:00 GMT+02:00
      |> \.dateTimeEnd .~ Date(timeIntervalSince1970: 1559829600)   // 6.06.2019 16:00:00 GMT+02:00
    
    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)
    
    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1559808000))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1559836800))
  }

  func testDateIntervalWithDatePeriod() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )
    
    let params = Context.Parameters()
      |> \.datePeriod .~ .init(
        startDate: Date(timeIntervalSince1970: 1560146400), // 10.06.2019 08:00:00 GMT+02:00
        endDate: Date(timeIntervalSince1970: 1560319200))   // 12.06.2019 08:00:00 GMT+02:00

    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)
    
    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1560124800))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1560297600))
  }

  func testDateIntervalWithDateStartAndEnd() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )
    
    let params = Context.Parameters()
      |> \.dateStart .~ Date(timeIntervalSince1970: 1560146400)   // 10.06.2019 08:00:00 GMT+02:00
      |> \.dateEnd .~ Date(timeIntervalSince1970: 1560319200)     // 12.06.2019 08:00:00 GMT+02:00
    
    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)
    
    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1560124800))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1560297600))
  }

  func testDateIntervalWithDateTimeStartAndDateEnd() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )
    
    let params = Context.Parameters()
      |> \.dateTimeStart .~ Date(timeIntervalSince1970: 1560146400) // 10.06.2019 08:00:00 GMT+02:00
      |> \.dateEnd .~ Date(timeIntervalSince1970: 1560319200)       // 12.06.2019 08:00:00 GMT+02:00
    
    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)
    
    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1560153600))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1560326400))
  }

  func testDateIntervalWithDateStartAndDateTimeEnd() {
    update(
      &Current,
      \.dialogflowTimeZone .~ { TimeZone(secondsFromGMT: 2 * 3600)! }
    )
    
    let params = Context.Parameters()
      |> \.dateStart .~ Date(timeIntervalSince1970: 1560146400)     // 10.06.2019 08:00:00 GMT+02:00
      |> \.dateTimeEnd .~ Date(timeIntervalSince1970: 1560319200)   // 12.06.2019 08:00:00 GMT+02:00
    
    let dateInterval = params
      .dateInterval(tz: TimeZone(secondsFromGMT: 2 * 3600)!)
    
    XCTAssertEqual(dateInterval?.start, Date(timeIntervalSince1970: 1560153600))
    XCTAssertEqual(dateInterval?.end, Date(timeIntervalSince1970: 1560326400))
  }
}
