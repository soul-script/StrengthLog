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

// Modified Epley formula: If reps = 1, use actual weight as 1RM
// Otherwise, use Epley formula: 1RM = weight × (1 + reps / 30)
func calculateOneRepMax(weight: Double, reps: Int) -> Double {
    guard reps > 0 else { return weight } // Avoid division by zero or negative reps issues in formula logic
    
    // For 1-rep sets, use the actual weight as the 1RM
    if reps == 1 {
        return weight
    }
    
    // For multiple reps, use the Epley formula
    return weight * (1 + Double(reps) / 30.0)
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