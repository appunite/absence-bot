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



      extension PartialIso where A == (
            InteractiveMessageAction
        ), B == Route {

          public static let slack = parenthesize <| PartialIso(
            apply: Route.slack,
            unapply: {
              guard case let .slack(result) = $0 else { return nil }
              return .some(result)
          })
      }



      extension PartialIso where A == (
            Webhook
        ), B == Route {

          public static let dialogflow = parenthesize <| PartialIso(
            apply: Route.dialogflow,
            unapply: {
              guard case let .dialogflow(result) = $0 else { return nil }
              return .some(result)
          })
      }



      extension PartialIso where A == (
            Int
          , 
            Int
        ), B == Route {

          public static let report = parenthesize <| PartialIso(
            apply: Route.report,
            unapply: {
              guard case let .report(result) = $0 else { return nil }
              return .some(result)
          })
      }

