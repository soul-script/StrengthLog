import Foundation
import SwiftData

@MainActor
struct ReferenceDataSeeder {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func seedIfNeeded() throws {
        var didMutateData = false

        let existingGroups = try fetchEntities(type: MajorMuscleGroup.self)
        var groupsByName = Dictionary(uniqueKeysWithValues: existingGroups.map { ($0.name, $0) })

        for seed in ReferenceSeedFactory.majorMuscleSeeds() {
            if groupsByName[seed.name] == nil {
                let group = MajorMuscleGroup(name: seed.name, info: seed.info)
                context.insert(group)
                groupsByName[seed.name] = group
                didMutateData = true
            }
        }

        let existingSpecificMuscles = try fetchEntities(type: SpecificMuscle.self)
        var specificByName = Dictionary(uniqueKeysWithValues: existingSpecificMuscles.map { ($0.name, $0) })

        for seed in ReferenceSeedFactory.majorMuscleSeeds() {
            guard let group = groupsByName[seed.name] else { continue }
            for muscleName in seed.specificMuscles {
                if specificByName[muscleName] == nil {
                    let specific = SpecificMuscle(name: muscleName, majorGroup: group)
                    context.insert(specific)
                    specificByName[muscleName] = specific
                    didMutateData = true
                }
            }
        }

        let existingCategories = try fetchEntities(type: WorkoutCategoryTag.self)
        var categoriesByName = Dictionary(uniqueKeysWithValues: existingCategories.map { ($0.name, $0) })

        for name in ReferenceSeedFactory.workoutCategoryNames {
            if categoriesByName[name] == nil {
                let tag = WorkoutCategoryTag(name: name)
                context.insert(tag)
                categoriesByName[name] = tag
                didMutateData = true
            }
        }

        if didMutateData {
            try context.save()
        }
    }

    private func fetchEntities<T: PersistentModel>(type: T.Type) throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try context.fetch(descriptor)
    }

}

private struct ReferenceSeedFactory {
    struct MajorSeed {
        let name: String
        let info: String?
        let specificMuscles: [String]
    }

    static func majorMuscleSeeds() -> [MajorSeed] {
        [
            MajorSeed(name: "Chest", info: "Chest muscles (pectorals) at the front of the upper torso.", specificMuscles: [
                "Pectoralis Major", "Pectoralis Minor", "Serratus Anterior"
            ]),
            MajorSeed(name: "Back", info: "Muscles of the upper and lower back (lats, traps, rhomboids, spinal erectors).", specificMuscles: [
                "Latissimus Dorsi", "Trapezius (Upper)", "Trapezius (Middle)", "Trapezius (Lower)",
                "Rhomboid Major", "Rhomboid Minor", "Teres Major", "Erector Spinae"
            ]),
            MajorSeed(name: "Shoulders", info: "Muscles around the shoulder joint (deltoids and rotator cuff).", specificMuscles: [
                "Anterior Deltoid", "Lateral Deltoid", "Posterior Deltoid",
                "Supraspinatus", "Infraspinatus", "Teres Minor", "Subscapularis"
            ]),
            MajorSeed(name: "Triceps", info: "Three-headed muscle on the back of the upper arm (elbow extensors).", specificMuscles: [
                "Triceps (Long Head)", "Triceps (Lateral Head)", "Triceps (Medial Head)"
            ]),
            MajorSeed(name: "Biceps", info: "Front of the upper arm (elbow flexors: biceps brachii and brachialis).", specificMuscles: [
                "Biceps Brachii", "Brachialis", "Coracobrachialis"
            ]),
            MajorSeed(name: "Forearms", info: "Muscles of the forearm that control the wrist, hand, and grip.", specificMuscles: [
                "Brachioradialis", "Wrist Flexors (Flexor Carpi group)", "Wrist Extensors (Extensor Carpi group)"
            ]),
            MajorSeed(name: "Abs/Core", info: "Abdominal muscles (abs and obliques) that stabilize the core.", specificMuscles: [
                "Rectus Abdominis", "External Oblique", "Internal Oblique", "Transversus Abdominis"
            ]),
            MajorSeed(name: "Glutes", info: "Buttocks muscles (gluteus maximus, medius, minimus) for hip extension/rotation.", specificMuscles: [
                "Gluteus Maximus", "Gluteus Medius", "Gluteus Minimus"
            ]),
            MajorSeed(name: "Quads", info: "Front thigh muscles (quadriceps) that extend the knee.", specificMuscles: [
                "Rectus Femoris", "Vastus Lateralis", "Vastus Medialis", "Vastus Intermedius"
            ]),
            MajorSeed(name: "Hamstrings", info: "Back thigh muscles (hamstrings) that flex the knee and extend the hip.", specificMuscles: [
                "Biceps Femoris", "Semimembranosus", "Semitendinosus"
            ]),
            MajorSeed(name: "Calves", info: "Calf muscles of the lower leg for ankle plantarflexion.", specificMuscles: [
                "Gastrocnemius", "Soleus"
            ]),
            MajorSeed(name: "Adductors", info: "Inner thigh muscles that adduct (bring inward) the legs.", specificMuscles: [
                "Adductor Longus", "Adductor Magnus", "Adductor Brevis", "Gracilis", "Pectineus"
            ]),
            MajorSeed(name: "Abductors", info: "Outer hip muscles that abduct (move outward) the legs.", specificMuscles: [
                "Tensor Fasciae Latae (TFL)"
            ]),
            MajorSeed(name: "Hip Flexors", info: "Front hip muscles that flex the hip (raise the knee).", specificMuscles: [
                "Iliopsoas (Psoas Major & Iliacus)", "Sartorius"
            ])
        ]
    }

    static var workoutCategoryNames: [String] {
        [
            "Push", "Pull", "Legs", "Upper Body", "Lower Body", "Full Body",
            "Chest", "Back", "Arms", "Abs/Core", "Shoulders", "Biceps", "Triceps", "Forearms"
        ]
    }

}
