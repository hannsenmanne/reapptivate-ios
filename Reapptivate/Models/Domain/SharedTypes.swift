// SharedTypes.swift
// Core enums shared across the Reapptivate iOS app
// Based on shared/types/index.ts from the web app

import Foundation

// MARK: - Shared Focus Area Protocol

/// Common interface for all condition-specific focus area models (NDI, TSI, SI, FS, LAS).
/// Enables a single generic FocusAreasView for all conditions.
protocol FocusAreaProtocol: Codable, Identifiable {
    var domainId: String { get }
    var domainLabel: String { get }
    var score: Int { get }
    var maxScore: Int { get }
    var dailyTips: [String]? { get }
    var percentage: Double { get }
}

// File-private language helper — reads AppStorage backing store directly
private var isEnglishLocale: Bool {
    UserDefaults.standard.string(forKey: "appLanguage") == "en"
}

// MARK: - Condition Type

enum TendinopathyType: String, Codable, CaseIterable {
    case tennisElbow = "TENNIS_ELBOW"
    case golfersElbow = "GOLFERS_ELBOW"
    case achilles = "ACHILLES"
    case patellar = "PATELLAR"
    case rotatorCuff = "ROTATOR_CUFF"
    case gluteal = "GLUTEAL"
    case proximalHamstring = "PROXIMAL_HAMSTRING"
    case plantarFascia = "PLANTAR_FASCIA"
    case lbpNonspecific = "LBP_NONSPECIFIC"
    case neckPain = "NECK_PAIN"
    case neckShoulderTension = "NECK_SHOULDER_TENSION"
    case aclReconstruction = "ACL_RECONSTRUCTION"
    case shoulderImpingement = "SHOULDER_IMPINGEMENT"
    case frozenShoulder = "FROZEN_SHOULDER"
    case lateralAnkleSprain = "LATERAL_ANKLE_SPRAIN"
    case unknown = "UNKNOWN"

    /// All known cases, excluding `.unknown`.
    static var allCases: [TendinopathyType] {
        [.tennisElbow, .golfersElbow, .achilles, .patellar, .rotatorCuff,
         .gluteal, .proximalHamstring, .plantarFascia, .lbpNonspecific,
         .neckPain, .neckShoulderTension, .aclReconstruction, .shoulderImpingement,
         .frozenShoulder, .lateralAnkleSprain]
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .tennisElbow: return "Tennis Elbow"
            case .golfersElbow: return "Golfer's Elbow"
            case .achilles: return "Achilles Tendinopathy"
            case .patellar: return "Patellar Tendinopathy"
            case .rotatorCuff: return "Rotator Cuff Tendinopathy"
            case .gluteal: return "Gluteal Tendinopathy"
            case .proximalHamstring: return "Proximal Hamstring Tendinopathy"
            case .plantarFascia: return "Plantar Fasciitis"
            case .lbpNonspecific: return "Non-specific Lower Back Pain"
            case .neckPain: return "Neck Pain"
            case .neckShoulderTension: return "Neck & Shoulder Tension"
            case .aclReconstruction: return "ACL Reconstruction"
            case .shoulderImpingement: return "Shoulder Impingement"
            case .frozenShoulder: return "Frozen Shoulder"
            case .lateralAnkleSprain: return "Lateral Ankle Sprain"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .tennisElbow: return "Tennisellenbogen"
        case .golfersElbow: return "Golferellenbogen"
        case .achilles: return "Achillessehne"
        case .patellar: return "Patellasehne"
        case .rotatorCuff: return "Rotatorenmanschette"
        case .gluteal: return "Glutealsehne"
        case .proximalHamstring: return "Proximale Hamstringsehne"
        case .plantarFascia: return "Plantarfaszie"
        case .lbpNonspecific: return "Unspez. Rückenschmerz"
        case .neckPain: return "Nackenschmerz"
        case .neckShoulderTension: return "Nacken-Schulter-Verspannung"
        case .aclReconstruction: return "Kreuzbandrekonstruktion"
        case .shoulderImpingement: return "Schulter-Impingement"
        case .frozenShoulder: return "Frozen Shoulder"
        case .lateralAnkleSprain: return "Laterale Sprunggelenksverstauchung"
        case .unknown: return "Unbekannt"
        }
    }

    var isLbp: Bool { self == .lbpNonspecific }
    var isNeck: Bool { self == .neckPain }
    var isTension: Bool { self == .neckShoulderTension }
    var isAcl: Bool { self == .aclReconstruction }
    var isShoulder: Bool { self == .shoulderImpingement }
    var isFrozenShoulder: Bool { self == .frozenShoulder }
    var isLateralAnkleSprain: Bool { self == .lateralAnkleSprain }
    var isTendinopathy: Bool { !isLbp && !isNeck && !isTension && !isAcl && !isShoulder && !isFrozenShoulder && !isLateralAnkleSprain && self != .unknown }
}

