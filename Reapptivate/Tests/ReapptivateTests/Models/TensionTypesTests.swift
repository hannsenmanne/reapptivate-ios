import XCTest
@testable import Reapptivate

final class TensionTypesTests: XCTestCase {

    // MARK: - TsiScreeningConfig

    func testTsiScreeningConfigCodable() throws {
        let json = """
        {
            "version": "1.0",
            "items": [
                {
                    "id": "tsi-1",
                    "textDe": "Frage 1",
                    "options": [
                        { "value": 0, "labelDe": "Gar nicht" },
                        { "value": 1, "labelDe": "Etwas" }
                    ]
                },
                {
                    "id": "tsi-2",
                    "textDe": "Frage 2",
                    "options": null
                }
            ]
        }
        """.data(using: .utf8)!

        let config = try JSONDecoder().decode(TsiScreeningConfig.self, from: json)

        XCTAssertEqual(config.version, "1.0")
        XCTAssertEqual(config.items.count, 2)
        XCTAssertEqual(config.items[0].id, "tsi-1")
        XCTAssertEqual(config.items[0].textDe, "Frage 1")
        XCTAssertEqual(config.items[0].options?.count, 2)
        XCTAssertEqual(config.items[0].options?[0].value, 0)
        XCTAssertEqual(config.items[0].options?[0].labelDe, "Gar nicht")
        XCTAssertNil(config.items[1].options)
    }

    func testTsiScreeningConfigRoundTrip() throws {
        let config = TestFixtures.makeTsiScreeningConfig()
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(TsiScreeningConfig.self, from: data)

        XCTAssertEqual(decoded.version, config.version)
        XCTAssertEqual(decoded.items.count, config.items.count)
        XCTAssertEqual(decoded.items[0].id, config.items[0].id)
    }

    // MARK: - TsiScreeningSubmission

    func testTsiScreeningSubmissionCodable() throws {
        let submission = TsiScreeningSubmission(responses: [
            "tsi-1": 3,
            "tsi-2": 1,
            "tsi-3": 4,
        ])

        let data = try JSONEncoder().encode(submission)
        let decoded = try JSONDecoder().decode(TsiScreeningSubmission.self, from: data)

        XCTAssertEqual(decoded.responses.count, 3)
        XCTAssertEqual(decoded.responses["tsi-1"], 3)
        XCTAssertEqual(decoded.responses["tsi-2"], 1)
        XCTAssertEqual(decoded.responses["tsi-3"], 4)
    }

    // MARK: - TsiScreeningResult

