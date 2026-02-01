import SwiftUI
import PhotosUI

struct ProfilePhotoSelector: View {
    @Binding var imageSelection: PhotosPickerItem?
    let avatarImage: AvatarImage?

    private let size: CGFloat = 280

    private let profileGradientColors: [Color] = [
        .purple, .blue, .purple,
        .blue, .purple, .blue,
        .purple, .blue, .purple
    ]

    var body: some View {
        PhotosPicker(selection: $imageSelection, matching: .images) {
            Group {
                if let avatarImage {
                    avatarImage.image
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack(alignment: .center) {
                        AnimatedMeshGradient(
                            colors: profileGradientColors,
                            animationStyle: .horizontalWave,
                            duration: 3.0
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
    }
}
