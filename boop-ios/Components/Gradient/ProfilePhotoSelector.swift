import SwiftUI
import PhotosUI

struct ProfilePhotoSelector: View {
    @Binding var imageSelection: PhotosPickerItem?
    let avatarImage: AvatarImage?

    private let size: CGFloat = 280
    private let cameraCircleSize: CGFloat = 70

    private let profileGradientColors: [Color] = [
        .purple, .blue, .purple,
        .blue, .purple, .blue,
        .purple, .blue, .purple
    ]

    var body: some View {
        PhotosPicker(selection: $imageSelection, matching: .images) {
            Group {
                if let avatarImage {
                    // Show photo when selected
                    avatarImage.image
                        .resizable()
                        .scaledToFill()
                } else {
                    // Show gradient with person icon when no photo
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
                // Camera icon circle
                Group {
                    if avatarImage != nil {
                        // Gradient background when photo is present
                        ZStack {
                            AnimatedMeshGradient(
                                colors: profileGradientColors,
                                animationStyle: .horizontalWave,
                                duration: 3.0
                            )

                            Image(systemName: "camera.fill")
                                .resizable()
                                .scaledToFit()
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                        }
                    } else {
                        // Solid background when no photo
                        Circle()
                            .fill(Color.formBackgroundInactive)
                            .overlay {
                                Image(systemName: "camera.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white)
                                    .frame(width: 28, height: 28)
                            }
                    }
                }
                .frame(width: cameraCircleSize, height: cameraCircleSize)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            TapGesture().onEnded {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        )
    }
}
