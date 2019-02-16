import XCTest
import Either
import Html
import HttpPipeline
import Prelude
import Optics
import SnapshotTesting
import AbsenceBotTestSupport
@testable import AbsenceBot

class DialogflowTests: TestCase {
  override func setUp() {
    super.setUp()
//    record = true
  }
  
  func testFullActionDialogflow() {
    Current = .mock

    let webhook = request(to: .dialogflow(.full), basicAuth: true)
    let conn = connection(from: webhook)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }

  func testFillDateContextDialogflow() {
    Current = .mock
    
    let webhook = request(to: .dialogflow(.fillDate), basicAuth: true)
    let conn = connection(from: webhook)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }
}
