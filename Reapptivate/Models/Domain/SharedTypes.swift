// SharedTypes.swift
// Core enums shared across the Reapptivate iOS app
// Based on shared/types/index.ts from the web app

import Foundation

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

    var displayName: String {
        switch self {
        case .tennisElbow: "Tennisellenbogen"
        case .golfersElbow: "Golferellenbogen"
        case .achilles: "Achillessehne"
        case .patellar: "Patellasehne"
        case .rotatorCuff: "Rotatorenmanschette"
        case .gluteal: "Glutealsehne"
        case .proximalHamstring: "Proximale Hamstringsehne"
        case .plantarFascia: "Plantarfaszie"
        case .lbpNonspecific: "Unspez. Ruckenschmerz"
        case .neckPain: "Nackenschmerz"
        }
    }

    var isLbp: Bool { self == .lbpNonspecific }
    var isNeck: Bool { self == .neckPain }
    var isTendinopathy: Bool { !isLbp && !isNeck }
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

    var displayName: String {
        switch self {
        case .isometric: "Isometrisch"
        case .hsr: "Heavy-Slow Resistance"
        case .eccentric: "Exzentrisch"
        case .concentric: "Konzentrisch"
        case .motorControl: "Motorische Kontrolle"
        case .bodyAwareness: "Korperwahrnehmung"
        case .pacing: "Pacing"
        case .gradedActivity: "Graded Activity"
        }
    }
}

// MARK: - Phase Adaptation

enum AdaptationDecision: String, Codable {
    case progress = "PROGRESS"
    case hold = "HOLD"
    case regress = "REGRESS"
    case initial = "INITIAL"

    var displayName: String {
        switch self {
        case .progress: "Aufgestiegen"
        case .hold: "Gehalten"
        case .regress: "Angepasst"
        case .initial: "Start"
        }
    }
}

// MARK: - AEM Subtypes

enum AemSubtype: String, Codable {
    case FAR
    case DER
    case EER
    case AR

    var displayName: String {
        switch self {
        case .FAR: "Fear-Avoidance"
        case .DER: "Distress-Endurance"
        case .EER: "Eustress-Endurance"
        case .AR: "Adaptiver Responder"
        }
    }

    var maxPainLevel: Int {
        switch self {
        case .FAR: 5
        case .DER: 3
        case .EER: 3
        case .AR: 4
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

    var displayName: String {
        switch self {
        case .LEICHT: "Leicht"
        case .MITTEL: "Mittel"
        case .SCHWER: "Schwer"
        }
    }

    static func from(ndiScore: Int) -> NdiSeverityGrade {
        if ndiScore <= 14 { return .LEICHT }
        if ndiScore <= 28 { return .MITTEL }
        return .SCHWER
    }
}

enum SymptomResponse: String, Codable {
    case centralized = "CENTRALIZED"
    case unchanged = "UNCHANGED"
    case peripheralized = "PERIPHERALIZED"

    var displayName: String {
        switch self {
        case .centralized: "Zentralisiert"
        case .unchanged: "Unverandert"
        case .peripheralized: "Peripheralisiert"
        }
    }
}

// MARK: - Visual Indicator

enum VisualIndicator: String, Codable {
    case exploration
    case pacing
    case dosing
}
