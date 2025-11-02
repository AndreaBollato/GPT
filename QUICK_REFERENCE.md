# Swift SSE Integration - Quick Reference

## ?? Quick Start

### Enable Remote Backend
```swift
// File: GPT/Design/AppConstants.swift
static let useRemoteBackend = true
static let baseURL = "http://127.0.0.1:8000"  // or your LAN IP
```

### Add Files to Xcode
1. Open `GPT.xcodeproj`
2. Create groups: Networking, API, Repositories, Services
3. Drag files into groups from Finder
4. ? Ensure "Add to targets: GPT" is checked
5. Build (?B)

## ?? File Structure

```
GPT/
??? Networking/
?   ??? HTTPClient.swift       # HTTP wrapper
?   ??? SSEClient.swift         # SSE streaming
??? API/
?   ??? Endpoints.swift         # API routes
?   ??? DTOs.swift              # Data models
?   ??? Decoders.swift          # JSON config
??? Repositories/
?   ??? ConversationsRepository.swift  # Data layer
??? Services/
?   ??? ChatService.swift       # Stream orchestration
?   ??? StreamingCenter.swift  # Concurrent streams
??? Views/Shared/
    ??? ErrorBanner.swift       # Error UI
```

## ?? Common Operations

### Send Message (with streaming)
```swift
// UIState handles everything automatically
uiState.submit(text: "Hello!", in: conversationId)
```

### Stop Streaming
```swift
// Specific conversation
uiState.stopStreaming(for: conversationId)

// All streams
uiState.stopStreaming()
```

### Load More Conversations
```swift
await uiState.loadMoreConversations()
```

### Open Conversation (lazy load messages)
```swift
await uiState.openConversation(id: conversationId)
```

### Check Streaming State
```swift
if uiState.isStreaming(conversationId) {
    // Show stop button
}
```

## ?? Backend Endpoints

### Conversations
```
GET    /conversations?limit=10&cursor=...
POST   /conversations { modelId, firstMessage? }
PATCH  /conversations/{id} { title?, modelId?, isPinned? }
DELETE /conversations/{id}
POST   /conversations/{id}/duplicate
```

### Messages
```
GET  /conversations/{id}/messages?limit=30&cursor=...
POST /conversations/{id}/messages { role: "user", text: "..." }  # SSE
```

### Models
```
GET /models
```

## ?? SSE Event Format

```json
data: {
  "conversationId": "uuid",
  "messageId": "uuid",
  "deltaText": "Hello",       // Incremental
  "fullText": "Hello world",  // Optional full text
  "done": true                // Completion flag
}
```

## ?? Key Types

### Endpoints
```swift
Endpoints.listConversations(limit: 10, cursor: nil)
Endpoints.sendMessage(conversationId: id, request: req)
Endpoints.listModels()
```

### DTOs
```swift
ConversationDTO.toDomain() -> Conversation
MessageDTO.toDomain() -> Message
ChatModelDTO.toDomain() -> ChatModel
```

### Repository
```swift
let repo = RemoteConversationsRepository(client: httpClient)
let models = try await repo.fetchModels()
let (items, cursor) = try await repo.listConversations(limit: 10, cursor: nil)
```

### ChatService
```swift
await chatService.streamReply(
    conversationId: id,
    userText: "Hello",
    onDelta: { delta in /* update UI */ },
    onDone: { /* complete */ },
    onError: { error in /* handle */ }
)
```

## ?? UI Components

### Error Banner
```swift
if let errorMessage = uiState.errorMessage {
    ErrorBanner(message: errorMessage) {
        uiState.errorMessage = nil
    }
}
```

### Loading Indicator
```swift
if uiState.isLoadingConversations {
    ProgressView()
}
```

### Streaming Indicator
```swift
if uiState.isStreaming(conversation.id) {
    Button("Stop", action: { 
        uiState.stopStreaming(for: conversation.id) 
    })
}
```

## ?? Testing Commands

### Test Endpoints (curl)
```bash
# List conversations
curl http://localhost:8000/conversations?limit=10

# Create conversation
curl -X POST http://localhost:8000/conversations \
  -H "Content-Type: application/json" \
  -d '{"modelId":"gpt-4","firstMessage":"Hello"}'

# SSE stream
curl -N http://localhost:8000/conversations/{id}/messages \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: text/event-stream" \
  -d '{"role":"user","text":"Hello"}'
```

## ?? Debugging

### Enable Logging
```swift
// In HTTPClient.swift
print("Request: \(request.url?.absoluteString ?? "")")
print("Response: \(String(data: data, encoding: .utf8) ?? "")")
```

### Check SSE Events
```swift
// In SSEClient.swift
print("SSE Event: \(event.data)")
```

### Monitor Streams
```swift
// Check active streams
Task {
    let isStreaming = await chatService.isStreaming(conversationId: id)
    print("Streaming: \(isStreaming)")
}
```

## ?? Common Issues

### Connection Refused
- Backend not running
- Wrong port/IP
- Check `baseURL` in AppConstants

### SSE Not Streaming
- Missing `Accept: text/event-stream` header
- Backend not sending proper SSE format
- Check `Content-Type: text/event-stream` response

### JSON Parsing Error
- Date format must be ISO8601
- Check snake_case conversion
- Verify DTO matches backend schema

### Messages Not Loading
- Check conversation exists
- Verify cursor is valid
- Check backend pagination logic

## ?? Performance Tips

### Optimize UI Updates
```swift
// Batch delta updates (future enhancement)
let debouncer = Debouncer(delay: 0.05)
debouncer.run {
    // Update UI
}
```

### Reduce Re-renders
```swift
// Use @Published only for UI-relevant state
// Keep internal state private
```

### Lazy Loading
```swift
// Already implemented
// Messages load only when conversation opens
// More messages load on scroll to top
```

## ?? Security Notes

- No authentication implemented (as per spec)
- Add auth headers in `HTTPClient.makeRequest()` if needed
- Consider HTTPS for production
- Add ATS exception for HTTP if required

## ?? Device Testing

### Use LAN IP
```swift
// For device testing
static let baseURL = "http://192.168.1.100:8000"
```

### Add ATS Exception (Info.plist)
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## ?? Quick Wins

### Switch Modes Instantly
```swift
AppConstants.API.useRemoteBackend = false  // Mock
AppConstants.API.useRemoteBackend = true   // Remote
```

### Test Without Backend
- Mock mode has sample data
- Perfect for UI development
- SwiftUI previews work

### Add New Endpoint
1. Add to `Endpoints.swift`
2. Add DTO to `DTOs.swift`
3. Add method to repository
4. Call from UIState

## ?? Documentation

- **INTEGRATION_GUIDE.md** - Complete guide
- **XCODE_PROJECT_UPDATE.md** - Setup steps
- **IMPLEMENTATION_SUMMARY.md** - Overview
- **QUICK_REFERENCE.md** - This file

## ? Checklist

- [ ] Added files to Xcode project
- [ ] Build succeeds (?B)
- [ ] Tested with mock data
- [ ] Implemented Python backend
- [ ] Tested SSE streaming
- [ ] Tested pagination
- [ ] Tested error handling
- [ ] Tested on device

---

**Pro Tip**: Start with mock mode, verify UI works, then implement backend matching the contract. The architecture supports seamless switching!
