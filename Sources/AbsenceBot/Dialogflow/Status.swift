import Foundation

public enum Status {
    case complete(Dialogflow.Reason, Period, Fulfillment)
    case incomplete(Fulfillment)
    case report(Period, Fulfillment)
}
