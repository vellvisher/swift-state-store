import Foundation
import Logging

public protocol StateProtocol {
  init()
  init(with: String) throws
  func textFormatString() -> String
}

public actor StateStore<State: StateProtocol>: ObservableObject {
  @MainActor @Published private(set) public var state: State = .init()

  private let storeFile: URL?
  private let inMemory: Bool

  public init(filename: String?) {
    if let filename = filename {
      storeFile = URL.getFileInDocumentsDirectory(filename)
      inMemory = false
    } else {
      storeFile = nil
      inMemory = true
    }

    if !inMemory {
      Task { await loadState() }
    }
  }

  private func loadState() async {
    guard let storeFile = storeFile else {
      Logger().error("Must specify storeFile to load state from")
      return
    }
    if FileManager.default.fileExists(atPath: storeFile.path) {
      do {
        let contents = try String(contentsOfFile: storeFile.path)
        let persistedState = try State(with: contents)
        await update { _ in
          return persistedState
        }
      } catch let error {
        Logger().error("Could not load value from file \(error)")
      }
    }
  }

  public func update(action: (State) -> State) async {
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

  private func writeToFile(_ state: String) async {
    guard let storeFile else {
      Logger().error("Store filename not specified for writing state")
      return
    }
    do {
      try state.write(to: storeFile, atomically: true, encoding: String.Encoding.utf8)
    } catch let error {
      // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
      Logger().error("Error writing: \(error)")
    }
  }
}

extension Logger {
  fileprivate init() {
    self.init(label: "StateStore")
  }
}

extension URL {
  fileprivate static func getFileInDocumentsDirectory(_ filename: String) -> URL {
    if #available(watchOS 9.0, *), #available(iOS 16.0, *), #available(macOS 13.0, *) {
      return URL.documentsDirectory.appendingPathComponent(filename)
    }

    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory.appendingPathComponent(filename)
  }
}
