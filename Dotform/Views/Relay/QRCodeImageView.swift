import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeImageView: View {
    let string: String
    var size: CGFloat = 240

    var body: some View {
        Group {
            if let image = generateQR(from: string) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .accessibilityLabel("QR-код для спаривания")
            } else {
                Text("Не удалось создать QR")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func generateQR(from string: String) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
