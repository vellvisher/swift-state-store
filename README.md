# swift-state-store

### Usage

```swift
struct MyApp: App {
  @StateObject private var store = StateStore<AppState>(
    storeURL: URL.getFileInDocumentsDirectory("state.binpb"))

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(store)
    }
  }
}

struct ContentView: View {
  @EnvironmentObject private var store: StateStore<AppState>
}

```


### Protobuf integration

To use this with an existing protobuf, add the following extension to your state object.

```swift
extension $ProtoState: StateProtocol {
  init(from serializedData: Data) throws {
    self = try AppState(serializedData: serializedData)
  }

  func serialized() throws -> Data {
    return try self.serializedData()
  }
}
```
