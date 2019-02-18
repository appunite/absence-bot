import XCTest
import SnapshotTesting
import AbsenceBotTestSupport
@testable import AbsenceBot

class EnvVarTests: TestCase {
  func testDecoding() throws {
    let json = [
      "BASE_URL": "http://localhost:8080",
      "APP_ENV": "testing",
      "PORT": "8080",
      "DATABASE_URL": "postgres://postgres:@localhost:5432/postgres",
      "BASIC_AUTH_USERNAME": "absence-bot",
      "BASIC_AUTH_PASSWORD": "password",
      "SLACK_ANNOUNCEMENT_CHANNEL": "#random",
      "SLACK_AUTH_TOKEN": "xoxb-1115164490-464635012382-76zULi9AzSQ2GG7RcAXgVeSi",
      "SLACK_SIGNING_SECRET": "a0e2f6c6090d1d3a9ee699c0065c2a3f",
      "GOOGLE_CALENDAR_ID": "appunite%40group.calendar.google.com",
      "GOOGLE_CLIENT_EMAIL": "absencebot@absencebot.iam.gserviceaccount.com",
      "GOOGLE_PRIVATE_KEY": "-----BEGIN RSA PRIVATE KEY-----MIIEpAIBAAKCAQEA4wClrl66Gxab3zldb-----END RSA PRIVATE KEY-----\n"
    ]

    let envVars = try JSONDecoder()
      .decode(EnvVars.self, from: try JSONSerialization.data(withJSONObject: json))

    let roundTrip = try JSONSerialization.jsonObject(with: try JSONEncoder().encode(envVars), options: [])
      as! [String: String]

    assertSnapshot(matching: roundTrip.sorted(by: { $0.key < $1.key }), as: .dump)
  }
}
