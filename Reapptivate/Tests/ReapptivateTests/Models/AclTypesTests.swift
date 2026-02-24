import XCTest
@testable import Reapptivate

final class AclTypesTests: XCTestCase {

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    private let encoder = JSONEncoder()

    // MARK: - AclAthleteLevel

    func testAclAthleteLevelRawValues() {
        XCTAssertEqual(AclAthleteLevel.competitive.rawValue, "COMPETITIVE")
        XCTAssertEqual(AclAthleteLevel.recreational.rawValue, "RECREATIONAL")
    }

    func testAclAthleteLevelDisplayNames() {
        XCTAssertEqual(AclAthleteLevel.competitive.displayName, "Leistungssportler")
        XCTAssertEqual(AclAthleteLevel.recreational.displayName, "Freizeitsportler")
    }

    func testAclAthleteLevelCodableRoundTrip() throws {
        for level in [AclAthleteLevel.competitive, .recreational] {
            let data = try encoder.encode(level)
            let decoded = try decoder.decode(AclAthleteLevel.self, from: data)
            XCTAssertEqual(decoded, level)
        }
    }

    // MARK: - AclGraftType

    func testAclGraftTypeRawValues() {
        XCTAssertEqual(AclGraftType.hamstring.rawValue, "HAMSTRING")
        XCTAssertEqual(AclGraftType.patellarTendon.rawValue, "PATELLAR_TENDON")
        XCTAssertEqual(AclGraftType.quadriceps.rawValue, "QUADRICEPS")
    }

    func testAclGraftTypeDisplayNames() {
        XCTAssertEqual(AclGraftType.hamstring.displayName, "Hamstring (Semitendinosus)")
        XCTAssertEqual(AclGraftType.patellarTendon.displayName, "Patellasehne (BTB)")
        XCTAssertEqual(AclGraftType.quadriceps.displayName, "Quadrizepssehne")
    }

    func testAclGraftTypeCodableRoundTrip() throws {
        for graft in [AclGraftType.hamstring, .patellarTendon, .quadriceps] {
            let data = try encoder.encode(graft)
            let decoded = try decoder.decode(AclGraftType.self, from: data)
            XCTAssertEqual(decoded, graft)
        }
    }

    // MARK: - AclConcomitantInjury

    func testAclConcomitantInjuryRawValues() {
        XCTAssertEqual(AclConcomitantInjury.none.rawValue, "NONE")
        XCTAssertEqual(AclConcomitantInjury.meniscalRepair.rawValue, "MENISCAL_REPAIR")
        XCTAssertEqual(AclConcomitantInjury.chondralRepair.rawValue, "CHONDRAL_REPAIR")
        XCTAssertEqual(AclConcomitantInjury.lateralExtraArticularTenodesis.rawValue, "LATERAL_EXTRA_ARTICULAR_TENODESIS")
        XCTAssertEqual(AclConcomitantInjury.posterolateralCorner.rawValue, "POSTEROLATERAL_CORNER")
    }

    func testAclConcomitantInjuryDisplayNames() {
        XCTAssertEqual(AclConcomitantInjury.none.displayName, "Keine")
        XCTAssertEqual(AclConcomitantInjury.meniscalRepair.displayName, "Meniskusnaht")
    }

    // MARK: - AclKneeSide

    func testAclKneeSideRawValues() {
        XCTAssertEqual(AclKneeSide.left.rawValue, "LEFT")
        XCTAssertEqual(AclKneeSide.right.rawValue, "RIGHT")
    }

    func testAclKneeSideDisplayNames() {
        XCTAssertEqual(AclKneeSide.left.displayName, "Links")
        XCTAssertEqual(AclKneeSide.right.displayName, "Rechts")
    }

    // MARK: - AclScreeningConfig Decoding