// MARK: - Exercise Type

enum ExerciseType: String, Codable {
    case isometric = "ISOMETRIC"
    case hsr = "HSR"
    case eccentric = "ECCENTRIC"
    case concentric = "CONCENTRIC"
    case motorControl = "MOTOR_CONTROL"
    case bodyAwareness = "BODY_AWARENESS"
    case pacing = "PACING"
    case gradedActivity = "GRADED_ACTIVITY"
    case relaxation = "RELAXATION"
    case functional = "FUNCTIONAL"
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .isometric: return "Isometric"
            case .hsr: return "Heavy Slow Resistance (HSR)"
            case .eccentric: return "Eccentric"
            case .concentric: return "Concentric"
            case .motorControl: return "Motor Control"
            case .bodyAwareness: return "Body Awareness"
            case .pacing: return "Pacing"
            case .gradedActivity: return "Graded Activity"
            case .relaxation: return "Relaxation"
            case .functional: return "Functional"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .isometric: return "Isometrisch"
        case .hsr: return "Schwer-Langsam (HSR)"
        case .eccentric: return "Exzentrisch"
        case .concentric: return "Konzentrisch"
        case .motorControl: return "Motorische Kontrolle"
        case .bodyAwareness: return "Körperwahrnehmung"
        case .pacing: return "Pacing"
        case .gradedActivity: return "Stufenweise Aktivität"
        case .relaxation: return "Entspannung"
        case .functional: return "Funktionell"
        case .unknown: return "Unbekannt"
        }
    }
}

// MARK: - Phase Adaptation

enum AdaptationDecision: String, Codable {
    case progress = "PROGRESS"
    case hold = "HOLD"
    case regress = "REGRESS"
    case initial = "INITIAL"
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .progress: return "Progress"
            case .hold: return "Hold"
            case .regress: return "Regress"
            case .initial: return "Initial"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .progress: return "Aufgestiegen"
        case .hold: return "Gehalten"
        case .regress: return "Angepasst"
        case .initial: return "Start"
        case .unknown: return "Unbekannt"
        }
    }
}

// MARK: - AEM Subtypes

enum AemSubtype: String, Codable {
    case FAR
    case DER
    case EER
    case AR
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .FAR: return "Fear-Avoidance Response (FAR)"
            case .DER: return "Disuse & Reconditioning (DER)"
            case .EER: return "Elevated Emotion & Recovery (EER)"
            case .AR: return "Adaptive Response (AR)"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .FAR: return "Fear-Avoidance"
        case .DER: return "Distress-Endurance"
        case .EER: return "Eustress-Endurance"
        case .AR: return "Adaptiver Responder"
        case .unknown: return "Unbekannt"
        }
    }

    var maxPainLevel: Int {
        switch self {
        case .FAR: 5
        case .DER: 3
        case .EER: 3
        case .AR: 4
        case .unknown: 4
        }
    }
}

enum AemSubscale: String, Codable {
    case fearAvoidance = "fear_avoidance"
    case distressEndurance = "distress_endurance"
    case eustressEndurance = "eustress_endurance"
}

// MARK: - Neck Pain Types

enum NeckSubtype: String, Codable {
    case neckNonspecific = "NECK_NONSPECIFIC"
    case neckRadiculopathy = "NECK_RADICULOPATHY"
}

enum NdiSeverityGrade: String, Codable {
    case LEICHT
    case MITTEL
    case SCHWER
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .LEICHT: return "Mild"
            case .MITTEL: return "Moderate"
            case .SCHWER: return "Severe"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .LEICHT: return "Leicht"
        case .MITTEL: return "Mittel"
        case .SCHWER: return "Schwer"
        case .unknown: return "Unbekannt"
        }
    }

    static func from(ndiScore: Int) -> NdiSeverityGrade {
        // NDI max = 50. LEICHT: 0-28% (≤14 raw), MITTEL: 29-48% (≤24 raw), SCHWER: 49%+
        if ndiScore <= 14 { return .LEICHT }
        if ndiScore <= 24 { return .MITTEL }
        return .SCHWER
    }
}

