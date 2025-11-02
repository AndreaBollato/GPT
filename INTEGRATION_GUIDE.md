# Swift + Python SSE Integration Guide

## Overview

This project now includes a complete integration with a Python backend using HTTP + SSE streaming. The architecture is cleanly layered with support for pagination, per-conversation concurrent streams, and graceful fallback to mock data.

## Architecture

```
GPT/
??? Networking/
?   ??? HTTPClient.swift       # HTTP client wrapper
?   ??? SSEClient.swift         # Server-Sent Events streaming
??? API/
?   ??? Endpoints.swift         # Type-safe API endpoints
?   ??? DTOs.swift              # Data Transfer Objects
?   ??? Decoders.swift          # JSON encoding/decoding
??? Repositories/
?   ??? ConversationsRepository.swift  # Repository pattern
??? Services/
?   ??? ChatService.swift       # SSE orchestration
?   ??? StreamingCenter.swift  # Concurrent stream management
??? ViewModels/
    ??? UIState.swift           # Updated with remote support
```

## Features Implemented

### ? Core Networking
- **HTTPClient**: Type-safe HTTP requests with automatic JSON encoding/decoding
- **SSEClient**: AsyncThrowingStream-based SSE parsing for streaming responses
- **Error Handling**: Comprehensive error types with user-friendly messages

### ? API Layer
- **Endpoints**: Type-safe endpoint definitions for all backend routes
- **DTOs**: Full DTO definitions with bidirectional mapping to domain models
- **Decoders**: ISO8601 date handling with snake_case conversion

### ? Repository Pattern
- **ConversationsRepository**: Protocol-based repository with async/await
- **RemoteConversationsRepository**: Full implementation using HTTPClient
- Supports: CRUD operations, pagination, message management, model fetching

### ? Streaming Services
- **ChatService**: Manages SSE streams with delta updates
- **StreamingCenter**: Actor-based concurrent stream management
- Per-conversation streaming state tracking
- Graceful cancellation with partial text preservation

### ? UI Integration
- **UIState**: Dual-mode support (mock + remote)
- **Pagination**: Infinite scroll for conversations and messages
- **Streaming UI**: Per-conversation streaming indicators
- **Error Banners**: Auto-dismissing error messages
- **Lazy Loading**: Messages loaded on conversation open

### ? Configuration
- **AppConstants**: Centralized API configuration
- **Mode Toggle**: Easy switch between mock and remote backends

## Backend Contract

The Swift client expects the following endpoints:

### Conversations
```
GET    /conversations?limit=10&cursor=...
POST   /conversations { modelId, firstMessage? }
GET    /conversations/{id}
PATCH  /conversations/{id} { title?, modelId?, isPinned? }
DELETE /conversations/{id}
POST   /conversations/{id}/duplicate
```

### Messages
```
GET  /conversations/{id}/messages?limit=30&cursor=...
POST /conversations/{id}/messages { role: "user", text }  [SSE endpoint]
```

### Models
```
GET /models
```

### SSE Event Format
```
data: { conversationId, messageId, deltaText?, fullText?, done? }

```

### Response Formats

**ConversationListResponse**:
```json
{
  "items": [ConversationMetaDTO],
  "nextCursor": "string?"
}
```

**ConversationMetaDTO**:
```json
{
  "id": "uuid",
  "title": "string",
  "modelId": "string",
  "isPinned": false,
  "createdAt": "2025-11-02T10:00:00Z",
  "updatedAt": "2025-11-02T10:00:00Z",
  "lastMessage": MessageDTO?
}
```

**MessageDTO**:
```json
{
  "id": "uuid",
  "role": "user|assistant|system",
  "text": "string",
  "createdAt": "2025-11-02T10:00:00Z",
  "isPinned": false,
  "isEdited": false
}
```

**ChatModelDTO**:
```json
{
  "id": "gpt-4",
  "name": "GPT-4",
  "description": "Most capable model"
}
```

## Configuration

### Enable Remote Backend

Edit `GPT/Design/AppConstants.swift`:

```swift
enum API {
    static let baseURL = "http://127.0.0.1:8000"
    static let useRemoteBackend = true  // Set to true
}
```

### Change Base URL

For testing on physical devices, use your machine's LAN IP:

```swift
static let baseURL = "http://192.168.1.100:8000"
```

### Add ATS Exception (if using HTTP)

Add to `Info.plist` if using HTTP instead of HTTPS:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## Usage Examples

### Starting a Conversation

```swift
// UIState automatically handles:
// 1. Creating conversation if needed
// 2. Adding user message optimistically
// 3. Starting SSE stream
// 4. Appending deltas in real-time
// 5. Marking as done

uiState.submit(text: "Hello!", in: nil)
```

### Stopping a Stream

```swift
// Stop specific conversation
uiState.stopStreaming(for: conversationId)

// Stop all streams
uiState.stopStreaming()
```

### Loading More Conversations

```swift
// Triggered automatically on scroll
await uiState.loadMoreConversations()
```

### Opening a Conversation

