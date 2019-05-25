import Optics
@testable import AbsenceBot
import Prelude
import SnapshotTesting
import XCTest

open class TestCase: XCTestCase {
  override open func setUp() {
    super.setUp()
    diffTool = "ksdiff"
  }

  override open func tearDown() {
    super.tearDown()
    record = false
  }
}
