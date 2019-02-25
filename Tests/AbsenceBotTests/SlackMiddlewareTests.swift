import XCTest
import Either
import Html
import HttpPipeline
import Prelude
import Optics
import SnapshotTesting
import AbsenceBotTestSupport
@testable import AbsenceBot

class SlackTests: TestCase {
  override func setUp() {
    super.setUp()
//    record = true
  }
  
  func testAcceptedInteractiveMessage() {
    Current = .mock
    
    let webhook = request(to: .slack(.accept)) |> signRequest
    let conn = connection(from: webhook)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }

  func testRejectedInteractiveMessage() {
    Current = .mock
    
    let webhook = request(to: .slack(.reject)) |> signRequest
    let conn = connection(from: webhook)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }
  
  func testGoogleCalendarEventRange() {
    let action = InteractiveMessageAction.accept
    update(
      &Current,
      \.calendar .~ GoogleCalendar(
        fetchAuthToken: { pure(pure(.mock)) },
        createEvent: { _, event in
          // calculate time interval between end dates
          let endInterval = zip(with: {$0.timeIntervalSince1970 - $1.timeIntervalSince1970})(
            event.end.date, action.absence?.interval.end)

          // start day need to equal
          XCTAssertEqual(event.start.date, action.absence?.interval.start)
          
          // end date must be extended by one day
          XCTAssertEqual(endInterval, 86_400)
          return pure(.mock)
        }
      )
    )

    let webhook = request(to: .slack(action)) |> signRequest
    let conn = connection(from: webhook)
    
    _ = appMiddleware(conn)
      .perform()
  }
}

private func signRequest(_ request: URLRequest) -> URLRequest {
  let timestamp = 1546344000
  let key = Current.envVars.slack.secret
  let signature = slackComputedDigest(
    key: key, body: request.httpBody, timestamp: "\(timestamp)")

  return request
    |> setHeader("X-Slack-Request-Timestamp", "\(timestamp)")
    <> setHeader("X-Slack-Signature", "\(signature!)")
}
