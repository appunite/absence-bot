import Foundation
import HttpPipeline
import Prelude
import AbsenceBot
import CodableCSV

let input = """
cdatetime,address,district,beat,grid,crimedescr,ucr_ncic_code,latitude,longitude
1/1/06 0:00,3108 OCCIDENTAL DR,3,3C        ,1115,10851(A)VC TAKE VEH W/O OWNER,2404,38.55042047,-121.3914158
1/1/06 0:00,2082 EXPEDITION WAY,5,5A        ,1512,459 PC  BURGLARY RESIDENCE,2204,38.47350069,-121.4901858
1/1/06 0:00,4 PALEN CT,2,2A        ,212,10851(A)VC TAKE VEH W/O OWNER,2404,38.65784584,-121.4621009
1/1/06 0:00,22 BECKFORD CT,6,6C        ,1443,476 PC PASS FICTICIOUS CHECK,2501,38.50677377,-121.4269508
1/1/06 0:00,3421 AUBURN BLVD,2,2A        ,508,459 PC  BURGLARY-UNSPECIFIED,2299,38.6374478,-121.3846125
"""
let config = DecoderConfiguration(fieldDelimiter: .comma, rowDelimiter: .lineFeed, headerStrategy: .unknown)
let (headers, rows) = try CSVReader.parse(string: input)

// Bootstrap
_ = try! AbsenceBot
  .bootstrap()
  .run
  .perform()
  .unwrap()

// Server
run(appMiddleware, on: Current.envVars.port, gzip: true, baseUrl: Current.envVars.baseUrl)
