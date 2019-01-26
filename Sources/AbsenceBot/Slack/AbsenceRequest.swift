import Foundation

struct AbsenceRequest {
  var user: String
  var period: Period
  var reason: String
  
  enum CodingKeys: String, CodingKey {
    case user = "user_id"
    case period
    case reason
  }
}

extension AbsenceRequest: Codable {}