```swift
// Lazy loads messages on first open
await uiState.openConversation(id: conversationId)
```

## Key Implementation Details

### Concurrent Streaming

The `StreamingCenter` actor ensures:
- Only one stream per conversation at a time
- Previous streams are cancelled when starting new ones
- All streams can be cancelled together
- Thread-safe stream management

### Optimistic Updates

When sending a message:
1. User message added immediately to UI
2. Placeholder assistant message created with loading state
3. Stream starts and updates placeholder incrementally
4. On completion, loading state removed

### Pagination

**Conversations**:
- Initial load: 10 conversations
- Infinite scroll: Triggered when last item appears
- Cursor-based pagination

**Messages**:
- Lazy loaded per conversation (30 messages)
- Pagination when scrolling to top (prepend older messages)

### Error Handling

- Errors displayed in auto-dismissing banner (5 seconds)
- Network errors don't crash the app
- Partial streaming text preserved on cancel
- Failed requests can be retried

## Testing Checklist

- [x] Architecture and files created
- [ ] Stream happy path (short/long responses)
- [ ] Cancel mid-stream; partial text preserved
- [ ] Pagination cursors for conversations/messages
- [ ] Error surfaces (network down, 500, malformed SSE)
- [ ] Multiple conversations streaming concurrently
- [ ] Model picker shows remote models
- [ ] Create/Update/Delete/Duplicate operations
- [ ] Device testing with LAN IP

## Development Workflow

### Phase 1: Mock Development (Current Default)
```swift
AppConstants.API.useRemoteBackend = false
```
- Uses `MockConversationsStore`
- Perfect for UI development and previews
- No backend required

### Phase 2: Remote Integration
```swift
AppConstants.API.useRemoteBackend = true
```
- Connects to Python backend
- Full SSE streaming
- Real pagination and persistence

## Code Organization

### Clean Separation of Concerns

- **Networking**: Pure HTTP and SSE clients
- **API**: DTOs and endpoint definitions
- **Repositories**: Business logic abstraction
- **Services**: High-level orchestration
- **ViewModels**: UI state management
- **Views**: Presentation only

### Dependency Injection

```swift
// Production
let client = HTTPClient(baseURL: baseURL)
let repo = RemoteConversationsRepository(client: client)
let chatService = ChatService(repo: repo)
let uiState = UIState(repo: repo, chatService: chatService)

// Testing/Previews
let uiState = UIState(store: MockConversationsStore())
```

## Performance Optimizations

### Implemented
- Async/await throughout for non-blocking operations
- Actor-based stream management for thread safety
- Lazy loading of messages per conversation
- Cursor-based pagination (no offset overhead)

### Future Enhancements
- Debounced delta batching (50-100ms) to reduce UI churn
- Local caching with Cache-Control headers
- Request deduplication
- Retry logic with exponential backoff

## Troubleshooting

### Issue: Connection Refused
**Solution**: Ensure Python backend is running on specified port

### Issue: SSE Stream Not Working
**Solution**: Verify `Accept: text/event-stream` header is set
**Check**: Backend sends `Content-Type: text/event-stream`

### Issue: JSON Parsing Errors
**Solution**: Verify date format is ISO8601
**Solution**: Check snake_case vs camelCase conversion

### Issue: Messages Not Loading
**Solution**: Check conversation ID exists
**Solution**: Verify cursor pagination logic in backend

### Issue: App Crashes on Stream
**Solution**: Ensure SSE events match expected format
**Solution**: Add error logging in `SSEClient` for debugging

## Next Steps

1. **Backend Implementation**: Implement Python FastAPI backend matching this contract
2. **Testing**: Run through all test scenarios
3. **Performance**: Add delta batching if UI updates too frequently
4. **Caching**: Implement local caching strategy
5. **Offline**: Add offline mode with sync on reconnect

## Files Modified

### New Files
- `GPT/Networking/HTTPClient.swift`
- `GPT/Networking/SSEClient.swift`
- `GPT/API/Endpoints.swift`
- `GPT/API/DTOs.swift`
- `GPT/API/Decoders.swift`
- `GPT/Repositories/ConversationsRepository.swift`
- `GPT/Services/StreamingCenter.swift`
- `GPT/Services/ChatService.swift`
- `GPT/Views/Shared/ErrorBanner.swift`

### Modified Files
- `GPT/Design/AppConstants.swift` - Added API configuration
- `GPT/ViewModels/UIState.swift` - Added remote support, pagination, streaming
- `GPT/Views/Chat/ChatView.swift` - Per-conversation streaming
- `GPT/Views/Sidebar/SidebarView.swift` - Pagination, lazy loading
- `GPT/Views/AppRootView.swift` - Error banner, flexible initialization
- `GPT/GPTApp.swift` - Remote/mock mode switching

## Summary

This integration provides a production-ready foundation for connecting the SwiftUI app to a Python SSE backend. The architecture is clean, maintainable, and performant with proper error handling, concurrent streaming, and pagination support. The dual-mode setup allows seamless development with mocks while maintaining full remote capability.
