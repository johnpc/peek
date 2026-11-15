import Combine
import UIKit

/// The last thing each saved computer's screen looked like, kept as a small
/// JPEG per host so the list shows which machine is which at a glance.
final class ThumbnailStore: ObservableObject {
    static let size = CGSize(width: 320, height: 200)

    @Published private(set) var images: [UUID: UIImage] = [:]
    private let directory: URL

    init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("thumbnails", isDirectory: true)
        self.directory = base
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        load()
    }

    func image(for id: UUID) -> UIImage? { images[id] }

    /// Downscale and store; the list updates immediately.
    func save(_ frame: CGImage, for id: UUID) {
        let image = ThumbnailStore.thumbnail(from: frame, fitting: Self.size)
        guard let data = image.jpegData(compressionQuality: 0.7) else { return }
        try? data.write(to: url(for: id), options: .atomic)
        images[id] = image
    }

    func remove(for id: UUID) {
        try? FileManager.default.removeItem(at: url(for: id))
        images[id] = nil
    }

    static func thumbnail(from frame: CGImage, fitting box: CGSize) -> UIImage {
        let source = CGSize(width: frame.width, height: frame.height)
        let scale = min(box.width / max(1, source.width), box.height / max(1, source.height), 1)
        let target = CGSize(width: max(1, (source.width * scale).rounded()), height: max(1, (source.height * scale).rounded()))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            UIImage(cgImage: frame).draw(in: CGRect(origin: .zero, size: target))
        }
    }

    private func url(for id: UUID) -> URL {
        directory.appendingPathComponent("\(id.uuidString).jpg")
    }

    private func load() {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for file in files where file.pathExtension == "jpg" {
            if let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent),
               let image = UIImage(contentsOfFile: file.path) {
                images[id] = image
            }
        }
    }
}
