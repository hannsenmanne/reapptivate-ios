import XCTest
@testable import Reapptivate

final class DosageModifierTests: XCTestCase {

    // MARK: - Exercise.applying()

    func testApplyingSetsMultiplier() {
        let exercise = makeExercise(sets: 3, reps: 12, holdTime: nil)

        let modified = exercise.applying(setsMultiplier: 0.67, repsMultiplier: nil, holdTimeMultiplier: nil)

        // 3 * 0.67 = 2.01 → rounded to 2
        XCTAssertEqual(modified.sets, 2)
        XCTAssertEqual(modified.reps, 12) // unchanged
    }

    func testApplyingRepsMultiplier() {
        let exercise = makeExercise(sets: 3, reps: 10, holdTime: nil)

        let modified = exercise.applying(setsMultiplier: nil, repsMultiplier: 0.8, holdTimeMultiplier: nil)

        // 10 * 0.8 = 8
        XCTAssertEqual(modified.reps, 8)
        XCTAssertEqual(modified.sets, 3) // unchanged
    }

    func testApplyingHoldTimeMultiplier() {
        let exercise = makeExercise(sets: 3, reps: 1, holdTime: 30)

        let modified = exercise.applying(setsMultiplier: nil, repsMultiplier: nil, holdTimeMultiplier: 0.6)

        // 30 * 0.6 = 18
        XCTAssertEqual(modified.holdTime, 18)
    }

    func testApplyingNilHoldTimeIgnoresMultiplier() {
        let exercise = makeExercise(sets: 3, reps: 10, holdTime: nil)

        let modified = exercise.applying(setsMultiplier: nil, repsMultiplier: nil, holdTimeMultiplier: 0.6)

        XCTAssertNil(modified.holdTime)
    }

    func testApplyingEnforcesMinimumOfOne() {
        let exercise = makeExercise(sets: 1, reps: 1, holdTime: 1)

        // 1 * 0.1 = 0.1 → rounded to 0 → clamped to 1
        let modified = exercise.applying(setsMultiplier: 0.1, repsMultiplier: 0.1, holdTimeMultiplier: 0.1)

        XCTAssertEqual(modified.sets, 1)
        XCTAssertEqual(modified.reps, 1)
        XCTAssertEqual(modified.holdTime, 1)
    }

    func testApplyingAllMultipliers() {
        let exercise = makeExercise(sets: 4, reps: 15, holdTime: 20)

        let modified = exercise.applying(setsMultiplier: 0.67, repsMultiplier: 0.8, holdTimeMultiplier: 0.5)

        // 4 * 0.67 = 2.68 → 3
        XCTAssertEqual(modified.sets, 3)
        // 15 * 0.8 = 12
        XCTAssertEqual(modified.reps, 12)
        // 20 * 0.5 = 10
        XCTAssertEqual(modified.holdTime, 10)
    }

    func testApplyingNilMultipliersReturnsUnchanged() {
        let exercise = makeExercise(sets: 3, reps: 12, holdTime: 30)

        let modified = exercise.applying(setsMultiplier: nil, repsMultiplier: nil, holdTimeMultiplier: nil)

        XCTAssertEqual(modified.sets, 3)
        XCTAssertEqual(modified.reps, 12)
        XCTAssertEqual(modified.holdTime, 30)
    }

    // MARK: - ExerciseWithPhase.applyingDosageModifier()

    func testApplyingDosageModifierWithMatchingKey() {
        let exercise = makeExercise(sets: 3, reps: 12, holdTime: nil)
        let dosage: DosageModifier = [
            "SCHWER": DosageMultipliers(setsMultiplier: 0.67, repsMultiplier: 0.8, holdTimeMultiplier: nil)
        ]
        let ewp = ExerciseWithPhase(
            exercise: exercise, phase: 1, phaseTitle: "Phase 1",
            weeksRange: "1-4", phaseGoal: "Goal", dosageModifier: dosage
        )

        let modified = ewp.applyingDosageModifier(severityKey: "SCHWER")

        // 3 * 0.67 = 2.01 → 2
        XCTAssertEqual(modified.exercise.sets, 2)
        // 12 * 0.8 = 9.6 → 10
        XCTAssertEqual(modified.exercise.reps, 10)
    }

    func testApplyingDosageModifierWithNonMatchingKeyReturnsUnchanged() {
        let exercise = makeExercise(sets: 3, reps: 12, holdTime: nil)
        let dosage: DosageModifier = [
            "SCHWER": DosageMultipliers(setsMultiplier: 0.67, repsMultiplier: 0.8, holdTimeMultiplier: nil)
        ]
        let ewp = ExerciseWithPhase(
            exercise: exercise, phase: 1, phaseTitle: "Phase 1",
            weeksRange: "1-4", phaseGoal: "Goal", dosageModifier: dosage
        )

        let modified = ewp.applyingDosageModifier(severityKey: "LEICHT")

        XCTAssertEqual(modified.exercise.sets, 3)
        XCTAssertEqual(modified.exercise.reps, 12)
    }

    func testApplyingDosageModifierWithNilModifierReturnsUnchanged() {
        let exercise = makeExercise(sets: 3, reps: 12, holdTime: nil)
        let ewp = ExerciseWithPhase(
            exercise: exercise, phase: 1, phaseTitle: "Phase 1",
            weeksRange: "1-4", phaseGoal: "Goal", dosageModifier: nil
        )

        let modified = ewp.applyingDosageModifier(severityKey: "SCHWER")

        XCTAssertEqual(modified.exercise.sets, 3)
        XCTAssertEqual(modified.exercise.reps, 12)
    }

    // MARK: - FS SCHWER Specific (67% sets, 80% reps)

    func testFrozenShoulderSchwerDosage() {
        let exercise = makeExercise(sets: 3, reps: 10, holdTime: 30)
        let dosage: DosageModifier = [
            "SCHWER": DosageMultipliers(setsMultiplier: 0.67, repsMultiplier: 0.8, holdTimeMultiplier: nil)
        ]
        let ewp = ExerciseWithPhase(
            exercise: exercise, phase: 1, phaseTitle: "Phase 1",
            weeksRange: "1-4", phaseGoal: "Goal", dosageModifier: dosage
        )

        let modified = ewp.applyingDosageModifier(severityKey: "SCHWER")

        // 3 * 0.67 = 2.01 → 2
        XCTAssertEqual(modified.exercise.sets, 2)
        // 10 * 0.8 = 8
        XCTAssertEqual(modified.exercise.reps, 8)
        // holdTime unmodified (no multiplier)
        XCTAssertEqual(modified.exercise.holdTime, 30)
    }

    // MARK: - Helpers

    private func makeExercise(sets: Int, reps: Int, holdTime: Int?) -> Exercise {
        Exercise(
            id: "test-exercise",
            name: "Test Exercise",
            type: .isometric,
            description: "A test exercise",
            sets: sets,
            reps: reps,
            holdTime: holdTime,
            restBetweenSets: 60,
            tempo: nil,
            videoUrl: nil,
            gifUrl: nil,
            intensity: "moderate",
            cognitiveCues: nil,
            aemSubtypeSpecific: nil,
            visualIndicator: nil
        )
    }
}
