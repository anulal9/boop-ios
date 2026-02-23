import SwiftUI
import PhotosUI

struct ProfilePhotoSelector: View {
    @Binding var imageSelection: PhotosPickerItem?
    let avatarImage: AvatarImage?

    private let size: CGFloat = 280
    private let cameraCircleSize: CGFloat = 70

    var body: some View {
        PhotosPicker(selection: $imageSelection, matching: .images) {
            Group {
                if let avatarImage {
                    // Show photo when selected
                    avatarImage.image
                        .resizable()
                        .scaledToFill()
                } else {
                    // Show icon when no photo
                    ZStack(alignment: .center) {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Circle()
                                    .stroke(Color.textPrimary.opacity(0.2), lineWidth: 2)
                            }

                        Image(systemName: "person.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.textPrimary.opacity(0.6))
                            .padding(60)
                    }
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                // Camera icon circle - only shown when photo is selected
                if avatarImage != nil {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay {
                                Circle()
                                    .stroke(Color.textPrimary.opacity(0.3), lineWidth: 1.5)
                            }

                        Image(systemName: "camera.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(.textPrimary)
                            .frame(width: 28, height: 28)
                    }
                    .frame(width: cameraCircleSize, height: cameraCircleSize)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                }
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
