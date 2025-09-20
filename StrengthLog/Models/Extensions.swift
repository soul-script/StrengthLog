import Foundation

// Helper for number formatters
extension NumberFormatter {
    static var decimal: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter
    }

    static var integer: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none // No thousands separators for reps
        formatter.maximumFractionDigits = 0
        return formatter
    }
}

protocol OneRepMaxFormula {
    func estimatedMax(weight: Double, reps: Int) -> Double
}

struct EpleyOneRepMaxFormula: OneRepMaxFormula {
    func estimatedMax(weight: Double, reps: Int) -> Double {
        guard weight > 0, reps > 0 else { return 0 }
        if reps == 1 {
            return weight
        }
        return weight * (1 + Double(reps) / 30.0)
    }
}

struct OneRepMaxCalculator {
    static let shared = OneRepMaxCalculator(formula: EpleyOneRepMaxFormula())
    
    private let formula: OneRepMaxFormula
    private let roundingRule: FloatingPointRoundingRule
    
    init(
        formula: OneRepMaxFormula,
        roundingRule: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    ) {
        self.formula = formula
        self.roundingRule = roundingRule
    }
    
    func calculate(weight: Double?, reps: Int) -> Double {
        guard let weight = weight else { return 0 }
        return calculate(weight: weight, reps: reps)
    }
    
    func calculate(weight: Double, reps: Int) -> Double {
        let rawValue = formula.estimatedMax(weight: weight, reps: reps)
        return normalizedOneRepMax(for: rawValue)
    }
    
    func normalizedOneRepMax(for rawValue: Double) -> Double {
        guard rawValue.isFinite else { return 0 }
        let nonNegative = max(rawValue, 0)
        let rounded = nonNegative.rounded(roundingRule)
        return Double(Int(rounded))
    }
}

struct WeightMeasurement {
    let kilograms: Double
    let pounds: Double

    func value(in unit: WeightUnit) -> Double {
        switch unit {
        case .kg:
            return kilograms
        case .lbs:
            return pounds
        }
    }
}

protocol WeightConversionProviding {
    func measurement(from value: Double, unit: WeightUnit) -> WeightMeasurement?
    func measurement(kilograms: Double?, pounds: Double?) -> WeightMeasurement?
    func pounds(fromKilograms kilograms: Double) -> Double
    func kilograms(fromPounds pounds: Double) -> Double
}

struct WeightConversionService: WeightConversionProviding {
    static let shared = WeightConversionService()

    private let roundingRule: FloatingPointRoundingRule = .toNearestOrAwayFromZero
    private let kilogramsPerPound: Double = 0.45359237
    private let poundsPerKilogram: Double = 2.2046226218

    private init() {}

    func measurement(from value: Double, unit: WeightUnit) -> WeightMeasurement? {
        switch unit {
        case .kg:
            guard let kilograms = normalize(value) else { return nil }
            let pounds = pounds(fromKilograms: kilograms)
            return WeightMeasurement(kilograms: kilograms, pounds: pounds)
        case .lbs:
            guard let pounds = normalize(value) else { return nil }
            let kilograms = kilograms(fromPounds: pounds)
            return WeightMeasurement(kilograms: kilograms, pounds: pounds)
        }
    }

    func measurement(kilograms: Double?, pounds: Double?) -> WeightMeasurement? {
        if let kilograms, let measurement = measurement(from: kilograms, unit: .kg) {
            return measurement
        }
        if let pounds, let measurement = measurement(from: pounds, unit: .lbs) {
            return measurement
        }
        return nil
    }

    func pounds(fromKilograms kilograms: Double) -> Double {
        guard let sanitizedKilograms = normalize(kilograms) else { return 0 }
        let converted = sanitizedKilograms * poundsPerKilogram
        return normalize(converted) ?? 0
    }

    func kilograms(fromPounds pounds: Double) -> Double {
        guard let sanitizedPounds = normalize(pounds) else { return 0 }
        let converted = sanitizedPounds * kilogramsPerPound
        return normalize(converted) ?? 0
    }

    private func normalize(_ value: Double) -> Double? {
        guard value.isFinite else { return nil }
        let sanitized = max(value, 0)
        let rounded = sanitized.rounded(roundingRule)
        guard rounded > 0 else { return nil }
        return Double(Int(rounded))
    }
}

func convertWeight(_ value: Double, from sourceUnit: WeightUnit, to targetUnit: WeightUnit) -> Double {
    guard let measurement = WeightConversionService.shared.measurement(from: value, unit: sourceUnit) else { return 0 }
    return measurement.value(in: targetUnit)
}

// Modified Epley formula with resilient rounding support
func calculateOneRepMax(weight: Double, reps: Int) -> Double {
    OneRepMaxCalculator.shared.calculate(weight: weight, reps: reps)
}

func calculateOneRepMax(weight: Double?, reps: Int) -> Double {
    OneRepMaxCalculator.shared.calculate(weight: weight, reps: reps)
}

func normalizeOneRepMax(_ value: Double) -> Double {
    OneRepMaxCalculator.shared.normalizedOneRepMax(for: value)
}

func convertOneRepMax(_ value: Double, to unit: WeightUnit) -> Double {
    let normalized = normalizeOneRepMax(value)
    switch unit {
    case .kg:
        return normalized
    case .lbs:
        return WeightConversionService.shared.pounds(fromKilograms: normalized)
    }
}

// MARK: - Date utilities for consistent timestamp handling
extension Date {
    /// Returns a new Date set to midnight (00:00:00.000) of the same day
    var midnight: Date {
        Calendar.current.startOfDay(for: self)
    }
    
    /// Creates a new Date set to midnight (00:00:00.000) of today
    static var todayAtMidnight: Date {
        Date().midnight
    }
}
