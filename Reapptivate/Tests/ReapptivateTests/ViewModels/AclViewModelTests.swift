import XCTest
@testable import Reapptivate

// MARK: - AclDailyKpiViewModelTests

@MainActor
final class AclDailyKpiViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: AclDailyKpiViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = AclDailyKpiViewModel(apiClient: apiClient)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil
    }

    // MARK: - Validation

    func testIsValidWithDefaultValues() {
        // Default values: painNrs=0, flexion=90, ext=0, swelling=0 — all in range
        XCTAssertTrue(viewModel.isValid)
    }

    func testIsValidFailsWhenPainNrsOutOfRange() {
        viewModel.painNrs = 11
        XCTAssertFalse(viewModel.isValid)

        viewModel.painNrs = -1
        XCTAssertFalse(viewModel.isValid)
    }

    func testIsValidFailsWhenFlexionOutOfRange() {
        viewModel.kneeFlexionDeg = 161
        XCTAssertFalse(viewModel.isValid)
    }

    func testIsValidFailsWhenExtensionDeficitOutOfRange() {
        viewModel.extensionDeficitDeg = 31
        XCTAssertFalse(viewModel.isValid)
    }

    func testIsValidFailsWhenSwellingOutOfRange() {
        viewModel.swellingGrade = 4
        XCTAssertFalse(viewModel.isValid)
    }

    func testIsValidAtBoundaries() {
        viewModel.painNrs = 10
        viewModel.kneeFlexionDeg = 160
        viewModel.extensionDeficitDeg = 30
        viewModel.swellingGrade = 3
        XCTAssertTrue(viewModel.isValid)

        viewModel.painNrs = 0
        viewModel.kneeFlexionDeg = 0
        viewModel.extensionDeficitDeg = 0
        viewModel.swellingGrade = 0
        XCTAssertTrue(viewModel.isValid)
    }

    // MARK: - Submit

    func testSubmitSendsCorrectEndpoint() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            XCTAssertTrue(url.contains("acl/daily-kpi"), "Expected acl/daily-kpi endpoint, got \(url)")
            XCTAssertEqual(request.httpMethod, "POST")
            return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclDailyKpiJSON())
        }

        viewModel.painNrs = 4
        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.didSubmit)
        XCTAssertFalse(viewModel.isSubmitting)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSubmitWithCustomValuesSucceeds() async {
        MockURLProtocol.requestHandler = { request in
            XCTAssertEqual(request.httpMethod, "POST")
            let url = request.url?.absoluteString ?? ""
            XCTAssertTrue(url.contains("acl/daily-kpi"))
            return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclDailyKpiJSON())
        }

        viewModel.painNrs = 7
        viewModel.kneeFlexionDeg = 120
        viewModel.extensionDeficitDeg = 3
        viewModel.swellingGrade = 1
        viewModel.quadsLag = true
        viewModel.painLocation = "anterior"
        viewModel.notes = "Test notes"

        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.didSubmit)
    }

    func testSubmitReturnsFalseWhenInvalid() async {
        viewModel.painNrs = 15 // out of range
        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.didSubmit)
    }

    func testSubmitHandlesServerError() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    // MARK: - loadHistory

    func testLoadHistoryPopulatesDailyKpis() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclDailyKpiHistoryJSON())
        }

        await viewModel.loadHistory()

        XCTAssertEqual(viewModel.dailyKpis.count, 2)
        XCTAssertFalse(viewModel.isLoadingHistory)
        XCTAssertNil(viewModel.errorMessage)
        // Sorted by date descending — 2025-10-15 first
        XCTAssertEqual(viewModel.dailyKpis.first?.date, "2025-10-15")
    }

    func testLoadHistoryHandlesError() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        await viewModel.loadHistory()

        XCTAssertTrue(viewModel.dailyKpis.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoadingHistory)
    }
}

// MARK: - AclWeeklyKpiViewModelTests

