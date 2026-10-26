import Photos
import SwiftUI

// MARK: - 相册（GR ROLL 相簿 + 导入）
struct LibraryView: View {
    @State private var assets: [PHAsset] = []
    @State private var showImport = false
    @State private var editTarget: UIImage? = nil
    @State private var gridImage: UIImage? = nil

    private let imageManager = PHCachingImageManager()

    var body: some View {
        NavigationView {
            Group {
                if assets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 40)).foregroundColor(Theme.textSecondary)
                        Text("还没有 GR ROLL 作品").font(TypeStyle.body).foregroundColor(Theme.textSecondary)
                        Button { showImport = true } label: {
                            Text("从相册导入").foregroundColor(Theme.accent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.background)
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 4) {
                            ForEach(assets, id: \.localIdentifier) { asset in
                                AssetCell(asset: asset, manager: imageManager) {
                                    loadFull(asset)
                                }
                            }
                        }
                        .padding(4)
                    }
                    .background(Theme.background)
                }
            }
            .navigationTitle("相册")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showImport = true } label: {
                        Image(systemName: "plus").foregroundColor(Theme.accent)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear(perform: loadAssets)
        .sheet(isPresented: $showImport) {
            ImagePicker { img in
                if let img { editTarget = img }
            }
        }
        .fullScreenCover(item: editBinding) { item in
            EditorView(original: item.image, look: .default, params: .default, ratio: .r3x2, source: .library)
        }
    }

    private var editBinding: Binding<EditableImage?> {
        Binding(get: { editTarget.map { EditableImage(image: $0) } },
                set: { editTarget = $0?.image })
    }

    private func loadAssets() {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let result: PHFetchResult<PHAsset>
        if let album = GRRollAlbum {
            result = PHAsset.fetchAssets(in: album, options: opts)
        } else {
            result = PHAsset.fetchAssets(with: .image, options: opts)
        }
        var arr: [PHAsset] = []
        result.enumerateObjects { a, _, _ in arr.append(a) }
        assets = arr
    }

    private var GRRollAlbum: PHAssetCollection? {
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "localizedTitle == %@", "GR ROLL")
        return PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: opts).firstObject
    }

    private func loadFull(_ asset: PHAsset) {
        let opts = PHImageRequestOptions()
        opts.isSynchronous = false
        opts.deliveryMode = .highQualityFormat
        imageManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: opts) { img, _ in
            if let img { DispatchQueue.main.async { editTarget = img } }
        }
    }
}

private struct AssetCell: View {
    let asset: PHAsset
    let manager: PHCachingImageManager
    let onTap: () -> Void
    @State private var thumb: UIImage? = nil

    var body: some View {
        Button(action: onTap) {
            Group {
                if let thumb {
                    Image(uiImage: thumb).resizable().scaledToFill()
                } else {
                    Color(Theme.surface)
                }
            }
            .frame(width: 110, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .onAppear { request() }
    }

    private func request() {
        let size = CGSize(width: 220, height: 220)
        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { img, _ in
            if let img { DispatchQueue.main.async { thumb = img } }
        }
    }
}

private struct EditableImage: Identifiable {
    let id = UUID(); let image: UIImage
}
