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
        tensionScreeningCompleted: Bool? = nil,
        tsiSeverity: TsiSeverityGrade? = nil,
        adaptivePhase: Int? = nil,
        ndiSeverity: NdiSeverityGrade? = nil,
        aclScreeningCompleted: Bool? = nil,
        aclAthleteLevel: AclAthleteLevel? = nil,
        aclGraftType: AclGraftType? = nil,
        aclSurgeryDate: String? = nil,
        aclCurrentMilestone: Int? = nil,
        aclConcomitantInjuries: [AclConcomitantInjury]? = nil
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
            tensionScreeningCompleted: tensionScreeningCompleted,
            tsiSeverity: tsiSeverity,
            aclScreeningCompleted: aclScreeningCompleted,
            aclAthleteLevel: aclAthleteLevel,
            aclGraftType: aclGraftType,
            aclSurgeryDate: aclSurgeryDate,
            aclCurrentMilestone: aclCurrentMilestone,
            aclConcomitantInjuries: aclConcomitantInjuries,
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
            tensionScreeningCompleted: screened,
            tsiSeverity: severity
        )
    }

    static func aclUser(screened: Bool = true, milestone: Int = 1) -> UserProfile {
        userProfile(
            tendinopathyType: .aclReconstruction,
            aclScreeningCompleted: screened,
            aclAthleteLevel: .recreational,
            aclGraftType: .hamstring,
            aclSurgeryDate: "2025-09-01",
            aclCurrentMilestone: milestone,
            aclConcomitantInjuries: [.none]
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

    // MARK: - Work Timer Fixtures

    static func makeWorkTimerSettings() -> WorkTimerSettings {
        WorkTimerSettings(
            startTime: "08:00",
            endTime: "17:00",
            breakIntervalMinutes: 60,
            breakDurationMinutes: 3,
            isEnabled: true
        )
    }

    static func makeWorkTimerExercise(
        id: String = "wt_test_1",
        name: String = "Test-Übung",
        category: String = "mobility"
    ) -> WorkTimerBreakExercise {
        WorkTimerBreakExercise(
            id: id,
            name: name,
            description: "Stehen Sie auf und machen Sie die Übung.",
            durationSeconds: 45,
            targetConditions: ["LBP_NONSPECIFIC"],
            minPhase: 1,
            category: category
        )
    }

    static func makeWorkTimerSummary(
        breaksCompleted: Int = 6,
        breaksSkipped: Int = 2
    ) -> WorkTimerDaySummary {
        let offered = breaksCompleted + breaksSkipped
        let adherence = offered > 0 ? Double(breaksCompleted) / Double(offered) * 100 : 0
        return WorkTimerDaySummary(
            date: "2026-02-18",
            totalWorkMinutes: 480,
            breaksOffered: offered,
            breaksCompleted: breaksCompleted,
            breaksSkipped: breaksSkipped,
            adherencePercent: adherence
        )
    }

    static func workTimerSettingsResponseData() -> Data {
        let json: [String: Any] = [
            "settings": [
                "startTime": "08:00",
                "endTime": "17:00",
                "breakIntervalMinutes": 60,
                "breakDurationMinutes": 3,
                "isEnabled": true,
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func workTimerExercisesResponseData() -> Data {
        let json: [String: Any] = [
            "exercises": [
                [
                    "id": "wt_lbp_pelvic_tilt",
                    "name": "Beckenkippung im Stehen",
                    "description": "Stehen Sie auf.",
                    "durationSeconds": 45,
                    "targetConditions": ["LBP_NONSPECIFIC"],
                    "minPhase": 1,
                    "category": "mobility",
                ],
                [
                    "id": "wt_neck_chin_tuck",
                    "name": "Chin Tucks",
                    "description": "Ziehen Sie Ihr Kinn nach hinten.",
                    "durationSeconds": 40,
                    "targetConditions": ["NECK_NONSPECIFIC", "NECK_SHOULDER_TENSION"],
                    "minPhase": 1,
                    "category": "mobility",
                ],
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func workTimerSummaryResponseData() -> Data {
        let json: [String: Any] = [
            "summary": [
                "date": "2026-02-18",
                "totalWorkMinutes": 480,
                "breaksOffered": 8,
                "breaksCompleted": 6,
                "breaksSkipped": 2,
                "adherencePercent": 75.0,
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
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
            "completedExercises": ["ex-1"],
            "count": 1,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func errorResponseJSON(message: String = "Something went wrong") -> Data {
        let json: [String: Any] = ["error": "Error", "message": message]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - ACL JSON Response Helpers

    static func aclDailyKpiJSON() -> Data {
        let json: [String: Any] = [
            "kpi": [
                "id": "daily-kpi-1",
                "date": "2025-10-15",
                "painNrs": 4,
                "painLocation": "anterior",
                "painActivity": "walking",
                "kneeFlexionDeg": 110,
                "extensionDeficitDeg": 5,
                "swellingGrade": 1,
                "quadsLag": false,
                "notes": "Feeling better",
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclDailyKpiHistoryJSON() -> Data {
        let json: [String: Any] = [
            "kpis": [
                [
                    "id": "daily-kpi-1",
                    "date": "2025-10-15",
                    "painNrs": 4,
                    "kneeFlexionDeg": 110,
                    "extensionDeficitDeg": 5,
                    "swellingGrade": 1,
                    "quadsLag": false,
                ],
                [
                    "id": "daily-kpi-2",
                    "date": "2025-10-14",
                    "painNrs": 5,
                    "kneeFlexionDeg": 100,
                    "extensionDeficitDeg": 8,
                    "swellingGrade": 2,
                    "quadsLag": true,
                ],
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclWeeklyKpiJSON() -> Data {
        let json: [String: Any] = [
            "kpi": [
                "id": "weekly-kpi-1",
                "weekDate": "2025-10-13",
                "ikdcScore": 55,
                "tampaScore": 30,
                "thighCirc5cm": 42.5,
                "thighCirc10cm": 48.0,
            ],
            "tampaAlert": false,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclWeeklyKpiHistoryJSON() -> Data {
        let json: [String: Any] = [
            "kpis": [
                [
                    "id": "weekly-kpi-1",
                    "weekDate": "2025-10-13",
                    "ikdcScore": 55,
                    "tampaScore": 30,
                    "thighCirc5cm": 42.5,
                    "thighCirc10cm": 48.0,
                ],
                [
                    "id": "weekly-kpi-2",
                    "weekDate": "2025-10-06",
                    "ikdcScore": 48,
                    "tampaScore": 35,
                    "thighCirc5cm": 41.0,
                    "thighCirc10cm": 47.0,
                ],
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclMilestoneStatusJSON() -> Data {
        let json: [String: Any] = [
            "currentMilestone": 2,
            "weeksPostSurgery": 8,
            "isPreOp": false,
            "athleteLevel": "RECREATIONAL",
            "graftType": "HAMSTRING",
            "surgeryDate": "2025-09-01",
            "concomitantInjuries": ["NONE"],
            "nextCriteria": [
                [
                    "id": "crit-1",
                    "label": "Quad LSI",
                    "labelDE": "Quad LSI",
                    "field": "quadLsi",
                    "threshold": 70.0,
                    "unit": "%",
                    "met": false,
                    "currentValue": "55.0",
                    "operator": ">=",
                ]
            ],
            "isReadyForLab": false,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclStreamsResponseJSON() -> Data {
        let json: [String: Any] = [
            "streams": [
                [
                    "id": "stream-rom",
                    "name": "ROM Recovery",
                    "nameDE": "ROM Wiederherstellung",
                    "description": "Range of motion exercises",
                    "unlockMilestone": 0,
                    "milestone": 1,
                    "isUnlocked": true,
                    "locked": false,
                    "exerciseCount": 5,
                ],
                [
                    "id": "stream-strength",
                    "name": "Strength",
                    "nameDE": "Kraft",
                    "description": "Strengthening exercises",
                    "unlockMilestone": 2,
                    "milestone": 2,
                    "isUnlocked": true,
                    "locked": false,
                    "exerciseCount": 8,
                ],
                [
                    "id": "stream-plyo",
                    "name": "Plyometrics",
                    "nameDE": "Plyometrie",
                    "description": "Plyometric exercises",
                    "unlockMilestone": 3,
                    "milestone": 3,
                    "isUnlocked": false,
                    "locked": true,
                    "exerciseCount": 4,
                ],
            ],
            "currentMilestone": 2,
            "weeksPostSurgery": 8,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclScreeningConfigJSON() -> Data {
        let json: [String: Any] = [
            "version": "1.0",
            "title": "ACL Screening",
            "titleDE": "ACL Screening",
            "description": "Complete the ACL screening",
            "descriptionDE": "Bitte füllen Sie das ACL Screening aus",
            "steps": [
                [
                    "id": "surgery_date",
                    "label": "Surgery Date",
                    "labelDE": "OP-Datum",
                    "type": "date",
                    "required": true,
                ],
                [
                    "id": "graft_type",
                    "label": "Graft Type",
                    "labelDE": "Transplantattyp",
                    "type": "radio",
                    "required": true,
                    "options": [
                        [
                            "value": "HAMSTRING",
                            "label": "Hamstring",
                            "labelDE": "Hamstring (Semitendinosus)",
                        ],
                        [
                            "value": "PATELLAR_TENDON",
                            "label": "Patellar Tendon",
                            "labelDE": "Patellasehne (BTB)",
                        ],
                    ],
                ],
                [
                    "id": "athlete_level",
                    "label": "Athlete Level",
                    "labelDE": "Sportler-Level",
                    "type": "radio",
                    "required": true,
                    "options": [
                        [
                            "value": "COMPETITIVE",
                            "label": "Competitive",
                            "labelDE": "Leistungssportler",
                        ],
                        [
                            "value": "RECREATIONAL",
                            "label": "Recreational",
                            "labelDE": "Freizeitsportler",
                        ],
                    ],
                ],
                [
                    "id": "knee_side",
                    "label": "Knee Side",
                    "labelDE": "Knieseite",
                    "type": "radio",
                    "required": true,
                    "options": [
                        [
                            "value": "LEFT",
                            "label": "Left",
                            "labelDE": "Links",
                        ],
                        [
                            "value": "RIGHT",
                            "label": "Right",
                            "labelDE": "Rechts",
                        ],
                    ],
                ],
                [
                    "id": "concomitant_injuries",
                    "label": "Concomitant Injuries",
                    "labelDE": "Begleitverletzungen",
                    "type": "checkbox",
                    "required": false,
                    "options": [
                        [
                            "value": "NONE",
                            "label": "None",
                            "labelDE": "Keine",
                        ],
                        [
                            "value": "MENISCAL_REPAIR",
                            "label": "Meniscal Repair",
                            "labelDE": "Meniskusnaht",
                        ],
                    ],
                ],
                [
                    "id": "sport",
                    "label": "Sport",
                    "labelDE": "Sportart",
                    "type": "text",
                    "required": false,
                    "placeholder": "z.B. Fußball",
                ],
            ] as [[String: Any]],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclScreeningResultJSON() -> Data {
        let json: [String: Any] = [
            "screening": [
                "id": "acl-screening-1",
                "surgeryDate": "2025-09-01",
                "graftType": "HAMSTRING",
                "athleteLevel": "RECREATIONAL",
                "concomitantInjuries": ["NONE"],
                "sport": "Fußball",
                "kneeSide": "LEFT",
                "initialMilestone": 0,
                "currentMilestone": 1,
                "createdAt": "2025-09-01T10:00:00.000Z",
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclDischargeProgressJSON() -> Data {
        let json: [String: Any] = [
            "athleteLevel": "RECREATIONAL",
            "criteria": [
                [
                    "id": "dc-1",
                    "category": "strength",
                    "test": "Quad LSI",
                    "field": "quadLsi",
                    "threshold": 90.0,
                    "unit": "%",
                    "met": true,
                    "currentValue": "92.0",
                    "operator": ">=",
                ],
                [
                    "id": "dc-2",
                    "category": "functional",
                    "test": "Extension Deficit",
                    "field": "extensionDeficitDeg",
                    "threshold": 5.0,
                    "unit": "°",
                    "met": false,
                    "currentValue": "8.0",
                    "operator": "<=",
                ],
            ] as [[String: Any]],
            "overallPercent": 50,
            "metCount": 1,
            "totalCount": 2,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aclMicroModuleJSON() -> Data {
        let json: [String: Any] = [
            "modules": [
                [
                    "key": "acl_intro",
                    "title": "Einführung ACL Reha",
                    "bodyMarkdown": "## ACL Rehabilitation\nWichtige Informationen...",
                    "takeHome": "Geduld ist wichtig",
                    "taskType": "read",
                    "targetCondition": "ACL_RECONSTRUCTION",
                    "targetMilestone": [0, 1],
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - ACL Daily Tip

    static func aclDailyTipJSON() -> Data {
        let json: [String: Any] = [
            "tip": "Kühlen Sie Ihr Knie nach dem Training für 15-20 Minuten.",
            "stream": "rom",
            "streamLabel": "ROM Wiederherstellung",
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - Streak

    static func streakResponseJSON() -> Data {
        let json: [String: Any] = [
            "currentStreak": 5,
            "longestStreak": 12,
            "freezeTokens": 2,
            "lastTrainingDate": "2025-10-15",
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - ACL Daily KPI with Donor Site Pain

    static func aclDailyKpiWithDonorSiteJSON() -> Data {
        let json: [String: Any] = [
            "kpi": [
                "id": "daily-kpi-3",
                "date": "2025-10-16",
                "painNrs": 3,
                "kneeFlexionDeg": 120,
                "extensionDeficitDeg": 2,
                "swellingGrade": 0,
                "quadsLag": false,
                "donorSitePainNrs": 5,
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - ACL Lab Assessment

    static func aclLabAssessmentListJSON() -> Data {
        let json: [String: Any] = [
            "assessments": [
                [
                    "id": "lab-1",
                    "assessmentDate": "2025-10-20",
                    "milestone": 3,
                    "quadLsi": 78.0,
                    "hamLsi": 82.0,
                    "singleLegSquatLsi": 75.0,
                ]
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - AEM Screening

    static func aemScreeningConfigResponseData() -> Data {
        let json: [String: Any] = [
            "version": "1.0",
            "items": [
                ["id": "aem-1", "text_de": "Frage 1", "text_en": "Question 1", "subscale": "fearAvoidance", "reverse": false],
                ["id": "aem-2", "text_de": "Frage 2", "text_en": "Question 2", "subscale": "distressEndurance", "reverse": false],
                ["id": "aem-3", "text_de": "Frage 3", "text_en": "Question 3", "subscale": "eustressEndurance", "reverse": true],
            ],
            "likert_scale": ["min": 0, "max": 6],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func aemScreeningResultResponseData() -> Data {
        let json: [String: Any] = [
            "screening": [
                "id": "aem-result-1",
                "subscale_scores": [
                    "fear_avoidance": 4.5,
                    "distress_endurance": 2.0,
                    "eustress_endurance": 1.5,
                ],
                "subtype": "FAR",
                "completed_at": "2025-01-15T10:00:00.000Z",
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    // MARK: - Neck Screening

    static func neckScreeningConfigResponseData() -> Data {
        let json: [String: Any] = [
            "version": "1.0",
            "part_a": [
                "title": "Part A",
                "description": "Radiculopathy classification",
                "items": [
                    ["id": "neck-a1", "text_de": "Haben Sie ausstrahlende Schmerzen?", "type": "yesno"],
                    ["id": "neck-a2", "text_de": "Taubheitsgefühl?", "type": "yesno"],
                ],
            ],
            "part_b": [
                "title": "Part B",
                "description": "NDI Assessment",
                "items": [
                    ["id": "neck-b1", "text_de": "Schmerzintensität", "type": "likert",
                     "options": [["value": 0, "label_de": "Keine"], ["value": 1, "label_de": "Leicht"]]],
                    ["id": "neck-b2", "text_de": "Körperpflege", "type": "likert",
                     "options": [["value": 0, "label_de": "Keine Probleme"], ["value": 1, "label_de": "Leichte Probleme"]]],
                    ["id": "neck-b3", "text_de": "Heben", "type": "likert",
                     "options": [["value": 0, "label_de": "Keine Probleme"], ["value": 1, "label_de": "Leichte Probleme"]]],
                ],
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    static func neckScreeningResultResponseData() -> Data {
        let json: [String: Any] = [
            "screening": [
                "id": "neck-result-1",
                "subtype": "standard",
                "subtype_score": 2,
                "ndi_score": 14,
                "ndi_category": "LEICHT",
                "created_at": "2025-01-15T10:00:00.000Z",
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
