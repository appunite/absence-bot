import Foundation
import HttpPipeline
import Prelude
import AbsenceBot

// Bootstrap
_ = try! AbsenceBot
  .bootstrap()
  .run
  .perform()
  .unwrap()

// Server
run(appMiddleware, on: Current.envVars.port, gzip: true, baseUrl: Current.envVars.baseUrl)