// MARK: - TSI Severity Grade

enum TsiSeverityGrade: String, Codable {
    case LEICHT
    case MITTEL
    case SCHWER
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .LEICHT: return "Mild"
            case .MITTEL: return "Moderate"
            case .SCHWER: return "Severe"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .LEICHT: return "Leicht"
        case .MITTEL: return "Mittel"
        case .SCHWER: return "Schwer"
        case .unknown: return "Unbekannt"
        }
    }

    static func from(tsiScore: Int) -> TsiSeverityGrade {
        // Thresholds aligned with backend percentage-based scoring:
        // TSI max = 50, percentage = score/50*100
        // LEICHT: ≤30% = ≤15 raw, MITTEL: ≤55% = ≤27 raw
        if tsiScore <= 15 { return .LEICHT }
        if tsiScore <= 27 { return .MITTEL }
        return .SCHWER
    }
}

// MARK: - SI Severity Grade

enum SiSeverityGrade: String, Codable {
    case LEICHT
    case MITTEL
    case SCHWER
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .LEICHT: return "Mild"
            case .MITTEL: return "Moderate"
            case .SCHWER: return "Severe"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .LEICHT: return "Leicht"
        case .MITTEL: return "Mittel"
        case .SCHWER: return "Schwer"
        case .unknown: return "Unbekannt"
        }
    }

    static func from(quickDashScore: Double) -> SiSeverityGrade {
        // QuickDASH 0-100. LEICHT: ≤40, MITTEL: ≤60, SCHWER: >60
        if quickDashScore <= 40 { return .LEICHT }
        if quickDashScore <= 60 { return .MITTEL }
        return .SCHWER
    }
}

// MARK: - FS Severity Grade

enum FsSeverityGrade: String, Codable {
    case LEICHT
    case MITTEL
    case SCHWER
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .LEICHT: return "Mild"
            case .MITTEL: return "Moderate"
            case .SCHWER: return "Severe"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .LEICHT: return "Leicht"
        case .MITTEL: return "Mittel"
        case .SCHWER: return "Schwer"
        case .unknown: return "Unbekannt"
        }
    }

    static func from(spadiScore: Double) -> FsSeverityGrade {
        // SPADI 0-100. LEICHT: <=34, MITTEL: <=59, SCHWER: >59
        if spadiScore <= 34 { return .LEICHT }
        if spadiScore <= 59 { return .MITTEL }
        return .SCHWER
    }
}

// MARK: - LAS Severity Grade

enum LasSeverityGrade: String, Codable {
    case LEICHT
    case MITTEL
    case SCHWER
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .LEICHT: return "Mild"
            case .MITTEL: return "Moderate"
            case .SCHWER: return "Severe"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .LEICHT: return "Leicht"
        case .MITTEL: return "Mittel"
        case .SCHWER: return "Schwer"
        case .unknown: return "Unbekannt"
        }
    }

    static func from(caitScore: Int) -> LasSeverityGrade {
        // CAIT 0-30. Higher = better. LEICHT: >=24, MITTEL: 12-23, SCHWER: <=11
        if caitScore >= 24 { return .LEICHT }
        if caitScore >= 12 { return .MITTEL }
        return .SCHWER
    }
}

enum SymptomResponse: String, Codable {
    case centralized = "CENTRALIZED"
    case unchanged = "UNCHANGED"
    case peripheralized = "PERIPHERALIZED"
    case unknown = "UNKNOWN"

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = Self(rawValue: rawValue) ?? .unknown
    }

    var displayName: String {
        if isEnglishLocale {
            switch self {
            case .centralized: return "Centralized"
            case .unchanged: return "Unchanged"
            case .peripheralized: return "Peripheralized"
            case .unknown: return "Unknown"
            }
        }
        switch self {
        case .centralized: return "Zentralisiert"
        case .unchanged: return "Unverändert"
        case .peripheralized: return "Peripheralisiert"
        case .unknown: return "Unbekannt"
        }
    }
}

// MARK: - Visual Indicator

enum VisualIndicator: String, Codable {
    case exploration
    case pacing
    case dosing
}