    func testAclScreeningConfigDecoding() throws {
        let data = TestFixtures.aclScreeningConfigJSON()
        let config = try decoder.decode(AclScreeningConfig.self, from: data)

        XCTAssertEqual(config.version, "1.0")
        XCTAssertEqual(config.title, "ACL Screening")
        XCTAssertEqual(config.titleDE, "ACL Screening")
        XCTAssertEqual(config.steps.count, 6)

        let dateStep = config.steps[0]
        XCTAssertEqual(dateStep.id, "surgery_date")
        XCTAssertEqual(dateStep.type, "date")
        XCTAssertEqual(dateStep.required, true)

        let graftStep = config.steps[1]
        XCTAssertEqual(graftStep.id, "graft_type")
        XCTAssertEqual(graftStep.type, "radio")
        XCTAssertEqual(graftStep.options?.count, 2)
        XCTAssertEqual(graftStep.options?.first?.value, "HAMSTRING")
    }

    // MARK: - AclMilestoneStatus Decoding

    func testAclMilestoneStatusDecoding() throws {
        let data = TestFixtures.aclMilestoneStatusJSON()
        let status = try decoder.decode(AclMilestoneStatus.self, from: data)

        XCTAssertEqual(status.currentMilestone, 2)
        XCTAssertEqual(status.weeksPostSurgery, 8)
        XCTAssertFalse(status.isPreOp)
        XCTAssertEqual(status.athleteLevel, "RECREATIONAL")
        XCTAssertEqual(status.graftType, "HAMSTRING")
        XCTAssertEqual(status.surgeryDate, "2025-09-01")
        XCTAssertEqual(status.concomitantInjuries, ["NONE"])
        XCTAssertEqual(status.isReadyForLab, false)
    }

    func testAclMilestoneCriterionOperatorField() throws {
        let data = TestFixtures.aclMilestoneStatusJSON()
        let status = try decoder.decode(AclMilestoneStatus.self, from: data)

        let criterion = try XCTUnwrap(status.nextCriteria?.first)
        XCTAssertEqual(criterion.id, "crit-1")
        XCTAssertEqual(criterion.`operator`, ">=")
        XCTAssertEqual(criterion.threshold, 70.0)
        XCTAssertEqual(criterion.met, false)
        XCTAssertEqual(criterion.currentValue, 55.0)
    }

    // MARK: - AclDailyKpi Encoding/Decoding

