import SwiftUI
import PhotosUI

struct ProfilePhotoSelector: View {
    @Binding var imageSelection: PhotosPickerItem?
    let avatarImage: AvatarImage?

    @State private var animationProgress: Float = 0.0

    private let size: CGFloat = 280

    var body: some View {
        PhotosPicker(selection: $imageSelection, matching: .images) {
            Group {
                if let avatarImage {
                    avatarImage.image
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack(alignment: .center) {
                        MeshGradient(
                            width: 3,
                            height: 3,
                            points: [
                                [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                                [0.0, 0.5], [animationProgress, 0.5], [1.0, 0.5],
                                [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                            ],
                            colors: [
                                .purple, .blue, .purple,
                                .blue, .purple, .blue,
                                .purple, .blue, .purple
                            ]
                        )

                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.black.opacity(0.5))
                            .frame(width: size, height: size)
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(Color.formBackgroundInactive)
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "camera.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                animationProgress = 1.0
            }
        }
    }
}
