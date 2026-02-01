import SwiftUI

/// A reusable animated mesh gradient that can be applied as a background to any shape
/// Usage: .background(AnimatedMeshGradient().clipShape(Circle()))
struct AnimatedMeshGradient: View {
    enum AnimationStyle {
        case verticalWave
        case horizontalWave
    }

    let colors: [Color]
    let animationStyle: AnimationStyle
    let duration: Double

    @State private var animationOffset: CGFloat = 0

    /// Creates an animated mesh gradient
    /// - Parameters:
    ///   - colors: Array of 9 colors for the 3x3 mesh grid
    ///   - animationStyle: Type of animation (vertical or horizontal wave)
    ///   - duration: Animation duration in seconds (defaults to 3.0)
    init(
        colors: [Color],
        animationStyle: AnimationStyle,
        duration: Double = 3.0
    ) {
        self.colors = colors
        self.animationStyle = animationStyle
        self.duration = duration
    }

    private var meshPoints: [SIMD2<Float>] {
        switch animationStyle {
        case .verticalWave:
            let yOffset = Float(animationOffset * 0.2)
            return [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5 + yOffset], [0.5, 0.5 - yOffset], [1, 0.5 + yOffset],
                [0, 1], [0.5, 1], [1, 1]
            ]
        case .horizontalWave:
            let xOffset = Float(animationOffset * 0.5)
            return [
                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                [0.0, 0.5], [xOffset, 0.5], [1.0, 0.5],
                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
            ]
        }
    }

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: meshPoints,
            colors: colors
        )
        .onAppear {
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                animationOffset = 1.0
            }
        }
    }
}

