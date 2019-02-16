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
  
  func testFillDateContextDialogflow() {
    Current = .mock
    
    let req = request(to: .dialogflow(.fillDate), basicAuth: true)
    let conn = connection(from: req)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }

  func testFullActionDialogflow() {
    Current = .mock

    let req = request(to: .dialogflow(.full), basicAuth: true)
    let conn = connection(from: req)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }

  func testFullActionDialogflowWithTodayAndTimePeriod() {
    Current = .mock

    let parameters = Context.Parameters.illness
      |> \.timePeriod .~ .init(
        startTime: Date(timeIntervalSince1970: 1550325600),
        endTime: Date(timeIntervalSince1970: 1550336400))

    let webhook = Webhook.mock
      |> \.outputContexts <<< map <<< \.parameters .~ parameters

    let req = request(to: .dialogflow(webhook), basicAuth: true)
    let conn = connection(from: req)

    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }
}
