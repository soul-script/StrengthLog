import SwiftUI

struct AppIcon: View {
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "1A2980"), Color(hex: "26D0CE")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Dumbbell design
            HStack(spacing: 12) {
                // Left weight
                WeightPlate()
                
                // Bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 80, height: 12)
                
                // Right weight
                WeightPlate()
            }
            
            // App name at bottom
            VStack {
                Spacer()
                Text("STRENGTH LOG")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 40)
            }
        }
        .frame(width: 1024, height: 1024)
    }
}

struct WeightPlate: View {
    var body: some View {
        ZStack {
            // Outer ring
            Circle()
                .fill(Color.gray.opacity(0.8))
                .frame(width: 120, height: 120)
            
            // Inner ring
            Circle()
                .fill(Color.black.opacity(0.7))
                .frame(width: 100, height: 100)
            
            // Center hole
            Circle()
                .fill(Color.white.opacity(0.9))
                .frame(width: 20, height: 20)
        }
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

// Helper extension to create colors from hex values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Preview for the app icon
struct AppIcon_Previews: PreviewProvider {
    static var previews: some View {
        AppIcon()
            .previewLayout(.fixed(width: 1024, height: 1024))
    }
} 