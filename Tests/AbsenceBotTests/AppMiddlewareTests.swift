import Html
import SnapshotTesting
import Prelude
import XCTest
import AbsenceBotTestSupport
import HttpPipelineTestSupport
import Optics
@testable import AbsenceBot
@testable import HttpPipeline

class AppMiddlewareTests: TestCase {

  func testWithHttps() {
    assertSnapshot(
      matching: connection(from: URLRequest(url: URL(string: "https://absences.appunite.com/hello")!))
        |> appMiddleware,
      as: .ioConn,
      named: "1.redirects_to_https"
    )
    
    assertSnapshot(
      matching: connection(from: URLRequest(url: URL(string: "http://absences.appunite.com/hello")!))
        |> appMiddleware,
      as: .ioConn,
      named: "2.redirects_to_https"
    )
    
    assertSnapshot(
      matching: connection(from: URLRequest(url: URL(string: "http://0.0.0.0:8080/hello")!))
        |> appMiddleware,
      as: .ioConn,
      named: "0.0.0.0_allowed"
    )
    
    assertSnapshot(
      matching: connection(from: URLRequest(url: URL(string: "http://127.0.0.1:8080/hello")!))
        |> appMiddleware,
      as: .ioConn,
      named: "127.0.0.0_allowed"
    )
    
    assertSnapshot(
      matching: connection(from: URLRequest(url: URL(string: "http://localhost:8080/hello")!))
        |> appMiddleware,
      as: .ioConn,
      named: "localhost_allowed"
    )
  }
}
