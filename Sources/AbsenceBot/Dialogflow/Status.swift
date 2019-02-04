import Foundation

public enum Status {
    case complete(Absence, Fulfillment)
    case incomplete(Fulfillment)
    case report(Absence.Period, Fulfillment)
}
