# Reapptivate iOS

Native iOS companion app for the Reapptivate physiotherapy platform.

## Overview

This is the native iOS application that provides offline-capable exercise tracking, local notifications, and audio guidance for patients undergoing evidence-based tendinopathy rehabilitation and low back pain management.

## Tech Stack

- **Platform**: iOS 17.0+
- **Language**: Swift 6.0+
- **UI Framework**: SwiftUI with @Observable state management
- **Architecture**: MVVM
- **Networking**: URLSession with async/await
- **Local Storage**: SwiftData
- **Audio**: AVAudioPlayer
- **Notifications**: UserNotifications framework (local only)

## Features

### Core Features
- Exercise protocols with video demonstrations
- Pain-adaptive phase progression
- Real-time exercise tracking with audio guidance
- Local notification scheduling
- Offline-first data synchronization
- AEM psychobehavioral subtype support (LBP patients)

### Supported Conditions
- **Tendinopathies**: Tennis Elbow, Golfer's Elbow, Achilles, Patellar, Rotator Cuff, Gluteal, Proximal Hamstring, Plantar Fascia
- **Musculoskeletal**: Non-Specific Low Back Pain (with AEM subtyping)

## Architecture

```
Reapptivate/
├── App/
│   ├── ReapptivateApp.swift          # App entry point
│   └── AppDelegate.swift              # Lifecycle management
├── Models/
│   ├── Exercise.swift                 # Exercise entity
│   ├── Protocol.swift                 # Protocol entity
│   ├── ProgressEntry.swift            # Progress logging
│   └── UserProfile.swift              # User data
├── ViewModels/
│   ├── AuthViewModel.swift            # Authentication state
│   ├── ExerciseViewModel.swift        # Exercise session logic
│   └── ProgressViewModel.swift        # Progress tracking
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift
│   ├── Dashboard/
│   │   └── DashboardView.swift
│   ├── Exercise/
│   │   ├── ExerciseSessionView.swift
│   │   └── ExerciseDetailView.swift
│   └── Progress/
│       └── ProgressHistoryView.swift
├── Services/
│   ├── APIService.swift               # Backend communication
│   ├── AudioService.swift             # Exercise audio guidance
│   ├── NotificationService.swift      # Local notifications
│   └── SyncService.swift              # Offline sync
└── Utils/
    ├── KeychainHelper.swift           # Secure token storage
    └── Logger.swift                   # Logging utility
```

## API Integration

The iOS app communicates with the backend API at:
- **Local Development**: `http://localhost:3000/api`
- **Production**: `https://physio-app-server-production.up.railway.app/api`

### Key Endpoints
- `POST /onboarding/login` - Patient authentication
- `GET /patient/me` - User profile
- `GET /patient/schedule` - Training schedule
- `POST /patient/progress` - Log exercise completion
- `GET /patient/phase-status` - Adaptive phase info
- `GET /aem/result` - AEM screening result (LBP only)

## Setup Instructions

### Prerequisites
- macOS 14.0+
- Xcode 15.0+
- Swift 6.0+
- Active backend API (see main repo: [physio-app](https://github.com/hannsenmanne/physio-app))

### Installation
1. Clone this repository
2. Open `Reapptivate.xcodeproj` in Xcode
3. Select a simulator or device
4. Build and run (⌘R)

### Configuration
- API base URL is configured in `APIService.swift`
- Change `baseURL` for local development vs production

## Development Status

**Current Phase**: M0 - Prerequisites
- ✅ M0.1: Schedule endpoints (backend)
- 🔄 M0.2: Protocol translation script (in progress)
- ⏳ M1: Xcode project setup
- ⏳ M2-M10: Feature implementation

See [ios-app-implementation-v2.md](/.claude/plans/ios-app-implementation-v2.md) for full roadmap.

## Testing

Run tests with:
```bash
⌘U in Xcode
```

Test coverage includes:
- Unit tests for ViewModels
- Integration tests for API services
- UI tests for critical user flows

## Deployment

### TestFlight Distribution
1. Archive the app (Product → Archive)
2. Upload to App Store Connect
3. Add to TestFlight for internal testing
4. Invite external testers

### App Store Submission
- Requires Apple Developer Program membership
- Follows standard App Store Review Guidelines
- No background audio tricks (uses local notifications only)

## Related Repositories

- **Backend + Web App**: [physio-app](https://github.com/hannsenmanne/physio-app)

## License

TBD

## Contact

For questions or support, contact the development team.
