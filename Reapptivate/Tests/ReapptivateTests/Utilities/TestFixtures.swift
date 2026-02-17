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
        tsiScreeningCompleted: Bool? = nil,
        tsiSeverity: TsiSeverityGrade? = nil,
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
            tsiScreeningCompleted: tsiScreeningCompleted,
            tsiSeverity: tsiSeverity,
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

    static func tensionUser(screened: Bool = true, severity: TsiSeverityGrade = .LEICHT) -> UserProfile {
        userProfile(
            tendinopathyType: .neckShoulderTension,
            tsiScreeningCompleted: screened,
            tsiSeverity: severity
        )
    }

    // MARK: - TSI Screening Fixtures

    static func makeTsiScreeningConfig() -> TsiScreeningConfig {
        TsiScreeningConfig(
            version: "1.0",
            items: (1...10).map { i in
                TsiScreeningItem(
                    id: "tsi-\(i)",
                    textDe: "Frage \(i): Wie stark ist Ihre Verspannung?",
                    options: [
                        TsiScreeningOption(value: 0, labelDe: "Gar nicht"),
                        TsiScreeningOption(value: 1, labelDe: "Etwas"),
                        TsiScreeningOption(value: 2, labelDe: "Mäßig"),
                        TsiScreeningOption(value: 3, labelDe: "Ziemlich"),
                        TsiScreeningOption(value: 4, labelDe: "Sehr stark"),
                        TsiScreeningOption(value: 5, labelDe: "Extrem"),
                    ]
                )
            }
        )
    }

    static func makeTsiScreeningResult(score: Int = 12) -> TsiScreeningResult {
        let category = TsiSeverityGrade.from(tsiScore: score)
        return TsiScreeningResult(
            id: "tsi-result-1",
            tsiScore: score,
            tsiCategory: category.rawValue,
            createdAt: "2025-06-01T10:00:00.000Z"
        )
    }

    static func makeTsiFocusArea() -> TsiFocusArea {
        TsiFocusArea(
            domainId: "shoulder_tension",
            domainLabel: "Schulterverspannung",
            score: 3,
            maxScore: 5,
            dailyTips: ["Schultern regelmäßig kreisen", "Pausen einlegen"]
        )
    }

    static func makeTsiHistoryEntry() -> TsiHistoryEntry {
        TsiHistoryEntry(
            id: "tsi-hist-1",
            tsiScore: 18,
            tsiCategory: "MITTEL",
            severityGrade: .MITTEL,
            createdAt: "2025-06-01T10:00:00.000Z"
        )
    }

    // MARK: - TSI JSON Response Helpers

    static func tsiScreeningConfigResponseData() -> Data {
        let json: [String: Any] = [
            "version": "1.0",
            "items": (1...10).map { i in
                [
                    "id": "tsi-\(i)",
                    "textDe": "Frage \(i): Wie stark ist Ihre Verspannung?",
                    "options": [
                        ["value": 0, "labelDe": "Gar nicht"],
                        ["value": 1, "labelDe": "Etwas"],
                        ["value": 2, "labelDe": "Mäßig"],
                        ["value": 3, "labelDe": "Ziemlich"],
                        ["value": 4, "labelDe": "Sehr stark"],
                        ["value": 5, "labelDe": "Extrem"],
                    ]
                ] as [String: Any]
            },
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func tsiScreeningResultResponseData(score: Int = 12) -> Data {
        let category = TsiSeverityGrade.from(tsiScore: score).rawValue
        let json: [String: Any] = [
            "screening": [
                "id": "tsi-result-1",
                "tsiScore": score,
                "tsiCategory": category,
                "createdAt": "2025-06-01T10:00:00.000Z",
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func tsiFocusAreasResponseData() -> Data {
        let json: [String: Any] = [
            "focusAreas": [
                [
                    "domainId": "shoulder_tension",
                    "domainLabel": "Schulterverspannung",
                    "score": 3,
                    "maxScore": 5,
                    "dailyTips": ["Schultern regelmäßig kreisen", "Pausen einlegen"],
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func tsiHistoryResponseData() -> Data {
        let json: [String: Any] = [
            "history": [
                [
                    "id": "tsi-hist-1",
                    "tsiScore": 18,
                    "tsiCategory": "MITTEL",
                    "severityGrade": "MITTEL",
                    "createdAt": "2025-06-01T10:00:00.000Z",
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
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

    static func errorResponseJSON(message: String = "Something went wrong") -> Data {
        let json: [String: Any] = ["error": "Error", "message": message]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
