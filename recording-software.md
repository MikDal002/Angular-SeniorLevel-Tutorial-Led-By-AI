# Recording Software Selection

This document outlines the process of selecting a suitable screen recording software for creating tutorial videos.

## Requirements

- Must work reliably within a Windows Sandbox environment.
- Should have adequate video editing capabilities, including the ability to speed up or slow down sections of the recording.
- Preferably free or low-cost.
- Good-to-have: Installation via `winget`.

## Options Considered

### 1. Cap (version 0.3.67)

- **Pros:**
  - Unknown, as it could not be fully evaluated.
- **Cons:**
  - Fails to start recording within the Windows Sandbox environment, making it unusable for this project. A bug seems to prevent the recording process from initializing.
  - Not available via `winget`.

### 2. Free Cam (version 8.7.0)

- **Pros:**
  - Successfully records within the Windows Sandbox environment.
- **Cons:**
  - Very limited post-recording editing features.
  - Lacks essential functions like speeding up parts of the video, which is crucial for condensing long, repetitive tasks in tutorials.
  - Not available via `winget`.

## Conclusion

Neither of the evaluated tools fully meets the project requirements. **Free Cam** is the current workaround, but its editing limitations are a significant drawback. Further investigation is needed to find a more suitable alternative that combines reliable recording in a sandboxed environment with more advanced editing features.