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
    Current = .mock
//    record = true
  }
  
  func testAcceptedInteractiveMessage() {
    let webhook = request(to: .slack(.accept)) |> signRequest
    let conn = connection(from: webhook)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }

  func testAcceptedNotificationMessage() {
    update(
      &Current,
      \.slack.postMessage .~ { message in
        assertSnapshot(matching: message, as: .dump)
        return pure(pure(.mock))
      }
    )

    let webhook = request(to: .slack(.accept)) |> signRequest
    let conn = connection(from: webhook)

    _ = appMiddleware(conn).perform()
  }

  func testSilentlyAcceptedInteractiveMessage() {
    let webhook = request(to: .slack(.silentAccept)) |> signRequest
    let conn = connection(from: webhook)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }
  
  func testSilentlyAcceptedNotificationMessage() {
    update(
      &Current,
      \.slack.postMessage .~ { message in
        assertSnapshot(matching: message, as: .dump)
        return pure(pure(.mock))
      }
    )
    
    let webhook = request(to: .slack(.silentAccept)) |> signRequest
    let conn = connection(from: webhook)
    
    _ = appMiddleware(conn).perform()
  }

  func testRejectedInteractiveMessage() {
    let webhook = request(to: .slack(.reject)) |> signRequest
    let conn = connection(from: webhook)
    
    assertSnapshot(matching: conn |> appMiddleware, as: .ioConn)
  }

  func testRejectedNotificationMessage() {
    update(
      &Current,
      \.slack.postMessage .~ { message in
        assertSnapshot(matching: message, as: .dump)
        return pure(pure(.mock))
      }
    )

    let webhook = request(to: .slack(.reject)) |> signRequest
    let conn = connection(from: webhook)
    
    _ = appMiddleware(conn).perform()
  }

  func testGoogleCalendarEventRange() {
    let action = InteractiveMessageAction.accept
    update(
      &Current,
      \.calendar.createEvent .~ { _, event in
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

    let webhook = request(to: .slack(action)) |> signRequest
    let conn = connection(from: webhook)
    
    _ = appMiddleware(conn).perform()
  }
  
  func testGoogleCalendarEventAttendeesCountForSilectAcceptAction() {
    let action = InteractiveMessageAction.silentAccept
    update(
      &Current,
      \.calendar.createEvent .~ { _, event in
        // on silent accept there should be one attendee (requester)
        XCTAssertEqual(event.attendees?.count, 1)
        return pure(.mock)
      }
    )
    
    let webhook = request(to: .slack(action)) |> signRequest
    let conn = connection(from: webhook)
    
    _ = appMiddleware(conn).perform()
  }

  func testGoogleCalendarEventAttendeesCountForNormalAcceptAction() {
    let action = InteractiveMessageAction.accept
    update(
      &Current,
      \.calendar.createEvent .~ { _, event in
        // on normal accept there should be two attendees (requester & reviewer)
        XCTAssertEqual(event.attendees?.count, 2)
        return pure(.mock)
      }
    )
    
    let webhook = request(to: .slack(action)) |> signRequest
    let conn = connection(from: webhook)
    
    _ = appMiddleware(conn).perform()
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
