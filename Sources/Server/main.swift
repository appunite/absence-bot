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
run(appMiddleware, on: 8080, gzip: true, baseUrl: URL(string: "http://localhost:8080")!)

