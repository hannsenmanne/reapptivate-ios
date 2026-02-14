import Foundation
@testable import Reapptivate

enum TestFixtures {

    // MARK: - UserProfile

    static func userProfile(
        id: String = "user-1",
        email: String = "test@test.com",
        name: String = "Test User",
        tendinopathyType: TendinopathyType = .achilles,
        startDate: String = "2025-01-01T00:00:00.000Z",
        aemScreeningCompleted: Bool? = nil,
        aemSubtype: AemSubtype? = nil,
        neckScreeningCompleted: Bool? = nil,
        adaptivePhase: Int? = nil,
        ndiSeverity: NdiSeverityGrade? = nil
    ) -> UserProfile {
        UserProfile(
            id: id,
            email: email,
            name: name,
            tendinopathyType: tendinopathyType,
            protocolId: "proto-1",
            startDate: startDate,
            createdAt: startDate,
            aemScreeningCompleted: aemScreeningCompleted,
            aemSubtype: aemSubtype,
            neckScreeningCompleted: neckScreeningCompleted,
            neckSubtype: nil,
            adaptivePhase: adaptivePhase,
            ndiSeverity: ndiSeverity
        )
    }

    static func lbpFarUser() -> UserProfile {
        userProfile(
            tendinopathyType: .lbpNonspecific,
            aemScreeningCompleted: true,
            aemSubtype: .FAR
        )
    }

    static func neckUser(screened: Bool = true) -> UserProfile {
        userProfile(
            tendinopathyType: .neckPain,
            neckScreeningCompleted: screened,
            ndiSeverity: .MITTEL
        )
    }

    // MARK: - ProgressEntry

    static func progressEntry(
        id: String = "entry-1",
        exerciseId: String = "ex-1",
        painLevel: Int = 3,
        setsCompleted: Int = 3,
        repsCompleted: Int = 10
    ) -> ProgressEntry {
        ProgressEntry(
            id: id,
            userId: "user-1",
            exerciseId: exerciseId,
            completedAt: "2025-06-01T10:00:00.000Z",
            setsCompleted: setsCompleted,
            repsCompleted: repsCompleted,
            painLevel: painLevel,
            notes: nil,
            symptomResponse: nil
        )
    }

    // MARK: - AdaptivePhaseStatus

    static func phaseStatus(
        currentPhase: Int = 1,
        daysInPhase: Int = 14,
        sessionsInPhase: Int = 6,
        lastDecision: AdaptationDecision = .initial
    ) -> AdaptivePhaseStatus {
        AdaptivePhaseStatus(
            currentPhase: currentPhase,
            phaseName: "Phase \(currentPhase)",
            daysInPhase: daysInPhase,
            sessionsInPhase: sessionsInPhase,
            lastDecision: lastDecision,
            lastDecisionReason: "Test reason",
            lastDecisionDate: nil,
            currentPainAvg: 2.5,
            currentCompliance: 0.8,
            progressionReadiness: ProgressionReadiness(
                minDaysMet: true,
                minSessionsMet: true,
                painCriteriaMet: true,
                complianceCriteriaMet: false
            ),
            nextEvaluationHint: "Keep going"
        )
    }

    // MARK: - AdaptationResult

    static func adaptationResult(
        decision: AdaptationDecision = .hold,
        currentPhase: Int = 1,
        previousPhase: Int = 1
    ) -> AdaptationResult {
        AdaptationResult(
            currentPhase: currentPhase,
            previousPhase: previousPhase,
            decision: decision,
            reason: "Test",
            reasonKey: "test_reason",
            avgPainLevel: 2.0,
            compliancePct: 0.85,
            sessionsInPhase: 6,
            daysInPhase: 14
        )
    }

    // MARK: - Exercise

    static func exercise(
        id: String = "ex-1",
        name: String = "Test Exercise",
        sets: Int = 3,
        reps: Int = 10
    ) -> Exercise {
        Exercise(
            id: id,
            name: name,
            type: .isometric,
            description: "A test exercise",
            sets: sets,
            reps: reps,
            holdTime: nil,
            restBetweenSets: 60,
            tempo: "3-0-3-0",
            videoUrl: nil,
            gifUrl: nil,
            intensity: "moderate",
            cognitiveCues: nil,
            aemSubtypeSpecific: nil,
            visualIndicator: nil
        )
    }

    // MARK: - JSON Response Helpers

    static func userResponseJSON(_ user: UserProfile? = nil) -> Data {
        let u = user ?? userProfile()
        return try! JSONEncoder().encode(UserResponse(user: u))
    }

    static func loginResponseJSON() -> Data {
        let json: [String: Any] = [
            "token": "fake-jwt-token",
            "user": [
                "id": "user-1",
                "name": "Test User",
                "email": "test@test.com",
                "tendinopathyType": "ACHILLES",
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func phaseStatusResponseJSON(_ status: AdaptivePhaseStatus? = nil) -> Data {
        let s = status ?? phaseStatus()
        return try! JSONEncoder().encode(PhaseStatusResponse(phaseStatus: s))
    }

    static func progressLogResponseJSON(
        entry: ProgressEntry? = nil,
        adaptation: AdaptationResult? = nil
    ) -> Data {
        let e = entry ?? progressEntry()
        return try! JSONEncoder().encode(ProgressLogResponse(entry: e, adaptation: adaptation))
    }

    static func statsResponseJSON() -> Data {
        let json: [String: Any] = [
            "stats": [
                "totalSessions": 25,
                "averagePainLevel": 2.5,
                "lastSevenDays": 4,
                "currentWeekCompliance": 0.8,
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func todayProgressResponseJSON() -> Data {
        let json: [String: Any] = [
            "completedExercises": [
                [
                    "id": "entry-1",
                    "exerciseId": "ex-1",
                    "completedAt": "2025-06-01T10:00:00.000Z",
                    "setsCompleted": 3,
                    "repsCompleted": 10,
                    "painLevel": 2,
                ]
            ],
            "count": 1,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - StreakData

    static func streakData(
        currentStreak: Int = 5,
        longestStreak: Int = 12,
        freezeTokens: Int = 1,
        lastTrainingDate: String? = nil
    ) -> StreakData {
        StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            freezeTokens: freezeTokens,
            lastTrainingDate: lastTrainingDate
        )
    }

    static func streakResponseJSON(
        currentStreak: Int = 5,
        longestStreak: Int = 12,
        freezeTokens: Int = 1,
        lastTrainingDate: String? = nil
    ) -> Data {
        var json: [String: Any] = [
            "currentStreak": currentStreak,
            "longestStreak": longestStreak,
            "freezeTokens": freezeTokens,
        ]
        if let date = lastTrainingDate {
            json["lastTrainingDate"] = date
        }
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func errorResponseJSON(message: String = "Something went wrong") -> Data {
        let json: [String: Any] = ["error": "Error", "message": message]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
