import Optics
@testable import AbsenceBot
import Prelude
import SnapshotTesting
import XCTest

#if !os(Linux)
public typealias SnapshotTestCase = XCTestCase
#endif

open class TestCase: SnapshotTestCase {
  override open func setUp() {
    super.setUp()
    diffTool = "ksdiff"
  }

  override open func tearDown() {
    super.tearDown()
    record = false
  }
}