@MainActor
final class AclWeeklyKpiViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: AclWeeklyKpiViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = AclWeeklyKpiViewModel(apiClient: apiClient)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil
    }

    // MARK: - Parsed Values

    func testParsedIkdcScore() {
        viewModel.ikdcScoreText = "55"
        XCTAssertEqual(viewModel.ikdcScore, 55)

        viewModel.ikdcScoreText = "abc"
        XCTAssertNil(viewModel.ikdcScore)
    }

    func testParsedTampaScore() {
        viewModel.tampaScoreText = "30"
        XCTAssertEqual(viewModel.tampaScore, 30)
    }

    func testParsedThighCircWithComma() {
        viewModel.thighCirc5cmText = "42,5"
        XCTAssertEqual(viewModel.thighCirc5cm, 42.5)

        viewModel.thighCirc10cmText = "48.0"
        XCTAssertEqual(viewModel.thighCirc10cm, 48.0)
    }

    // MARK: - isTampaElevated

    func testIsTampaElevatedTrueAbove37() {
        viewModel.tampaScoreText = "38"
        XCTAssertTrue(viewModel.isTampaElevated)

        viewModel.tampaScoreText = "44"
        XCTAssertTrue(viewModel.isTampaElevated)
    }

    func testIsTampaElevatedFalseAt37OrBelow() {
        viewModel.tampaScoreText = "37"
        XCTAssertFalse(viewModel.isTampaElevated)

        viewModel.tampaScoreText = "25"
        XCTAssertFalse(viewModel.isTampaElevated)
    }

    func testIsTampaElevatedFalseWhenEmpty() {
        viewModel.tampaScoreText = ""
        XCTAssertFalse(viewModel.isTampaElevated)
    }

    // MARK: - hasAnyValue

    func testHasAnyValueFalseWhenAllEmpty() {
        XCTAssertFalse(viewModel.hasAnyValue)
    }

    func testHasAnyValueTrueWhenIkdcSet() {
        viewModel.ikdcScoreText = "50"
        XCTAssertTrue(viewModel.hasAnyValue)
    }

    // MARK: - Validation

    func testValidationErrorForIkdcOutOfRange() {
        viewModel.ikdcScoreText = "101"
        XCTAssertNotNil(viewModel.validationError)
    }

    func testValidationErrorForTampaOutOfRange() {
        viewModel.tampaScoreText = "10" // below 11
        XCTAssertNotNil(viewModel.validationError)

        viewModel.tampaScoreText = "45" // above 44
        XCTAssertNotNil(viewModel.validationError)
    }

    func testValidationErrorForThighCircOutOfRange() {
        viewModel.thighCirc5cmText = "19" // below 20
        XCTAssertNotNil(viewModel.validationError)

        viewModel.thighCirc5cmText = ""
        viewModel.thighCirc10cmText = "81" // above 80
        XCTAssertNotNil(viewModel.validationError)
    }

    func testValidationNoErrorForValidValues() {
        viewModel.ikdcScoreText = "55"
        viewModel.tampaScoreText = "30"
        viewModel.thighCirc5cmText = "42.5"
        viewModel.thighCirc10cmText = "48.0"
        XCTAssertNil(viewModel.validationError)
    }

    // MARK: - Submit

    func testSubmitSendsCorrectEndpoint() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            XCTAssertTrue(url.contains("acl/weekly-kpi"), "Expected acl/weekly-kpi endpoint, got \(url)")
            XCTAssertEqual(request.httpMethod, "POST")
            return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclWeeklyKpiJSON())
        }

        viewModel.ikdcScoreText = "55"
        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.didSubmit)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSubmitReturnsFalseWhenNoValues() async {
        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testSubmitReturnsFalseWhenValidationFails() async {
        viewModel.ikdcScoreText = "200" // out of range
        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testSubmitSetsTampaAlertFromResponse() async {
        let tampaAlertJSON: [String: Any] = [
            "kpi": [
                "id": "weekly-kpi-1",
                "weekDate": "2025-10-13",
                "ikdcScore": 55,
                "tampaScore": 40,
            ],
            "tampaAlert": true,
        ]
        let data = try! JSONSerialization.data(withJSONObject: tampaAlertJSON)

        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), data)
        }

        viewModel.tampaScoreText = "40"
        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertTrue(viewModel.showTampaAlert)
    }

    func testSubmitHandlesServerError() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        viewModel.ikdcScoreText = "55"
        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    // MARK: - loadHistory

    func testLoadHistoryPopulatesWeeklyKpis() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclWeeklyKpiHistoryJSON())
        }

        await viewModel.loadHistory()

        XCTAssertEqual(viewModel.weeklyKpis.count, 2)
        XCTAssertFalse(viewModel.isLoadingHistory)
        XCTAssertNil(viewModel.errorMessage)
        // Sorted by weekDate descending
        XCTAssertEqual(viewModel.weeklyKpis.first?.weekDate, "2025-10-13")
    }

    func testLoadHistoryHandlesError() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        await viewModel.loadHistory()

        XCTAssertTrue(viewModel.weeklyKpis.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoadingHistory)
    }
}

