import Foundation

struct AbsenceRequest {
  var user: String
  var period: Period
  var reason: String
  
//  public private(set) var user: Slack.User
//  public private(set) var period: Period
//  public private(set) var reason: Dialogflow.Reason
  
  enum CodingKeys: String, CodingKey {
    case user = "user_id"
    case period
    case reason
  }
}

extension AbsenceRequest: Codable {}
