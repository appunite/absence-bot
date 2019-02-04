import Foundation
import Prelude

public struct Fulfillment: Encodable {
  public private(set) var text: String?
  public private(set) var contexts: [Context]?
  
  enum CodingKeys: String, CodingKey {
    case text = "fulfillmentText"
    case contexts = "outputContexts"
  }
  
  public init(text: Body?, contexts: [Context]? = nil) {
    self.text = text?.description
    self.contexts = contexts
  }
  
  public enum Body {
    case raw(String)
    case missingPeriod
    case thanks
    case confirmation(String, Absence.Period, TimeZone)
  }
}

extension Fulfillment.Body: CustomStringConvertible {
    public var description: String {
        switch self {
        case .confirmation(let reason, let period, let timezone):
            let dates = period.dates(timeZone: timezone)
                .joined(separator: " - ")

//            switch reason {
//            case .illness:
//                return "Please check me! You do not feel well and requesting for absence \(dates), correct?"
//            case .holiday:
                return "Ok, let's summarize! You're planning vacations and requesting for absence \(dates), correct?"
//            case .remote:
//                return "Roger! You'll be working remotely and requesting for absence \(dates), correct?"
//            case .conference:
//                return "So, you'll be extending your knowledge and requesting for absence \(dates), correct?"
//            case .school:
//                return "So, you'll be at school and you're requesting for absence \(dates), correct?"
//            }
        case .missingPeriod:
            return "To fulfill requirements I need information about your absence period. Please write absence day or period, e.g. today, on Monday, from tomorrow 7 AM till 4.11.2018 4 PM"
        case .thanks:
            return "Thank you! I'll inform your project manager about your request!"
        case .raw(let msg):
            return msg
        }
    }
}
