import XCTest
@testable import Reapptivate

final class WorkTimerTypesTests: XCTestCase {

    // MARK: - WorkTimerSettings Decoding

    func testWorkTimerSettingsDecodeFromSnakeCase() throws {
        let json = """
        {
            "start_time": "08:30",
            "end_time": "17:00",
            "break_interval_minutes": 45,
            "break_duration_minutes": 3,
            "is_enabled": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let settings = try decoder.decode(WorkTimerSettings.self, from: json)

        XCTAssertEqual(settings.startTime, "08:30")
        XCTAssertEqual(settings.endTime, "17:00")
        XCTAssertEqual(settings.breakIntervalMinutes, 45)
        XCTAssertEqual(settings.breakDurationMinutes, 3)
        XCTAssertTrue(settings.isEnabled)
    }

    func testWorkTimerSettingsDecodeCamelCase() throws {
        let json = """
        {
            "startTime": "09:00",
            "endTime": "18:00",
            "breakIntervalMinutes": 60,
            "breakDurationMinutes": 5,
            "isEnabled": false
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(WorkTimerSettings.self, from: json)

        XCTAssertEqual(settings.startTime, "09:00")
        XCTAssertEqual(settings.endTime, "18:00")
        XCTAssertEqual(settings.breakIntervalMinutes, 60)
        XCTAssertEqual(settings.breakDurationMinutes, 5)
        XCTAssertFalse(settings.isEnabled)
    }

    // MARK: - WorkTimerBreakExercise Decoding

    func testWorkTimerBreakExerciseDecodeFromSnakeCase() throws {
        let json = """
        {
            "id": "wt_lbp_pelvic_tilt",
            "name": "Beckenkippung im Stehen",
            "description": "Stehen Sie auf.",
            "duration_seconds": 45,
            "target_conditions": ["LBP_NONSPECIFIC"],
            "min_phase": 1,
            "category": "mobility"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let exercise = try decoder.decode(WorkTimerBreakExercise.self, from: json)

        XCTAssertEqual(exercise.id, "wt_lbp_pelvic_tilt")
        XCTAssertEqual(exercise.name, "Beckenkippung im Stehen")
        XCTAssertEqual(exercise.durationSeconds, 45)
        XCTAssertEqual(exercise.targetConditions, ["LBP_NONSPECIFIC"])
        XCTAssertEqual(exercise.minPhase, 1)
        XCTAssertEqual(exercise.category, "mobility")
    }

    // MARK: - WorkTimerDaySummary Decoding

    func testWorkTimerDaySummaryDecodeFromSnakeCase() throws {
        let json = """
        {
            "date": "2026-02-18",
            "total_work_minutes": 480,
            "breaks_offered": 8,
            "breaks_completed": 6,
            "breaks_skipped": 2,
            "adherence_percent": 75.0
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let summary = try decoder.decode(WorkTimerDaySummary.self, from: json)

        XCTAssertEqual(summary.date, "2026-02-18")
        XCTAssertEqual(summary.totalWorkMinutes, 480)
        XCTAssertEqual(summary.breaksOffered, 8)
        XCTAssertEqual(summary.breaksCompleted, 6)
        XCTAssertEqual(summary.breaksSkipped, 2)
        XCTAssertEqual(summary.adherencePercent, 75.0)
    }

    // MARK: - WorkTimerBreakLog Encoding

    func testWorkTimerBreakLogEncodeToSnakeCase() throws {
        let log = WorkTimerBreakLog(
            date: "2026-03-08",
            breakNumber: 3,
            completed: true,
            skipped: false,
            exercisesShown: ["wt_lbp_pelvic_tilt", "wt_lbp_cat_cow"]
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(log)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["date"] as? String, "2026-03-08")
        XCTAssertEqual(json?["breakNumber"] as? Int, 3)
        XCTAssertEqual(json?["completed"] as? Bool, true)
        XCTAssertEqual(json?["skipped"] as? Bool, false)
        XCTAssertEqual(json?["exercisesShown"] as? [String], ["wt_lbp_pelvic_tilt", "wt_lbp_cat_cow"])
    }

    // MARK: - API Response Wrappers

    func testWorkTimerSettingsResponseDecode() throws {
        let json = """
        {
            "settings": {
                "startTime": "08:00",
                "endTime": "17:00",
                "breakIntervalMinutes": 60,
                "breakDurationMinutes": 3,
                "isEnabled": true
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WorkTimerSettingsResponse.self, from: json)
        XCTAssertEqual(response.settings.startTime, "08:00")
        XCTAssertEqual(response.settings.breakIntervalMinutes, 60)
    }

    func testWorkTimerExercisesResponseDecode() throws {
        let json = """
        {
            "exercises": [
                {
                    "id": "wt_1",
                    "name": "Test",
                    "description": "Desc",
                    "durationSeconds": 30,
                    "targetConditions": ["LBP_NONSPECIFIC"],
                    "minPhase": 1,
                    "category": "stretch"
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WorkTimerExercisesResponse.self, from: json)
        XCTAssertEqual(response.exercises.count, 1)
        XCTAssertEqual(response.exercises[0].id, "wt_1")
    }

    func testWorkTimerSummaryResponseDecode() throws {
        let json = """
        {
            "summary": {
                "date": "2026-02-18",
                "totalWorkMinutes": 360,
                "breaksOffered": 6,
                "breaksCompleted": 5,
                "breaksSkipped": 1,
                "adherencePercent": 83.3
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WorkTimerSummaryResponse.self, from: json)
        XCTAssertEqual(response.summary.breaksCompleted, 5)
        XCTAssertEqual(response.summary.adherencePercent, 83.3, accuracy: 0.1)
    }

    func testWorkTimerHistoryResponseDecode() throws {
        let json = """
        {
            "history": [
                {
                    "date": "2026-02-17",
                    "totalWorkMinutes": 480,
                    "breaksOffered": 8,
                    "breaksCompleted": 7,
                    "breaksSkipped": 1,
                    "adherencePercent": 87.5
                },
                {
                    "date": "2026-02-18",
                    "totalWorkMinutes": 300,
                    "breaksOffered": 5,
                    "breaksCompleted": 5,
                    "breaksSkipped": 0,
                    "adherencePercent": 100.0
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WorkTimerHistoryResponse.self, from: json)
        XCTAssertEqual(response.history.count, 2)
        XCTAssertEqual(response.history[1].adherencePercent, 100.0, accuracy: 0.1)
    }
}