// MARK: - AclDashboardViewModelTests

@MainActor
final class AclDashboardViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: AclDashboardViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = AclDashboardViewModel(apiClient: apiClient)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil
    }

    // MARK: - loadAll

    func testLoadAllPopulatesAllData() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if url.contains("milestone-status") {
                return (response, TestFixtures.aclMilestoneStatusJSON())
            } else if url.contains("streams") {
                return (response, TestFixtures.aclStreamsResponseJSON())
            } else if url.contains("discharge-progress") {
                return (response, TestFixtures.aclDischargeProgressJSON())
            }
            return (response, Data())
        }

        await viewModel.loadAll()

        XCTAssertNotNil(viewModel.milestoneStatus)
        XCTAssertEqual(viewModel.milestoneStatus?.currentMilestone, 2)
        XCTAssertFalse(viewModel.streams.isEmpty)
        XCTAssertEqual(viewModel.streams.count, 3)
        XCTAssertNotNil(viewModel.dischargeProgress)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadAllHandlesPartialFailure() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""

            if url.contains("milestone-status") {
                return (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
            } else if url.contains("streams") {
                return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclStreamsResponseJSON())
            } else if url.contains("discharge-progress") {
                return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclDischargeProgressJSON())
            }
            return (TestHelpers.makeHTTPResponse(statusCode: 200), Data())
        }

        await viewModel.loadAll()

        // Milestone failed but streams and discharge should still work
        XCTAssertNil(viewModel.milestoneStatus)
        XCTAssertEqual(viewModel.streams.count, 3)
        XCTAssertNotNil(viewModel.dischargeProgress)
        XCTAssertNotNil(viewModel.errorMessage)
    }

    func testLoadAllSetsErrorOnTotalFailure() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        await viewModel.loadAll()

        XCTAssertNil(viewModel.milestoneStatus)
        XCTAssertTrue(viewModel.streams.isEmpty)
        XCTAssertNil(viewModel.dischargeProgress)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Computed Properties

    func testCurrentMilestoneDefaultsToZero() {
        XCTAssertEqual(viewModel.currentMilestone, 0)
    }

    func testCurrentMilestoneFromStatus() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if url.contains("milestone-status") {
                return (response, TestFixtures.aclMilestoneStatusJSON())
            } else if url.contains("streams") {
                return (response, TestFixtures.aclStreamsResponseJSON())
            } else if url.contains("discharge-progress") {
                return (response, TestFixtures.aclDischargeProgressJSON())
            }
            return (response, Data())
        }

        await viewModel.loadAll()

        XCTAssertEqual(viewModel.currentMilestone, 2)
    }

    func testWeeksPostSurgeryDefaultsToZero() {
        XCTAssertEqual(viewModel.weeksPostSurgery, 0)
    }

    func testWeeksPostSurgeryFromStatus() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if url.contains("milestone-status") {
                return (response, TestFixtures.aclMilestoneStatusJSON())
            } else if url.contains("streams") {
                return (response, TestFixtures.aclStreamsResponseJSON())
            } else if url.contains("discharge-progress") {
                return (response, TestFixtures.aclDischargeProgressJSON())
            }
            return (response, Data())
        }

        await viewModel.loadAll()

        XCTAssertEqual(viewModel.weeksPostSurgery, 8)
    }

    func testUnlockedStreamsFiltersCorrectly() async {
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if url.contains("milestone-status") {
                return (response, TestFixtures.aclMilestoneStatusJSON())
            } else if url.contains("streams") {
                return (response, TestFixtures.aclStreamsResponseJSON())
            } else if url.contains("discharge-progress") {
                return (response, TestFixtures.aclDischargeProgressJSON())
            }
            return (response, Data())
        }

        await viewModel.loadAll()

        // 2 unlocked (locked=false), 1 locked (locked=true)
        XCTAssertEqual(viewModel.unlockedStreams.count, 2)
        XCTAssertEqual(viewModel.lockedStreams.count, 1)
        XCTAssertEqual(viewModel.lockedStreams.first?.id, "stream-plyo")
    }
}

