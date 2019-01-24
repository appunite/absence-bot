import Foundation

internal enum Throwable<T: Decodable>: Decodable {
    case success(T)
    case failure(Error)

    init(from decoder: Decoder) throws {
        do {
            let decoded = try T(from: decoder)
            self = .success(decoded)
        } catch let error {
            self = .failure(error)
        }
    }

    var value: T? {
        switch self {
        case .failure:
            return nil
        case .success(let value):
            return value
        }
    }
}
