//
//  AvatarImage.swift
//  boop-ios
//
//

import SwiftUI

/// Transferable image type for PhotosPicker
/// Holds both the SwiftUI Image for display and raw Data for upload
struct AvatarImage: Transferable, Equatable {
    let image: Image
    let data: Data
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            guard let image = AvatarImage(data: data) else {
                throw TransferError.importFailed
            }
            return image
        }
    }
}

extension AvatarImage {
    /// Maximum dimension for avatar images (width or height)
    private static let maxDimension: CGFloat = 512
    /// JPEG compression quality (0.0 to 1.0)
    private static let compressionQuality: CGFloat = 0.8
    
    init?(data: Data) {
        guard let uiImage = UIImage(data: data) else {
            return nil
        }
        
        // Resize and compress the image
        let resizedImage = Self.resizeImage(uiImage, maxDimension: Self.maxDimension)
        
        // Convert to JPEG data with compression
        guard let compressedData = resizedImage.jpegData(compressionQuality: Self.compressionQuality) else {
            return nil
        }
        
        let image = Image(uiImage: resizedImage)
        self.init(image: image, data: compressedData)
    }
    
    /// Resizes an image to fit within maxDimension while maintaining aspect ratio
    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = CGSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        
        // Resize the image
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        
        return resizedImage
    }
}

enum TransferError: Error {
    case importFailed
}
