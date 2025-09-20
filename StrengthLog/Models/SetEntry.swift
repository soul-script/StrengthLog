import Foundation
import SwiftData

@Model
final class SetEntry: Identifiable {
    @Attribute(.unique) var id: UUID
    var weight: Double?  // Stored as kilograms
    var weightInPounds: Double?
    var reps: Int
    var calculatedOneRepMax: Double
    
    @Relationship(deleteRule: .nullify) var workoutRecord: WorkoutRecord?
    
    init(weight: Double? = nil, weightInPounds: Double? = nil, reps: Int, workoutRecord: WorkoutRecord? = nil) {
        self.id = UUID()
        self.weight = nil
        self.weightInPounds = nil
        self.reps = reps
        self.calculatedOneRepMax = 0
        self.workoutRecord = workoutRecord

        let measurement = WeightConversionService.shared.measurement(kilograms: weight, pounds: weightInPounds)
        apply(weightMeasurement: measurement)
        self.calculatedOneRepMax = calculateOneRepMax(weight: self.weight, reps: reps)
    }
    
    // Update one-rep max when weight or reps change
    func updateOneRepMax() {
        self.calculatedOneRepMax = calculateOneRepMax(weight: weight, reps: reps)
    }

    func updateWeight(kilograms: Double?, pounds: Double? = nil) {
        let measurement = WeightConversionService.shared.measurement(kilograms: kilograms, pounds: pounds)
        apply(weightMeasurement: measurement)
        updateOneRepMax()
    }

    func weightValue(in unit: WeightUnit) -> Double? {
        switch unit {
        case .kg:
            if let weight { return weight }
            if let pounds = weightInPounds {
                return WeightConversionService.shared.kilograms(fromPounds: pounds)
            }
        case .lbs:
            if let weightInPounds { return weightInPounds }
            if let weight {
                return WeightConversionService.shared.pounds(fromKilograms: weight)
            }
        }
        return nil
    }

    var isWeighted: Bool {
        weightValue(in: .kg) != nil
    }

    private func apply(weightMeasurement: WeightMeasurement?) {
        if let measurement = weightMeasurement {
            self.weight = measurement.kilograms
            self.weightInPounds = measurement.pounds
        } else {
            self.weight = nil
            self.weightInPounds = nil
        }
    }
}
