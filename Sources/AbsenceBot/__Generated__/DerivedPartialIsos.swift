// Generated using Sourcery 0.15.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT


import ApplicativeRouter
import Either
import Prelude



      extension PartialIso where A == Prelude.Unit, B == Route {
        public static let hello = parenthesize <| PartialIso<Prelude.Unit, Route>(
          apply: const(.some(.hello)),
          unapply: {
            guard case .hello = $0 else { return nil }
            return .some(Prelude.unit)
        })
      }



      extension PartialIso where A == Prelude.Unit, B == Route {
        public static let slack = parenthesize <| PartialIso<Prelude.Unit, Route>(
          apply: const(.some(.slack)),
          unapply: {
            guard case .slack = $0 else { return nil }
            return .some(Prelude.unit)
        })
      }



      extension PartialIso where A == (
            Dialogflow
        ), B == Route {

          public static let dialogflow = parenthesize <| PartialIso(
            apply: Route.dialogflow,
            unapply: {
              guard case let .dialogflow(result) = $0 else { return nil }
              return .some(result)
          })
      }

