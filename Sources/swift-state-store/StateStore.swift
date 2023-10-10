import Foundation
import Logging

protocol StateProtocol {
  init()
  init(with: String) throws
  func serializedData() -> Data
}

actor AppStore<State: StateProtocol>: ObservableObject {
  @MainActor @Published private(set) var state: State = .init()

  let storeFilename: URL
  let inMemory: Bool

  init(inMemory: Bool = false) {
    storeFilename = URL.getFileInDocumentsDirectory("store.binpb")

    if let uiTesting = ProcessInfo.processInfo.environment["UITesting"],
      uiTesting == "true"
    {
      self.inMemory = true
    } else {
      self.inMemory = inMemory
    }

    if !self.inMemory {
      Task { await loadState() }
    }
  }

  func loadState() async {
    if FileManager.default.fileExists(atPath: storeFilename.path) {
      do {
        let contents = try String(contentsOfFile: storeFilename.path)
        let persistedState = try State(with: contents)
        await update { _ in
          return persistedState
        }
      } catch let error {
        Logger().error("Could not load value from file \(error)")
      }
    }
  }

  func update(action: (State) -> State) async {
    await MainActor.run {
      Logger().info("Mutating old state: \(state)")
      state = action(state)
      Logger().info("New state: \(state)")
    }
    await MainActor.run {
      self.objectWillChange.send()
    }
    if !self.inMemory {
      await writeToFile(state.textFormatString())
    }
  }

  func writeToFile(_ state: String) async {
    do {
      try state.write(to: storeFilename, atomically: true, encoding: String.Encoding.utf8)
    } catch let error {
      // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
      Logger().error("Error writing: \(error)")
    }
  }
}

extension Logger {
  fileprivate init() {
    self.init(label: "AppStore")
  }
}
