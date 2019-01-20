import Either
import Foundation
import Optics
import Prelude

public func bootstrap() -> EitherIO<Error, Prelude.Unit> {
  return print(message: "⚠️ Bootstrapping AbsenceBot...")
    .flatMap(const(loadEnvironment))
    .flatMap(const(print(message: "✅ AbsenceBot Bootstrapped!")))
}

private func print(message: @autoclosure @escaping () -> String) -> EitherIO<Error, Prelude.Unit> {
  return EitherIO<Error, Prelude.Unit>(run: IO {
    print(message())
    return .right(unit)
  })
}

private let stepDivider = print(message: "  -----------------------------")

private let loadEnvironment =
  print(message: "  ⚠️ Loading environment...")
    .flatMap(loadEnvVars)
    .flatMap(const(print(message: "  ✅ Loaded!")))

private let loadEnvVars = { (_: Prelude.Unit) -> EitherIO<Error, Prelude.Unit> in
  let envFilePath = URL(fileURLWithPath: #file)
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .deletingLastPathComponent()
    .appendingPathComponent(".env")

  let decoder = JSONDecoder()
  let encoder = JSONEncoder()

  let defaultEnvVarDict = (try? encoder.encode(Current.envVars))
    .flatMap { try? decoder.decode([String: String].self, from: $0) }
    ?? [:]

  let localEnvVarDict = (try? Data(contentsOf: envFilePath))
    .flatMap { try? decoder.decode([String: String].self, from: $0) }
    ?? [:]

  let envVarDict = defaultEnvVarDict
    .merging(localEnvVarDict, uniquingKeysWith: { $1 })
    .merging(ProcessInfo.processInfo.environment, uniquingKeysWith: { $1 })

  let envVars = (try? JSONSerialization.data(withJSONObject: envVarDict))
    .flatMap { try? decoder.decode(EnvVars.self, from: $0) }
    ?? Current.envVars

  update(&Current, \.envVars .~ envVars)
  return pure(unit)
}

