# iOS Planning Architect Memory

## Project Structure - Condition Groups
- **Current conditions in codebase**: Tendinopathy (8 subtypes), LBP (4 AEM subtypes: FAR/DER/EER/AR), Neck Pain
- Previous NST implementation was REMOVED (git status shows 15+ deleted NeckShoulder files, not yet staged)
- `TendinopathyType` enum has 10 cases (8 tendinopathy + lbpNonspecific + neckPain)

## Key File Locations
- Condition-specific views: `Views/LBP/` (13 files), `Views/Neck/` (4 files: NeckProfileView, NdiProgressView, NeckFocusAreasView, NeckMicroModulesView)
- Models: `LbpTypes.swift` (includes MicroModule, MicroModuleCompletion), `NeckTypes.swift` (95 lines), `SharedTypes.swift` (enums)
- Endpoints: `Services/Networking/APIEndpoints.swift` -- Neck: 7 endpoints (config, screening x2, result, history, focus-areas, micro-modules x4)
- Tab bar: `DashboardTabBar` is inside `DashboardView.swift`
- Screening: `Views/Screening/` -- Neck: NeckScreeningView, NeckQuestionView, NeckResultView
- Protocol JSONs: `Resources/Protocols/` (14 files, neck has neck_pain.json + neck_radiculopathy.json)

## Architecture Patterns Confirmed
- Screening flow: VM created in `.task`, loads config from API, navigates questions, submits, shows result, refreshes profile
- NeckScreeningVM: 2-part (A=radiculopathy, B=NDI), rescreening skips Part A
- Neck dashboard views use inline `@State` + API calls (no centralized VM like LBP's LbpEnhancementsViewModel)
- `MicroModule`/`MicroModuleCompletion` in LbpTypes.swift, shared by Neck endpoints (same response shape)
- `NdiSeverityGrade` enum (LEICHT/MITTEL/SCHWER) with `from(ndiScore:)` in SharedTypes.swift
- `Color.severityColor(for:)` maps NdiSeverityGrade to colors
- DashboardViewModel.loadDashboard() fetches neckResult to populate ndiSeverity when isNeck==true
- ProtocolLoader returns "neck_pain" for .neckPain; does NOT vary by severity
- UserProfile.maxPhase: 4 for neck, 3 for others

## Test Infrastructure
- ~103 tests in Tests/ReapptivateTests/ across Models, Services, ViewModels, AppState
- TestFixtures.neckUser() and userProfile() factories exist
- AppStateTests tests isNeck, needsNeckScreening; SharedTypesTests tests NdiSeverityGrade
- All VM/Service tests use @MainActor + `override func setUp() async throws`

## EducationCard System
- EducationCardLoader filters by card.condition: nil=generic, "LBP_NONSPECIFIC", "NECK_PAIN"
- WissenCardView/WissenAllCardsView take isLbp/isNeck booleans

## Navigation Flow
- RootView: isCheckingAuth -> LoginView -> AemScreening (LBP) -> NeckScreening (Neck) -> ScreeningComplete -> Walkthrough -> Dashboard
- InsightsTab: LBP=AnalyticsDashboardView, Neck=NeckInsightsSection
- EdukationTab: LBP=micro-modules+wissen, Neck=NeckMicroModulesView+wissen, others=wissen only
- Tab bar showInsights: appState.isLbp || appState.isNeck
