# Models & Networking Layer Review Notes (2026-03-08)

## Key Structural Observations
- 21 domain model files, 1 APIResponses file, 5 networking files
- APIClient uses 3 request methods with identical retry logic (known duplication)
- `DateFormatters.apiDecoder` is dead code -- never referenced outside its declaration
- `LoginUser` struct is only used in AuthTypes for decoding, actual login flow fetches full `UserProfile` via `/patient/me`
- `PendingSync.syncId` now has `@Attribute(.unique)` -- previously flagged issue is fixed

## PostgreSQL Numeric String Handling
- Consistent `flexibleDouble`/`flexibleInt` extensions on `KeyedDecodingContainer` in AclTypes.swift
- Manual Double-or-String decoding in PhaseAdaptation.swift (AdaptivePhaseStatus, AdaptationResult, PhaseAdaptationRecord)
- These two approaches accomplish the same thing -- could be unified

## Model-Backend Alignment Issues Found
- `CustomExercise.extra` is optional String? -- correctly handles null from backend
- `AclDailyKpiListResponse` has dual optional keys (`kpis` and `entries`) -- defensive but awkward
- `AclWeeklyKpiListResponse` same dual-key pattern
- `AclCompletedModulesResponse` also dual-key (`completions` and `completedModules`)

## AnyCodable Decode Order
- Order: nil -> String -> Int -> Double -> Bool -> Dict -> Array
- This is correct: Int before Bool prevents JSON numbers being decoded as booleans
