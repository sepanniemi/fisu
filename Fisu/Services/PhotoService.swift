import UIKit
import SwiftUI
import PhotosUI
import ImageIO

@Observable @MainActor
final class PhotoService {
    static let maxDimension: CGFloat = 1600
    static let thumbnailDimension: CGFloat = 200
    static let jpegQuality: CGFloat = 0.82

    func process(_ item: PhotosPickerItem) async -> (full: Data, thumb: Data)? {
        guard let raw = try? await item.loadTransferable(type: Data.self) else { return nil }
        let full = downsample(raw) ?? raw
        guard let thumb = thumbnail(from: full) else { return nil }
        return (full, thumb)
    }

    func captureFromCamera() -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }

    func process(uiImage: UIImage) -> (full: Data, thumb: Data)? {
        guard let raw = uiImage.jpegData(compressionQuality: Double(Self.jpegQuality)) else { return nil }
        let full = downsample(raw) ?? raw
        guard let thumb = thumbnail(from: full) else { return nil }
        return (full, thumb)
    }

    private func downsample(_ data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any]
        let w = props?[kCGImagePropertyPixelWidth] as? CGFloat ?? 0
        let h = props?[kCGImagePropertyPixelHeight] as? CGFloat ?? 0
        let maxDim = Self.maxDimension
        guard max(w, h) > maxDim else { return data }
        let scale = maxDim / max(w, h)
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: max(w, h) * scale,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return data }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: Double(Self.jpegQuality))
    }

    private func thumbnail(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let options: [CFString: Any] = [
            kCGImageSourceThumbnailMaxPixelSize: Self.thumbnailDimension,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
        ]
        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else { return nil }
        return UIImage(cgImage: cgImage).jpegData(compressionQuality: 0.75)
    }
}
