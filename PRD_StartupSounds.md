## Product Requirements Document: StartupSounds

**1. Introduction & Purpose**

StartupSounds is a desktop application that enhances the user experience by playing a distinct, short audio cue each time a designated application is launched. This PRD outlines the current state, desired future functionality, and initial requirements for evolving StartupSounds from its current iteration into a more user-friendly and customizable application.

**2. Goals**

*   **Short-term:**
    *   Transition the application from a menu bar utility to a standalone application with a dedicated UI.
    *   Formalize the 3.25-second maximum duration for startup sounds, including a fade-out for longer files.
*   **Mid-term:**
    *   Allow users to add their own custom applications to be tracked.
    *   Allow users to upload and assign their own custom sound files for any tracked application.
*   **Long-term:**
    *   Provide a delightful and unobtrusive user experience.
    *   Enable the application to start automatically at system login.
    *   Explore options for a library of pre-set sounds.
    *   Explore the potential for an integrated marketplace where users can discover, share, or purchase curated startup sounds (very long-term).

**3. Current State (as of [Current Date] - *User to fill in* )**

*   The application can successfully detect the launch of two specific applications: "WindSurf" and "Cursor."
*   Upon detection, a pre-defined sound file (unique to each of the two apps) is played.
*   Each of the current sound files is 3.25 seconds in duration.
*   The application currently resides in the startup menu bar, with a music note icon.

**4. Target Users & Use Cases**

*   **Target Users:** Desktop users who appreciate personalization, auditory feedback, and a more engaging computing experience.
*   **Use Cases:**
    *   **As a user, I want to hear a satisfying sound when I launch my favorite or frequently used applications so that I get immediate auditory confirmation and a moment of delight.** (Current & Future)
    *   **As a user, I want to easily see which applications are configured to have startup sounds and manage these settings.** (Future - tied to new UI)
    *   **As a user, I want to be able to add new applications to the list of apps that trigger a startup sound so I can customize the experience for my workflow.** (Future)
    *   **As a user, I want to replace the default startup sounds with my own audio files so I can fully personalize the application.** (Future)
    *   **As a user, I want the application to have a simple, intuitive interface that is separate from the system menu bar for easier access and management.** (Future - Core of next development phase)

**5. Proposed Features & Requirements**

**5.1. Core Sound Playback Engine**

*   **REQ-001:** The application MUST detect the launch of configured applications.
    *   *Current:* WindSurf, Cursor.
    *   *Future:* User-defined applications.
*   **REQ-002:** Upon detecting an application launch, the application MUST play the assigned startup sound.
*   **REQ-003:** Startup sounds MUST have a maximum duration of 3.25 seconds.
*   **REQ-004:** If a sound file assigned to an application is longer than 3.25 seconds, the application MUST play the first 3.25 seconds and implement a clean fade-out effect starting slightly before the 3.25-second mark to avoid an abrupt cutoff. The fade-out should be noticeable but quick, within the last 0.25-0.5 seconds of the playback.
*   **REQ-005:** The application should handle cases where a sound file is missing or corrupted gracefully (e.g., play no sound, log an error silently).

**5.2. Application User Interface (Phase 1 - Detach from Menu Bar)**

*   **REQ-006:** The application MUST function as a standalone desktop application with its own window and UI, not solely as a menu bar item.
*   **REQ-007:** The application MUST be launchable like any other standard application (e.g., from the Applications folder, Dock, or Spotlight search).
*   **REQ-008:** Upon launch, the application UI SHOULD present a clear and intuitive way to see the currently configured applications and their assigned sounds (even if initially hardcoded and not yet editable by the user).
*   **REQ-009:** The application icon SHOULD be updated to something representative of the app's core function (sound, customization) and distinct from a generic music note if a more specific design is desired. (Open for discussion - current music note might be fine if the app is named StartupSounds).
*   **REQ-010:** The application MUST provide a clear way to be quit/closed.
*   **REQ-011:** The application MUST run in the background to monitor app launches once configured and the main UI window is closed (or minimized). A separate action (e.g., from a system tray/menu bar icon or an explicit "Quit" option in the app's menu) should be required to stop the monitoring service entirely.
*   **REQ-011a (ASAP):** The application's menu bar icon MUST provide a right-click (or control-click) context menu with an option to "Quit" the application entirely, stopping all monitoring.
*   **REQ-011b (ASAP):** Whenever the application's main window is opened (e.g., on initial launch, or when re-opened from the Dock/menu bar), it MUST come to the very front of all other application windows.

**5.3. Customization (Future Phases)**

*   **REQ-012 (Future):** Users MUST be able to add new applications to be monitored.
    *   This will require a UI mechanism to browse/select installed applications.
*   **REQ-013 (Future):** Users MUST be able to upload their own sound files (e.g., .mp3, .wav, .aiff).
*   **REQ-014 (Future):** Users MUST be able to assign custom sounds to any monitored application, replacing the default sounds.
*   **REQ-015 (Future):** The UI MUST provide a clear way to manage (add, edit, delete) tracked applications and their assigned sounds.
*   **REQ-016 (Future):** The application SHOULD offer an option to automatically start at system login.
*   **REQ-017 (Future - Very Long Term):** Explore feasibility and design for an integrated marketplace for startup sounds, allowing users to discover, share, or purchase curated sounds.

**5.4. Advanced Customization & System Integration (Future Ideas)**

*   **IDEA-001 (Future):** Explore the possibility of using symbolic links (symlinks) to allow users to replace the entire sound set of specific applications (e.g., "Cursor") with a custom sound pack managed by StartupSounds. This could enable deeper customization beyond just startup sounds.
*   **IDEA-002 (Future):** Investigate the concept of "Custom Artist Packs" – curated collections of sounds (potentially including startup sounds, UI interaction sounds, system notifications, etc.) that users could apply to their entire OS or specific libraries of applications, offering a thematic audio overhaul.

**6. Non-Functional Requirements**

*   **NFR-001 (Performance):** Application launch detection and sound playback should be near-instantaneous, with no perceptible lag.
*   **NFR-002 (Resource Usage):** The background monitoring process should have minimal impact on system resources (CPU, memory).
*   **NFR-003 (Stability):** The application should be stable and not crash or interfere with the normal operation of the OS or other applications.
*   **NFR-004 (Usability):** The UI (once developed) should be intuitive and easy to use, even for non-technical users.

**7. Open Questions & Future Considerations**

*   How should the application handle multiple application launches in rapid succession? (e.g., queue sounds, play only the first/last, play concurrently if possible and not jarring?)
*   Specifics of the fade-out curve for REQ-004.
*   Error handling and user feedback for failed sound plays, inability to find an app, etc.
*   Platform considerations (initially macOS? Windows? Cross-platform?) - *Assuming macOS for now based on "startup menu" and "Cursor" app.*
*   Mechanism for the background service to start on system login.

--- 