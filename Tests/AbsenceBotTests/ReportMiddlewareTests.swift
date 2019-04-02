import XCTest
import Either
import Html
import HttpPipeline
import Prelude
import Optics
import SnapshotTesting
import AbsenceBotTestSupport
@testable import AbsenceBot

class ReportMiddlewareTests: TestCase {
  override func setUp() {
    super.setUp()
    //    record = true
  }
  
  func testBasicReportGeneration() {
    Current = .mock
    
    let req = request(to: .report(year: 2019, month: 3), basicAuth: true)
    let conn = connection(from: req)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }
}
