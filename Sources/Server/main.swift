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
run(siteMiddleware, on: 8080, gzip: true, baseUrl: URL(string: "http://localhost:8080")!)