    func testAclDailyKpiDecoding() throws {
        let json: [String: Any] = [
            "id": "daily-kpi-1",
            "date": "2025-10-15",
            "painNrs": 4,
            "painLocation": "anterior",
            "painActivity": "walking",
            "kneeFlexionDeg": 110,
            "extensionDeficitDeg": 5,
            "swellingGrade": 1,
            "quadsLag": false,
            "notes": "Good day",
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let kpi = try decoder.decode(AclDailyKpi.self, from: data)

        XCTAssertEqual(kpi.id, "daily-kpi-1")
        XCTAssertEqual(kpi.date, "2025-10-15")
        XCTAssertEqual(kpi.painNrs, 4)
        XCTAssertEqual(kpi.painLocation, "anterior")
        XCTAssertEqual(kpi.painActivity, "walking")
        XCTAssertEqual(kpi.kneeFlexionDeg, 110)
        XCTAssertEqual(kpi.extensionDeficitDeg, 5)
        XCTAssertEqual(kpi.swellingGrade, 1)
        XCTAssertEqual(kpi.quadsLag, false)
        XCTAssertEqual(kpi.notes, "Good day")
    }

    func testAclDailyKpiRequestEncoding() throws {
        let request = AclDailyKpiRequest(
            date: nil,
            painNrs: 6,
            painLocation: "lateral",
            painActivity: nil,
            kneeFlexionDeg: 100,
            extensionDeficitDeg: 10,
            swellingGrade: 2,
            quadsLag: true,
            notes: nil
        )
        let data = try encoder.encode(request)
        let decoded = try decoder.decode(AclDailyKpiRequest.self, from: data)

        XCTAssertEqual(decoded.painNrs, 6)
        XCTAssertEqual(decoded.painLocation, "lateral")
        XCTAssertNil(decoded.painActivity)
        XCTAssertEqual(decoded.kneeFlexionDeg, 100)
        XCTAssertEqual(decoded.extensionDeficitDeg, 10)
        XCTAssertEqual(decoded.swellingGrade, 2)
        XCTAssertEqual(decoded.quadsLag, true)
    }

    // MARK: - AclWeeklyKpi Encoding/Decoding

    func testAclWeeklyKpiDecoding() throws {
        let json: [String: Any] = [
            "id": "weekly-kpi-1",
            "weekDate": "2025-10-13",
            "ikdcScore": 55,
            "tampaScore": 30,
            "thighCirc5cm": 42.5,
            "thighCirc10cm": 48.0,
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let kpi = try decoder.decode(AclWeeklyKpi.self, from: data)

        XCTAssertEqual(kpi.id, "weekly-kpi-1")
        XCTAssertEqual(kpi.weekDate, "2025-10-13")
        XCTAssertEqual(kpi.ikdcScore, 55)
        XCTAssertEqual(kpi.tampaScore, 30)
        XCTAssertEqual(kpi.thighCirc5cm, 42.5)
        XCTAssertEqual(kpi.thighCirc10cm, 48.0)
    }

    func testAclWeeklyKpiRequestEncoding() throws {
        let request = AclWeeklyKpiRequest(
            weekDate: nil,
            ikdcScore: 60,
            tampaScore: 25,
            thighCirc5cm: 43.0,
            thighCirc10cm: nil
        )
        let data = try encoder.encode(request)
        let decoded = try decoder.decode(AclWeeklyKpiRequest.self, from: data)

        XCTAssertEqual(decoded.ikdcScore, 60)
        XCTAssertEqual(decoded.tampaScore, 25)
        XCTAssertEqual(decoded.thighCirc5cm, 43.0)
        XCTAssertNil(decoded.thighCirc10cm)
    }

    // MARK: - AclDischargeCriterion

    func testAclDischargeProgressDecoding() throws {
        let data = TestFixtures.aclDischargeProgressJSON()
        let progress = try decoder.decode(AclDischargeProgress.self, from: data)

        XCTAssertEqual(progress.athleteLevel, "RECREATIONAL")
        XCTAssertEqual(progress.criteria.count, 2)
        XCTAssertEqual(progress.overallPercent, 50)
        XCTAssertEqual(progress.metCount, 1)
        XCTAssertEqual(progress.totalCount, 2)

        let metCriterion = progress.criteria[0]
        XCTAssertEqual(metCriterion.`operator`, ">=")
        XCTAssertEqual(metCriterion.met, true)
        XCTAssertEqual(metCriterion.currentValue, 92.0)

        let unmetCriterion = progress.criteria[1]
        XCTAssertEqual(unmetCriterion.`operator`, "<=")
        XCTAssertEqual(unmetCriterion.met, false)
        XCTAssertEqual(unmetCriterion.currentValue, 8.0)
    }

    // MARK: - AclMicroModule

    func testAclMicroModuleDecodingWithCodingKeys() throws {
        let data = TestFixtures.aclMicroModuleJSON()
        let response = try decoder.decode(AclMicroModulesResponse.self, from: data)

        XCTAssertEqual(response.modules.count, 1)
        let module = response.modules[0]
        XCTAssertEqual(module.key, "acl_intro")
        XCTAssertEqual(module.title, "Einführung ACL Reha")
        // content maps from bodyMarkdown via CodingKeys
        XCTAssertTrue(module.content.contains("ACL Rehabilitation"))
        XCTAssertEqual(module.takeHome, "Geduld ist wichtig")
        XCTAssertEqual(module.taskType, "read")
        XCTAssertEqual(module.targetCondition, "ACL_RECONSTRUCTION")
        XCTAssertEqual(module.targetMilestone, [0, 1])
        XCTAssertEqual(module.id, "acl_intro")
    }

    // MARK: - AclStreamsResponse

    func testAclStreamsResponseDecoding() throws {
        let data = TestFixtures.aclStreamsResponseJSON()
        let response = try decoder.decode(AclStreamsResponse.self, from: data)

        XCTAssertEqual(response.currentMilestone, 2)
        XCTAssertEqual(response.weeksPostSurgery, 8)
        XCTAssertEqual(response.streams.count, 3)

        let unlockedStream = response.streams[0]
        XCTAssertEqual(unlockedStream.id, "stream-rom")
        XCTAssertEqual(unlockedStream.locked, false)
        XCTAssertEqual(unlockedStream.exerciseCount, 5)

        let lockedStream = response.streams[2]
        XCTAssertEqual(lockedStream.id, "stream-plyo")
        XCTAssertEqual(lockedStream.locked, true)
    }

    // MARK: - AclScreeningResult

    func testAclScreeningResultDecoding() throws {
        let data = TestFixtures.aclScreeningResultJSON()
        let response = try decoder.decode(AclScreeningResponse.self, from: data)
        let result = response.screening

        XCTAssertEqual(result.id, "acl-screening-1")
        XCTAssertEqual(result.surgeryDate, "2025-09-01")
        XCTAssertEqual(result.graftType, "HAMSTRING")
        XCTAssertEqual(result.athleteLevel, "RECREATIONAL")
        XCTAssertEqual(result.concomitantInjuries, ["NONE"])
        XCTAssertEqual(result.sport, "Fußball")
        XCTAssertEqual(result.kneeSide, "LEFT")
        XCTAssertEqual(result.initialMilestone, 0)
        XCTAssertEqual(result.currentMilestone, 1)
    }

    // MARK: - AclScreeningSubmission

    func testAclScreeningSubmissionEncoding() throws {
        let submission = AclScreeningSubmission(
            surgeryDate: "2025-09-01",
            graftType: "HAMSTRING",
            athleteLevel: "RECREATIONAL",
            concomitantInjuries: ["NONE"],
            sport: "Fußball",
            kneeSide: "LEFT"
        )
        let data = try encoder.encode(submission)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertEqual(json?["surgeryDate"] as? String, "2025-09-01")
        XCTAssertEqual(json?["graftType"] as? String, "HAMSTRING")
        XCTAssertEqual(json?["athleteLevel"] as? String, "RECREATIONAL")
        XCTAssertEqual(json?["kneeSide"] as? String, "LEFT")
        XCTAssertEqual(json?["sport"] as? String, "Fußball")
    }

    // MARK: - AclWeeklyKpiResponse

    func testAclWeeklyKpiResponseDecoding() throws {
        let data = TestFixtures.aclWeeklyKpiJSON()
        let response = try decoder.decode(AclWeeklyKpiResponse.self, from: data)

        XCTAssertEqual(response.kpi.id, "weekly-kpi-1")
        XCTAssertEqual(response.kpi.ikdcScore, 55)
        XCTAssertEqual(response.tampaAlert, false)
    }

    // MARK: - Response Wrapper Decoding

    func testAclDailyKpiSingleResponseDecoding() throws {
        let data = TestFixtures.aclDailyKpiJSON()
        let response = try decoder.decode(AclDailyKpiSingleResponse.self, from: data)

        XCTAssertEqual(response.kpi.id, "daily-kpi-1")
        XCTAssertEqual(response.kpi.painNrs, 4)
    }

    func testAclDailyKpiListResponseDecoding() throws {
        let data = TestFixtures.aclDailyKpiHistoryJSON()
        let response = try decoder.decode(AclDailyKpiListResponse.self, from: data)

        XCTAssertEqual(response.kpis?.count, 2)
        XCTAssertNil(response.entries)
    }

    func testAclWeeklyKpiListResponseDecoding() throws {
        let data = TestFixtures.aclWeeklyKpiHistoryJSON()
        let response = try decoder.decode(AclWeeklyKpiListResponse.self, from: data)

        XCTAssertEqual(response.kpis?.count, 2)
        XCTAssertNil(response.entries)
    }
}
