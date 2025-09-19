import Foundation

struct ExerciseTemplate {
    struct MajorShare {
        let name: String
        let share: Int
    }

    struct SpecificShare {
        let name: String
        let share: Int
    }

    let canonicalName: String
    let categories: [String]
    let majorShares: [MajorShare]
    let specificShares: [SpecificShare]
}

enum ExerciseTemplateProvider {
    static func template(for exerciseName: String) -> ExerciseTemplate? {
        let key = sanitize(exerciseName)
        if let direct = templates[key] {
            return direct
        }
        for (alias, templateKey) in aliasMap {
            if key.contains(alias) {
                return templates[templateKey]
            }
        }
        return nil
    }

    private static let templates: [String: ExerciseTemplate] = {
        var storage: [String: ExerciseTemplate] = [:]

        storage["barbell bench press"] = ExerciseTemplate(
            canonicalName: "Barbell Bench Press",
            categories: ["Push", "Chest", "Upper Body"],
            majorShares: [
                ExerciseTemplate.MajorShare(name: "Chest", share: 60),
                ExerciseTemplate.MajorShare(name: "Shoulders", share: 25),
                ExerciseTemplate.MajorShare(name: "Triceps", share: 15)
            ],
            specificShares: [
                ExerciseTemplate.SpecificShare(name: "Pectoralis Major", share: 54),
                ExerciseTemplate.SpecificShare(name: "Pectoralis Minor", share: 3),
                ExerciseTemplate.SpecificShare(name: "Serratus Anterior", share: 3),
                ExerciseTemplate.SpecificShare(name: "Anterior Deltoid", share: 23),
                ExerciseTemplate.SpecificShare(name: "Lateral Deltoid", share: 2),
                ExerciseTemplate.SpecificShare(name: "Triceps (Long Head)", share: 6),
                ExerciseTemplate.SpecificShare(name: "Triceps (Lateral Head)", share: 6),
                ExerciseTemplate.SpecificShare(name: "Triceps (Medial Head)", share: 3)
            ]
        )

        storage["back squat"] = ExerciseTemplate(
            canonicalName: "Back Squat",
            categories: ["Legs", "Lower Body"],
            majorShares: [
                ExerciseTemplate.MajorShare(name: "Quads", share: 45),
                ExerciseTemplate.MajorShare(name: "Glutes", share: 35),
                ExerciseTemplate.MajorShare(name: "Hamstrings", share: 15),
                ExerciseTemplate.MajorShare(name: "Abs/Core", share: 5)
            ],
            specificShares: [
                ExerciseTemplate.SpecificShare(name: "Rectus Femoris", share: 18),
                ExerciseTemplate.SpecificShare(name: "Vastus Lateralis", share: 12),
                ExerciseTemplate.SpecificShare(name: "Vastus Medialis", share: 9),
                ExerciseTemplate.SpecificShare(name: "Vastus Intermedius", share: 6),
                ExerciseTemplate.SpecificShare(name: "Gluteus Maximus", share: 25),
                ExerciseTemplate.SpecificShare(name: "Gluteus Medius", share: 7),
                ExerciseTemplate.SpecificShare(name: "Gluteus Minimus", share: 3),
                ExerciseTemplate.SpecificShare(name: "Biceps Femoris", share: 8),
                ExerciseTemplate.SpecificShare(name: "Semimembranosus", share: 4),
                ExerciseTemplate.SpecificShare(name: "Semitendinosus", share: 3),
                ExerciseTemplate.SpecificShare(name: "Rectus Abdominis", share: 2),
                ExerciseTemplate.SpecificShare(name: "Transversus Abdominis", share: 2),
                ExerciseTemplate.SpecificShare(name: "External Oblique", share: 1)
            ]
        )

        storage["deadlift"] = ExerciseTemplate(
            canonicalName: "Deadlift",
            categories: ["Pull", "Full Body", "Back"],
            majorShares: [
                ExerciseTemplate.MajorShare(name: "Back", share: 40),
                ExerciseTemplate.MajorShare(name: "Hamstrings", share: 25),
                ExerciseTemplate.MajorShare(name: "Glutes", share: 20),
                ExerciseTemplate.MajorShare(name: "Forearms", share: 10),
                ExerciseTemplate.MajorShare(name: "Abs/Core", share: 5)
            ],
            specificShares: [
                ExerciseTemplate.SpecificShare(name: "Latissimus Dorsi", share: 12),
                ExerciseTemplate.SpecificShare(name: "Trapezius (Middle)", share: 8),
                ExerciseTemplate.SpecificShare(name: "Trapezius (Lower)", share: 5),
                ExerciseTemplate.SpecificShare(name: "Erector Spinae", share: 15),
                ExerciseTemplate.SpecificShare(name: "Biceps Femoris", share: 8),
                ExerciseTemplate.SpecificShare(name: "Semimembranosus", share: 9),
                ExerciseTemplate.SpecificShare(name: "Semitendinosus", share: 8),
                ExerciseTemplate.SpecificShare(name: "Gluteus Maximus", share: 15),
                ExerciseTemplate.SpecificShare(name: "Gluteus Medius", share: 3),
                ExerciseTemplate.SpecificShare(name: "Gluteus Minimus", share: 2),
                ExerciseTemplate.SpecificShare(name: "Brachioradialis", share: 10),
                ExerciseTemplate.SpecificShare(name: "Rectus Abdominis", share: 3),
                ExerciseTemplate.SpecificShare(name: "Transversus Abdominis", share: 2)
            ]
        )

        storage["overhead press"] = ExerciseTemplate(
            canonicalName: "Overhead Press",
            categories: ["Push", "Shoulder", "Upper Body"],
            majorShares: [
                ExerciseTemplate.MajorShare(name: "Shoulders", share: 55),
                ExerciseTemplate.MajorShare(name: "Triceps", share: 25),
                ExerciseTemplate.MajorShare(name: "Chest", share: 10),
                ExerciseTemplate.MajorShare(name: "Abs/Core", share: 10)
            ],
            specificShares: [
                ExerciseTemplate.SpecificShare(name: "Anterior Deltoid", share: 35),
                ExerciseTemplate.SpecificShare(name: "Lateral Deltoid", share: 15),
                ExerciseTemplate.SpecificShare(name: "Posterior Deltoid", share: 5),
                ExerciseTemplate.SpecificShare(name: "Triceps (Long Head)", share: 10),
                ExerciseTemplate.SpecificShare(name: "Triceps (Lateral Head)", share: 8),
                ExerciseTemplate.SpecificShare(name: "Triceps (Medial Head)", share: 7),
                ExerciseTemplate.SpecificShare(name: "Pectoralis Major", share: 7),
                ExerciseTemplate.SpecificShare(name: "Pectoralis Minor", share: 3),
                ExerciseTemplate.SpecificShare(name: "Rectus Abdominis", share: 4),
                ExerciseTemplate.SpecificShare(name: "External Oblique", share: 3),
                ExerciseTemplate.SpecificShare(name: "Internal Oblique", share: 3)
            ]
        )

        storage["pull up"] = ExerciseTemplate(
            canonicalName: "Pull-Up",
            categories: ["Pull", "Back", "Upper Body"],
            majorShares: [
                ExerciseTemplate.MajorShare(name: "Back", share: 50),
                ExerciseTemplate.MajorShare(name: "Biceps", share: 25),
                ExerciseTemplate.MajorShare(name: "Forearms", share: 15),
                ExerciseTemplate.MajorShare(name: "Abs/Core", share: 10)
            ],
            specificShares: [
                ExerciseTemplate.SpecificShare(name: "Latissimus Dorsi", share: 25),
                ExerciseTemplate.SpecificShare(name: "Trapezius (Upper)", share: 5),
                ExerciseTemplate.SpecificShare(name: "Trapezius (Middle)", share: 7),
                ExerciseTemplate.SpecificShare(name: "Rhomboid Major", share: 5),
                ExerciseTemplate.SpecificShare(name: "Biceps Brachii", share: 18),
                ExerciseTemplate.SpecificShare(name: "Brachialis", share: 7),
                ExerciseTemplate.SpecificShare(name: "Brachioradialis", share: 15),
                ExerciseTemplate.SpecificShare(name: "Rectus Abdominis", share: 4),
                ExerciseTemplate.SpecificShare(name: "External Oblique", share: 3),
                ExerciseTemplate.SpecificShare(name: "Internal Oblique", share: 3)
            ]
        )

        return storage
    }()

    private static let aliasMap: [(alias: String, templateKey: String)] = [
        ("bench press", "barbell bench press"),
        ("flat bench", "barbell bench press"),
        ("squat", "back squat"),
        ("back squat", "back squat"),
        ("deadlift", "deadlift"),
        ("deadlifts", "deadlift"),
        ("overhead press", "overhead press"),
        ("military press", "overhead press"),
        ("pull up", "pull up"),
        ("pull ups", "pull up")
    ]

    private static func sanitize(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined(separator: " ")
            .split(separator: " ")
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
