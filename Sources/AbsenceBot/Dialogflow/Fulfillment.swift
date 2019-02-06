import Foundation
import Prelude

public struct Fulfillment: Encodable {
  public private(set) var text: String?
  public private(set) var contexts: [Context]?
  
  enum CodingKeys: String, CodingKey {
    case text = "fulfillmentText"
    case contexts = "outputContexts"
  }
}

extension Fulfillment {
  public static let missingPeriod = Fulfillment(text: "*When* are you planning to take time off?", contexts: nil)
  public static let missingReason = Fulfillment(text: "What is the *reason* you're taking days off?", contexts: nil)

  public static func compliments(contexts: [Context]) -> Fulfillment {
    return Fulfillment(text: "Thank you! I'll inform your project manager about your request!", contexts: contexts)
  }

  public static func confirmation(absence: Absence, context: Context) -> Fulfillment {
    let periodString = absence.period
      .dateRange(tz: absence.user.timezone)

    let fulfillment = { Fulfillment(text: $0, contexts: [context]) }

    switch absence.reason {
    case .illness:
      return "So, you feel *sick* and you are going to take day(s) off \(periodString), correct?" |> fulfillment
    case .holiday:
      return "So you're planning a *vacation* \(periodString), correct?" |> fulfillment
    case .remote:
      return "So, you'll be working *remotely* and you're requesting for absence \(periodString), correct?" |> fulfillment
    case .conference:
      return "So, you're going to the *conference* \(periodString), correct?" |> fulfillment
    case .school:
      return "So, you'll be at *school* and you're requesting for absence \(periodString), correct?" |> fulfillment
    }
  }
}
