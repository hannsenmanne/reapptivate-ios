import XCTest
@testable import Reapptivate

final class CodableRoundTripTests: XCTestCase {

    // MARK: - ProgressEntry

    func testProgressEntrySnakeCaseDecode() throws {
        let json = """
        {
            "id": "e-1",
            "user_id": "u-1",
            "exercise_id": "ex-1",
            "completed_at": "2025-06-01T10:00:00.000Z",
            "sets_completed": 3,
            "reps_completed": 10,
            "pain_level": 2,
            "notes": null,
            "symptom_response": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let entry = try decoder.decode(ProgressEntry.self, from: json)

        XCTAssertEqual(entry.id, "e-1")
        XCTAssertEqual(entry.exerciseId, "ex-1")
        XCTAssertEqual(entry.setsCompleted, 3)
        XCTAssertEqual(entry.repsCompleted, 10)
        XCTAssertEqual(entry.painLevel, 2)
    }

    // MARK: - ExerciseWithPhase

    func testExerciseWithPhaseNestedFormatDecode() throws {
        let json = """
        {
            "exercise": {
                "id": "ex-1",
                "name": "Heel Raise",
                "type": "ISOMETRIC",
                "description": "Test",
                "sets": 3,
                "reps": 10,
                "hold_time": null,
                "rest_between_sets": 60,
                "tempo": "3-0-3-0",
                "video_url": null,
                "gif_url": null,
                "intensity": "moderate",
                "cognitive_cues": null,
                "aem_subtype_specific": null,
                "visual_indicator": null
            },
            "phase": 2,
            "phase_title": "HSR Phase",
            "weeks_range": "5-8",
            "phase_goal": "Build strength"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let ewp = try decoder.decode(ExerciseWithPhase.self, from: json)

        XCTAssertEqual(ewp.exercise.id, "ex-1")
        XCTAssertEqual(ewp.exercise.name, "Heel Raise")
        XCTAssertEqual(ewp.phase, 2)
        XCTAssertEqual(ewp.phaseTitle, "HSR Phase")
    }

    func testExerciseWithPhaseFlatFormatDecode() throws {
        let json = """
        {
            "id": "ex-2",
            "name": "Squat",
            "type": "ECCENTRIC",
            "description": "Test flat",
            "sets": 4,
            "reps": 8,
            "hold_time": null,
            "rest_between_sets": 90,
            "tempo": null,
            "video_url": null,
            "gif_url": null,
            "intensity": "high",
            "cognitive_cues": null,
            "aem_subtype_specific": null,
            "visual_indicator": null,
            "phase": 1,
            "phase_title": "Eccentric Phase",
            "weeks_range": "1-4",
            "phase_goal": "Pain reduction"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let ewp = try decoder.decode(ExerciseWithPhase.self, from: json)

        XCTAssertEqual(ewp.exercise.id, "ex-2")
        XCTAssertEqual(ewp.exercise.name, "Squat")
        XCTAssertEqual(ewp.exercise.sets, 4)
        XCTAssertEqual(ewp.phase, 1)
    }

    // MARK: - AdaptationResult.phaseChanged

    func testAdaptationResultPhaseChangedProgress() {
        let result = TestFixtures.adaptationResult(decision: .progress, currentPhase: 2, previousPhase: 1)
        XCTAssertTrue(result.phaseChanged)
    }

    func testAdaptationResultPhaseChangedHold() {
        let result = TestFixtures.adaptationResult(decision: .hold)
        XCTAssertFalse(result.phaseChanged)
    }

    func testAdaptationResultPhaseChangedRegress() {
        let result = TestFixtures.adaptationResult(decision: .regress, currentPhase: 1, previousPhase: 2)
        XCTAssertTrue(result.phaseChanged)
    }

    func testAdaptationResultPhaseChangedInitial() {
        let result = TestFixtures.adaptationResult(decision: .initial)
        XCTAssertFalse(result.phaseChanged)
    }

    // MARK: - API Response Wrappers

    func testUserResponseDecode() throws {
        let json = """
        {
            "user": {
                "id": "u-1",
                "email": "test@test.com",
                "name": "Test",
                "tendinopathyType": "ACHILLES",
                "protocolId": "p-1",
                "startDate": "2025-01-01T00:00:00.000Z",
                "createdAt": "2025-01-01T00:00:00.000Z"
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(UserResponse.self, from: json)
        XCTAssertEqual(response.user.id, "u-1")
        XCTAssertEqual(response.user.tendinopathyType, .achilles)
    }

    func testPhaseStatusResponseDecode() throws {
        let data = TestFixtures.phaseStatusResponseJSON()
        let response = try JSONDecoder().decode(PhaseStatusResponse.self, from: data)
        XCTAssertEqual(response.phaseStatus.currentPhase, 1)
        XCTAssertEqual(response.phaseStatus.lastDecision, .initial)
    }
}
