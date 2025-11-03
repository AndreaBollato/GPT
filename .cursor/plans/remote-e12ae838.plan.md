<!-- e12ae838-79f1-420a-854a-783900e48abd 096717d9-e7d9-4277-a620-af9c69e51aeb -->
# Remote Call Feedback Plan

Goal: I’d like to have some kind of notification or visual feedback — for example, when I send a message, there should be an animation indicating that the request to Python is being processed, and if any issue occurs during the communication, it should display an error message or warning.

Some ideas, buf **fix all you need**:

1. Stabilize remote state in `GPT/ViewModels/UIState.swift`

- Track per-conversation request phases (sending, streaming, error) so views know when a call is in flight.
- Ensure network failures keep placeholder messages and surface `errorMessage` with descriptive text.

2. Add visible progress cues in chat views

- Update `GPT/Views/Chat/MessageRowView.swift` and `ComposerView.swift` to show an explicit spinner/animation while `isLoading` messages stream.
- In `GPT/Views/Chat/ChatView.swift` (and Home if needed) surface a lightweight overlay or status banner driven by the new state to signal “richiesta in corso”.

3. Elevate error presentation for Python connectivity issues

- Enhance `ErrorBanner` usage (e.g., keep it visible until dismissed, optionally add icon/color tweaks) and ensure it appears whenever backend calls fail.
- Optionally tag failed assistant messages with an inline warning style so the conversation itself reflects the error.

4. Verification

- Manual build & run: send message with backend up (see animation) and with backend down (see banner + inline error).
- Adjust documentation snippets if needed to reflect the new UX.

TODO

- [ ] Extend UIState with per-conversation call status and reliable error propagation
- [ ] Update chat/composer views to display spinners or overlays based on the new state
- [ ] Improve banner and inline error styling for backend failures
- [ ] Manually test streaming success/failure paths and update docs if required

### To-dos

- [ ] Extend UIState with per-conversation call status and reliable error propagation
- [ ] Update chat/composer views to display spinners or overlays based on the new state
- [ ] Improve banner and inline error styling for backend failures
- [ ] Manually test streaming success/failure paths and update docs if required