import StateStore
import XCTest

struct AppState: StateProtocol {
  // Always starts with 1.
  var nextRollNumber: Int
  // [RollNumber: Name]
  var students: [Int: String]

  init() {
    self.init(nextRollNumber: 1, students: [:])
  }

  init(nextRollNumber: Int, students: [Int: String]) {
    self.nextRollNumber = nextRollNumber
    self.students = students
  }

  init(from serializedData: Data) throws {
    let value = serializedData.withUnsafeBytes {
      $0.load(as: Int.self)
    }
    self.init(nextRollNumber: value, students: [:])
  }

  func serialized() throws -> Data {
    return withUnsafeBytes(of: nextRollNumber) { Data($0) }
  }
}

final class StateStoreTest: XCTestCase {
  let store = StateStore<AppState>(storeURL: nil)

  @MainActor
  func testUpdateNextRollNumber() async throws {
    XCTAssertEqual(store.state.nextRollNumber, 1)
    XCTAssert(store.state.students.isEmpty)
    await store.update {
      $0.nextRollNumber = 2
    }
    XCTAssertEqual(store.state.nextRollNumber, 2)
    XCTAssert(store.state.students.isEmpty)
  }

  @MainActor
  func testUpdateStudents() async throws {
    XCTAssertEqual(store.state.nextRollNumber, 1)
    XCTAssert(store.state.students.isEmpty)
    await store.update {
      $0.students = [1: "Jenny Dear"]
    }
    XCTAssertEqual(store.state.nextRollNumber, 1)
    XCTAssertEqual(store.state.students[1], "Jenny Dear")
  }

  @MainActor
  func testAddNewStudent() async throws {
    XCTAssertEqual(store.state.nextRollNumber, 1)
    XCTAssert(store.state.students.isEmpty)
    await store.update {
      $0.nextRollNumber = 2
      $0.students = [1: "Jenny Dear"]
    }
    XCTAssertEqual(store.state.nextRollNumber, 2)
    XCTAssertEqual(store.state.students[1], "Jenny Dear")
  }

  @MainActor
  func testAddNewStudentInTwoUpdates() async throws {
    XCTAssertEqual(store.state.nextRollNumber, 1)
    XCTAssert(store.state.students.isEmpty)
    let expectation1 = XCTestExpectation(description: "Updated rollNumber")
    let expectation2 = XCTestExpectation(description: "Updated student")

    Task {
      Task {
        await store.update {
          $0.nextRollNumber = 2
          sleep(3)
        }
        expectation1.fulfill()
      }
      Task {
        XCTAssertEqual(store.state.nextRollNumber, 1)
      }
      Task {
        await store.update {
          $0.students = [1: "Jenny Dear"]
          sleep(1)
        }
        expectation2.fulfill()
      }
    }

    await fulfillment(of: [expectation1, expectation2], timeout: 5)
    XCTAssertEqual(store.state.nextRollNumber, 2)
    XCTAssertEqual(store.state.students[1], "Jenny Dear")
  }
}
