import SwiftUI

struct AppIconPreviewView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Preview")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            AppIcon()
                .frame(width: 300, height: 300)
                .clipShape(RoundedRectangle(cornerRadius: 60))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            
            Text("StrengthLog App Icon")
                .font(.title2)
            
            Text("To use this icon in your app, take a screenshot and add it to your Xcode project's Assets catalog.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    AppIconPreviewView()
} 