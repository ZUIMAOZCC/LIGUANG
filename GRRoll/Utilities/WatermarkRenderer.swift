import UIKit

// MARK: - 水印渲染
/// 简约小字：可选理光日期戳 + GR 机型标记，不抢画面
struct WatermarkRenderer {

    struct Options {
        var showDate: Bool = true
        var showModel: Bool = true
        var modelName: String = "RICOH GR III"
        var date: Date = Date()
    }

    static func apply(to image: UIImage, options: Options) -> UIImage {
        let size = image.size
        let scale = image.scale
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = scale

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))

            let margin = size.width * 0.035
            let font = UIFont.monospacedSystemFont(ofSize: size.width * 0.026, weight: .medium)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor(white: 1.0, alpha: 0.85),
                .strokeColor: UIColor.black.withAlphaComponent(0.35),
                .strokeWidth: -2
            ]

            var lines: [String] = []
            if options.showDate {
                let df = DateFormatter()
                df.dateFormat = "yyyy.MM.dd"
                lines.append(df.string(from: options.date))
            }
            if options.showModel {
                lines.append(options.modelName)
            }
            guard !lines.isEmpty else { return }

            let lineHeight = font.lineHeight
            let total = CGFloat(lines.count) * lineHeight
            var y = size.height - margin - total
            for line in lines {
                let text = NSAttributedString(string: line, attributes: attrs)
                text.draw(at: CGPoint(x: margin, y: y))
                y += lineHeight
            }
        }
    }
}
