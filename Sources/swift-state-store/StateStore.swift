import Foundation
import Logging

/// This protocol must be implemented by a State object that can
/// be used with the store.
public protocol StateProtocol {
  init()
  func serialized() throws -> Data
  init(serializedData: Data) throws
}

/// StateStore generalised on a particular State value.
public actor StateStore<State: StateProtocol>: ObservableObject {
  @MainActor @Published private(set) public var state: State = .init()

  private let storeURL: URL?
  private let inMemory: Bool

  /// Parameter: storeURL Uses the specified file for persisting
  ///   the state, otherwise pass nil for in-memory state.
  /// - Note: Recommended extension for the file is ".binpb"
  /// https://protobuf.dev/programming-guides/techniques/#suffixes
  public init(storeURL: URL?) {
    self.storeURL = storeURL
    inMemory = storeURL == nil ? true : false

    if !inMemory {
      Task { await loadState() }
    }
  }

  private func loadState() async {
    guard let storeURL = storeURL else {
      Logger().error("Must specify storeURL to load state from")
      return
    }
    if FileManager.default.fileExists(atPath: storeURL.path) {
      do {
        let contents = try Data(contentsOf: storeURL)
        let persistedState = try State(serializedData: contents)
        await update { _ in
          return persistedState
        }
      } catch let error {
        Logger().error("Could not load value from file \(error)")
      }
    }
  }

  /// Update the underlying state to |state|.
  ///
  /// - Note: Updates are done on the MainActor.
  public func update(action: (State) -> State) async {
    await MainActor.run {
      Logger().info("Mutating old state: \(state)")
      state = action(state)
      Logger().info("New state: \(state)")
    }
    await MainActor.run {
      // Helps notify subscribed SwiftUI views of update.
      self.objectWillChange.send()
    }
    if !self.inMemory {
      await writeToFile(state)
    }
  }

  private func writeToFile(_ state: State) async {
    guard let storeURL else {
      Logger().error("Store filename not specified for writing state")
      return
    }
    do {
      try state.serialized().write(to: storeURL)
    } catch let error {
      // Failed to write file – bad permissions, bad filename, missing permissions,
      // or it can't be converted to the encoding.
      Logger().error("Error writing: \(error)")
    }
  }
}

extension Logger {
  fileprivate init() {
    self.init(label: "StateStore")
  }
}