// MARK: - AclScreeningViewModelTests

@MainActor
final class AclScreeningViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: AclScreeningViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = AclScreeningViewModel(apiClient: apiClient)
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil
    }

    // MARK: - loadConfig

    func testLoadConfigSuccess() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }

        await viewModel.loadConfig()

        XCTAssertNotNil(viewModel.config)
        XCTAssertEqual(viewModel.steps.count, 6)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadConfigError() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        await viewModel.loadConfig()

        XCTAssertNil(viewModel.config)
        XCTAssertTrue(viewModel.steps.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - isStepComplete

    func testSurgeryDateStepNotCompleteByDefault() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        let dateStep = viewModel.steps[0]
        XCTAssertFalse(viewModel.isStepComplete(dateStep))
    }

    func testSurgeryDateStepCompleteAfterSet() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        viewModel.setSurgeryDate(Date())

        let dateStep = viewModel.steps[0]
        XCTAssertTrue(viewModel.isStepComplete(dateStep))
    }

    func testRadioStepCompleteAfterSelection() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        let graftStep = viewModel.steps[1]
        XCTAssertFalse(viewModel.isStepComplete(graftStep))

        viewModel.selectRadio(stepId: "graft_type", value: "HAMSTRING")
        XCTAssertTrue(viewModel.isStepComplete(graftStep))
    }

    // MARK: - selectRadio

    func testSelectRadioSetsGraftType() {
        viewModel.selectRadio(stepId: "graft_type", value: "PATELLAR_TENDON")
        XCTAssertEqual(viewModel.graftType, "PATELLAR_TENDON")
    }

    func testSelectRadioSetsAthleteLevel() {
        viewModel.selectRadio(stepId: "athlete_level", value: "COMPETITIVE")
        XCTAssertEqual(viewModel.athleteLevel, "COMPETITIVE")
    }

    func testSelectRadioSetsKneeSide() {
        viewModel.selectRadio(stepId: "knee_side", value: "LEFT")
        XCTAssertEqual(viewModel.kneeSide, "LEFT")
    }

    // MARK: - toggleCheckbox

    func testToggleCheckboxAddsValue() {
        viewModel.toggleCheckbox(value: "MENISCAL_REPAIR")
        XCTAssertTrue(viewModel.concomitantInjuries.contains("MENISCAL_REPAIR"))
    }

    func testToggleCheckboxRemovesValue() {
        viewModel.concomitantInjuries = ["MENISCAL_REPAIR"]
        viewModel.toggleCheckbox(value: "MENISCAL_REPAIR")
        XCTAssertFalse(viewModel.concomitantInjuries.contains("MENISCAL_REPAIR"))
    }

    func testToggleCheckboxNoneClearsOthers() {
        viewModel.concomitantInjuries = ["MENISCAL_REPAIR", "CHONDRAL_REPAIR"]
        viewModel.toggleCheckbox(value: "NONE")
        XCTAssertEqual(viewModel.concomitantInjuries, ["NONE"])
    }

    func testToggleCheckboxInjuryRemovesNone() {
        viewModel.concomitantInjuries = ["NONE"]
        viewModel.toggleCheckbox(value: "MENISCAL_REPAIR")
        XCTAssertFalse(viewModel.concomitantInjuries.contains("NONE"))
        XCTAssertTrue(viewModel.concomitantInjuries.contains("MENISCAL_REPAIR"))
    }

    // MARK: - Navigation

    func testGoForwardAdvancesStep() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        viewModel.setSurgeryDate(Date())
        XCTAssertEqual(viewModel.currentStepIndex, 0)

        viewModel.goForward()
        XCTAssertEqual(viewModel.currentStepIndex, 1)
    }

    func testGoBackDecreasesStep() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        viewModel.currentStepIndex = 3
        viewModel.goBack()
        XCTAssertEqual(viewModel.currentStepIndex, 2)
    }

    func testGoBackAtStartDoesNothing() {
        XCTAssertEqual(viewModel.currentStepIndex, 0)
        viewModel.goBack()
        XCTAssertEqual(viewModel.currentStepIndex, 0)
    }

    // MARK: - canSubmit

    func testCanSubmitFalseWhenRequiredStepsIncomplete() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        // Only set surgery date — graft_type, athlete_level, knee_side still missing
        viewModel.setSurgeryDate(Date())
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmitTrueWhenAllRequiredComplete() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        viewModel.setSurgeryDate(Date())
        viewModel.selectRadio(stepId: "graft_type", value: "HAMSTRING")
        viewModel.selectRadio(stepId: "athlete_level", value: "RECREATIONAL")
        viewModel.selectRadio(stepId: "knee_side", value: "LEFT")
        // concomitant_injuries and sport are optional
        XCTAssertTrue(viewModel.canSubmit)
    }

    // MARK: - submit

    func testSubmitSuccess() async {
        var configLoaded = false
        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            let response = TestHelpers.makeHTTPResponse(statusCode: 200)

            if !configLoaded {
                configLoaded = true
                return (response, TestFixtures.aclScreeningConfigJSON())
            }

            XCTAssertTrue(url.contains("acl/screening"), "Expected acl/screening endpoint, got \(url)")
            XCTAssertEqual(request.httpMethod, "POST")
            return (response, TestFixtures.aclScreeningResultJSON())
        }

        await viewModel.loadConfig()

        viewModel.setSurgeryDate(Date())
        viewModel.selectRadio(stepId: "graft_type", value: "HAMSTRING")
        viewModel.selectRadio(stepId: "athlete_level", value: "RECREATIONAL")
        viewModel.selectRadio(stepId: "knee_side", value: "LEFT")

        // Wait briefly for any auto-advance tasks to finish
        try? await Task.sleep(for: .milliseconds(600))

        let success = await viewModel.submit()

        XCTAssertTrue(success)
        XCTAssertNotNil(viewModel.result)
        XCTAssertEqual(viewModel.result?.graftType, "HAMSTRING")
        XCTAssertFalse(viewModel.isSubmitting)
    }

    func testSubmitReturnsFalseWhenIncomplete() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        // Do not fill required fields
        let success = await viewModel.submit()
        XCTAssertFalse(success)
    }

    func testSubmitHandlesServerError() async {
        var configLoaded = false
        MockURLProtocol.requestHandler = { _ in
            if !configLoaded {
                configLoaded = true
                return (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
            }
            return (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        await viewModel.loadConfig()

        viewModel.setSurgeryDate(Date())
        viewModel.selectRadio(stepId: "graft_type", value: "HAMSTRING")
        viewModel.selectRadio(stepId: "athlete_level", value: "RECREATIONAL")
        viewModel.selectRadio(stepId: "knee_side", value: "LEFT")

        try? await Task.sleep(for: .milliseconds(600))

        let success = await viewModel.submit()

        XCTAssertFalse(success)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isSubmitting)
    }

    // MARK: - progress

    func testProgressZeroWhenNoConfig() {
        XCTAssertEqual(viewModel.progress, 0.0)
    }

    func testProgressCalculation() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        // 6 steps total, concomitant_injuries and sport are always "complete"
        // So 2/6 complete by default (optional steps)
        let baseProgress = viewModel.progress

        viewModel.setSurgeryDate(Date())
        let afterDate = viewModel.progress
        XCTAssertGreaterThan(afterDate, baseProgress)
    }

    // MARK: - currentStep

    func testCurrentStepReturnsCorrectStep() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), TestFixtures.aclScreeningConfigJSON())
        }
        await viewModel.loadConfig()

        XCTAssertEqual(viewModel.currentStep?.id, "surgery_date")

        viewModel.currentStepIndex = 1
        XCTAssertEqual(viewModel.currentStep?.id, "graft_type")
    }

    func testCurrentStepNilWhenNoConfig() {
        XCTAssertNil(viewModel.currentStep)
    }
}

