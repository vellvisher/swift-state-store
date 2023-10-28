# swift-state-store

### Usage

In the `App`:

```swift
import StateStore

struct MyApp: App {
  @StateObject private var store = StateStore<AppState>(
    storeURL: URL.documentsDirectory.appendingPathComponent("state.binpb")

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(store)
    }
  }
}
```

In a `ContentView`:

```swift
import StateStore
struct ContentView: View {
  @EnvironmentObject private var store: StateStore<AppState>
}

```


### Protobuf integration

To use this with an existing protobuf, add the following extension to your state object.

In `AppState.swift`:

```swift
import Foundation
import StateStore

extension AppState: StateProtocol {
  init(from serializedData: Data) throws {
    self = try AppState(serializedData: serializedData)
  }

  func serialized() throws -> Data {
    return try self.serializedData()
  }
}
```
