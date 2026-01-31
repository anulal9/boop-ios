import SwiftUI

struct AnimatedTextFieldMeshGradient: View {
    @State private var animationOffset: CGFloat = 0

    private var meshPoints: [SIMD2<Float>] {
        let yOffset = Float(animationOffset * 0.2)
        return [
            [0, 0], [0.5, 0], [1, 0],
            [0, 0.5 + yOffset], [0.5, 0.5 - yOffset], [1, 0.5 + yOffset],
            [0, 1], [0.5, 1], [1, 1]
        ]
    }

    private var meshColors: [Color] {
        [
            .purple.opacity(0.6), .blue.opacity(0.6), .cyan.opacity(0.6),
            .pink.opacity(0.6), .indigo.opacity(0.7), .teal.opacity(0.6),
            .purple.opacity(0.6), .blue.opacity(0.6), .cyan.opacity(0.6)
        ]
    }

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: meshPoints,
            colors: meshColors
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animationOffset = 1.0
            }
        }
    }
}
