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

// Epley formula: 1RM = weight × (1 + reps / 30)
func calculateOneRepMax(weight: Double, reps: Int) -> Double {
    guard reps > 0 else { return weight } // Avoid division by zero or negative reps issues in formula logic
    return weight * (1 + Double(reps) / 30.0)
} 