// MARK: - AclStreamViewModelTests

@MainActor
final class AclStreamViewModelTests: XCTestCase {

    private var apiClient: APIClient!
    private var viewModel: AclStreamViewModel!

    override func setUp() async throws {
        let session = TestHelpers.makeTestSession()
        apiClient = APIClient(session: session)
        viewModel = AclStreamViewModel(apiClient: apiClient, streamId: "stream-rom")
    }

    override func tearDown() async throws {
        MockURLProtocol.requestHandler = nil
        viewModel = nil
        apiClient = nil
    }

    func testLoadDetailSuccess() async {
        let json: [String: Any] = [
            "stream": [
                "id": "stream-rom",
                "name": "ROM Recovery",
                "nameDE": "ROM Wiederherstellung",
                "description": "Range of motion exercises",
                "milestone": 1,
            ],
            "exercises": [
                [
                    "id": "ex-1",
                    "name": "Heel Slides",
                    "nameDE": "Fersenschleifen",
                    "description": "Slide heel towards buttocks",
                    "sets": 3,
                    "reps": "15",
                ]
            ],
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)

        MockURLProtocol.requestHandler = { request in
            let url = request.url?.absoluteString ?? ""
            XCTAssertTrue(url.contains("acl/streams/stream-rom"))
            return (TestHelpers.makeHTTPResponse(statusCode: 200), data)
        }

        await viewModel.loadDetail()

        XCTAssertNotNil(viewModel.streamDetail)
        XCTAssertEqual(viewModel.streamDetail?.id, "stream-rom")
        XCTAssertEqual(viewModel.exercises.count, 1)
        XCTAssertEqual(viewModel.exercises.first?.name, "Heel Slides")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testLoadDetailHandlesError() async {
        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 500), Data())
        }

        await viewModel.loadDetail()

        XCTAssertNil(viewModel.streamDetail)
        XCTAssertTrue(viewModel.exercises.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testLoadDetailFallsBackToStreamExercises() async {
        // When top-level exercises is empty, falls back to stream.exercises
        let json: [String: Any] = [
            "stream": [
                "id": "stream-rom",
                "name": "ROM Recovery",
                "exercises": [
                    [
                        "id": "ex-nested",
                        "name": "Nested Exercise",
                    ]
                ],
            ],
            "exercises": [] as [[String: Any]],
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)

        MockURLProtocol.requestHandler = { _ in
            (TestHelpers.makeHTTPResponse(statusCode: 200), data)
        }

        await viewModel.loadDetail()

        XCTAssertEqual(viewModel.exercises.count, 1)
        XCTAssertEqual(viewModel.exercises.first?.name, "Nested Exercise")
    }
}