    func testTsiScreeningResultCodable() throws {
        let json = """
        {
            "id": "result-1",
            "tsiScore": 22,
            "tsiCategory": "MITTEL",
            "createdAt": "2025-06-01T10:00:00.000Z"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TsiScreeningResult.self, from: json)

        XCTAssertEqual(result.id, "result-1")
        XCTAssertEqual(result.tsiScore, 22)
        XCTAssertEqual(result.tsiCategory, "MITTEL")
        XCTAssertEqual(result.createdAt, "2025-06-01T10:00:00.000Z")
    }

    func testTsiScreeningResultWithNilFields() throws {
        let json = """
        {
            "tsiScore": 10,
            "tsiCategory": "LEICHT"
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(TsiScreeningResult.self, from: json)

        XCTAssertNil(result.id)
        XCTAssertEqual(result.tsiScore, 10)
        XCTAssertEqual(result.tsiCategory, "LEICHT")
        XCTAssertNil(result.createdAt)
    }

    // MARK: - TsiFocusArea

    func testTsiFocusAreaPercentageCalculation() {
        let area = TestFixtures.makeTsiFocusArea()
        // score=3, maxScore=5 => 60%
        XCTAssertEqual(area.percentage, 60.0, accuracy: 0.01)
    }

    func testTsiFocusAreaPercentageZeroMaxScore() {
        let area = TsiFocusArea(
            domainId: "test",
            domainLabel: "Test",
            score: 0,
            maxScore: 0,
            dailyTips: nil
        )
        XCTAssertEqual(area.percentage, 0.0)
    }

    func testTsiFocusAreaIdentifiable() {
        let area = TestFixtures.makeTsiFocusArea()
        XCTAssertEqual(area.id, area.domainId)
        XCTAssertEqual(area.id, "shoulder_tension")
    }

    func testTsiFocusAreaCodable() throws {
        let json = """
        {
            "domainId": "neck_stiffness",
            "domainLabel": "Nackensteifheit",
            "score": 4,
            "maxScore": 5,
            "dailyTips": ["Kopf langsam drehen"]
        }
        """.data(using: .utf8)!

        let area = try JSONDecoder().decode(TsiFocusArea.self, from: json)

        XCTAssertEqual(area.domainId, "neck_stiffness")
        XCTAssertEqual(area.domainLabel, "Nackensteifheit")
        XCTAssertEqual(area.score, 4)
        XCTAssertEqual(area.maxScore, 5)
        XCTAssertEqual(area.dailyTips?.count, 1)
        XCTAssertEqual(area.percentage, 80.0, accuracy: 0.01)
    }

    // MARK: - TsiHistoryEntry

    func testTsiHistoryEntryCreatedAtDateParsing() {
        let entry = TestFixtures.makeTsiHistoryEntry()
        XCTAssertNotNil(entry.createdAtDate)

        let calendar = Calendar.current
        let components = calendar.dateComponents(in: TimeZone(identifier: "UTC")!, from: entry.createdAtDate!)
        XCTAssertEqual(components.year, 2025)
        XCTAssertEqual(components.month, 6)
        XCTAssertEqual(components.day, 1)
    }

    func testTsiHistoryEntryCodable() throws {
        let json = """
        {
            "id": "hist-1",
            "tsiScore": 25,
            "tsiCategory": "MITTEL",
            "severityGrade": "MITTEL",
            "createdAt": "2025-06-15T14:30:00.000Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        let entry = try decoder.decode(TsiHistoryEntry.self, from: json)

        XCTAssertEqual(entry.id, "hist-1")
        XCTAssertEqual(entry.tsiScore, 25)
        XCTAssertEqual(entry.tsiCategory, "MITTEL")
        XCTAssertEqual(entry.severityGrade, .MITTEL)
        XCTAssertNotNil(entry.createdAtDate)
    }

    func testTsiHistoryEntryWithOptionalFields() throws {
        let json = """
        {
            "id": "hist-2",
            "tsiScore": 10,
            "createdAt": "2025-07-01T08:00:00Z"
        }
        """.data(using: .utf8)!

        let entry = try JSONDecoder().decode(TsiHistoryEntry.self, from: json)

        XCTAssertEqual(entry.id, "hist-2")
        XCTAssertEqual(entry.tsiScore, 10)
        XCTAssertNil(entry.tsiCategory)
        XCTAssertNil(entry.severityGrade)
        XCTAssertNotNil(entry.createdAtDate)
    }

    // MARK: - API Response Wrappers

    func testTsiScreeningResponseDecode() throws {
        let data = TestFixtures.tsiScreeningResultResponseData(score: 22)
        let response = try JSONDecoder().decode(TsiScreeningResponse.self, from: data)

        XCTAssertEqual(response.screening.tsiScore, 22)
        XCTAssertEqual(response.screening.tsiCategory, "MITTEL")
    }

    func testTsiHistoryResponseDecode() throws {
        let data = TestFixtures.tsiHistoryResponseData()
        let response = try JSONDecoder().decode(TsiHistoryResponse.self, from: data)

        XCTAssertEqual(response.history.count, 1)
        XCTAssertEqual(response.history[0].tsiScore, 18)
    }

    func testTsiFocusAreasResponseDecode() throws {
        let data = TestFixtures.tsiFocusAreasResponseData()
        let response = try JSONDecoder().decode(TsiFocusAreasResponse.self, from: data)

        XCTAssertEqual(response.focusAreas.count, 1)
        XCTAssertEqual(response.focusAreas[0].domainId, "shoulder_tension")
        XCTAssertEqual(response.focusAreas[0].score, 3)
    }
}
