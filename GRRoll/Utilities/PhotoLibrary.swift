import Foundation
import Photos
import UIKit

// MARK: - 相册保存（本地，不上传）
final class PhotoLibrary {

    /// 保存图片到系统相册，并归入「GR ROLL」相簿
    static func save(_ image: UIImage,
                     completion: @escaping (Result<Void, Error>) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                completion(.failure(NSError(domain: "GRRoll", code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "需要相册权限才能保存"])))
                return
            }
            let album = Self.ensureAlbum()
            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetChangeRequest.creationRequestForAsset(from: image)
                if let album = album {
                    let change = PHAssetCollectionChangeRequest(for: album)
                    if let placeholder = req.placeholderForCreatedAsset {
                        change?.addAssets([placeholder] as NSArray)
                    }
                }
            }) { ok, err in
                DispatchQueue.main.async {
                    ok ? completion(.success(())) : completion(.failure(err ?? NSError()))
                }
            }
        }
    }

    /// 查找 / 创建 GR ROLL 相簿（同步）
    private static func ensureAlbum() -> PHAssetCollection? {
        let name = "GR ROLL"
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "localizedTitle == %@", name)
        if let existing = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: opts).firstObject {
            return existing
        }
        var localID: String?
        do {
            try PHPhotoLibrary.shared().performChangesAndWait {
                let req = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: name)
                localID = req.placeholderForCreatedAssetCollection.localIdentifier
            }
        } catch {
            return nil
        }
        guard let localID else { return nil }
        return PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [localID], options: nil).firstObject
    }
}
