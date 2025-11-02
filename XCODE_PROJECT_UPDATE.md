# Xcode Project Update Instructions

## New Files to Add

The following files need to be added to the Xcode project:

### Networking Group
- `GPT/Networking/HTTPClient.swift`
- `GPT/Networking/SSEClient.swift`

### API Group
- `GPT/API/Endpoints.swift`
- `GPT/API/DTOs.swift`
- `GPT/API/Decoders.swift`

### Repositories Group
- `GPT/Repositories/ConversationsRepository.swift`

### Services Group
- `GPT/Services/StreamingCenter.swift`
- `GPT/Services/ChatService.swift`

### Views/Shared Group
- `GPT/Views/Shared/ErrorBanner.swift`

## Manual Steps in Xcode

1. **Open the project in Xcode**:
   ```bash
   open GPT.xcodeproj
   ```

2. **Create Group Structure**:
   - Right-click on `GPT` folder in Project Navigator
   - New Group ? Name: `Networking`
   - New Group ? Name: `API`
   - New Group ? Name: `Repositories`
   - New Group ? Name: `Services`

3. **Add Files**:
   - For each group, right-click and select "Add Files to GPT..."
   - Navigate to the corresponding directory
   - Select all `.swift` files in that directory
   - ? Check "Copy items if needed" (should be unchecked since files are already there)
   - ? Check "Add to targets: GPT"
   - Click "Add"

4. **Add ErrorBanner.swift**:
   - Right-click on `GPT/Views/Shared`
   - "Add Files to GPT..."
   - Select `ErrorBanner.swift`

5. **Verify**:
   - Build the project (?B)
   - All files should compile without errors
   - Check that all new files appear in the Project Navigator

## Alternative: Command Line (if using xcodebuild)

```bash
cd /workspace

# You can also use a Ruby script with xcodeproj gem:
# gem install xcodeproj
# Then create a script to add files programmatically
```

## Build Settings

No additional build settings or dependencies are required. All new code uses:
- Swift standard library
- Foundation framework
- SwiftUI (already linked)

## Target Membership

All new `.swift` files should be members of:
- ? GPT (main app target)
- ? GPT Tests (not needed unless adding tests)

## Expected Build Result

After adding all files and building:
- ? 0 errors
- ? 0 warnings
- ? All new types available in code completion
- ? App runs with mock data (default mode)

## Testing the Integration

1. **Build and Run** (?R)
2. **Verify mock mode works**: App should function normally
3. **Switch to remote mode**:
   - Edit `GPT/Design/AppConstants.swift`
   - Set `useRemoteBackend = true`
   - Update `baseURL` if needed
4. **Start Python backend** (when ready)
5. **Build and Run again**
6. **Test streaming**: Send a message and observe SSE streaming

## Notes

- The project structure is designed to be clean and modular
- Each layer has clear responsibilities
- Mock mode works without any backend
- Remote mode requires Python backend to be running
- All files follow Swift naming conventions
- Code is formatted and documented

## Troubleshooting

### "No such file or directory"
**Solution**: Verify files exist in workspace using `ls -la GPT/Networking/`

### "Duplicate symbol"
**Solution**: Check that files aren't added twice to the target

### "Cannot find type"
**Solution**: Ensure all files are added to the GPT target (check Target Membership)

### Build fails with missing imports
**Solution**: All required imports are Foundation and SwiftUI - ensure target has proper framework links
