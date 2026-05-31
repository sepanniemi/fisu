import SwiftUI
import UIKit

struct CatchRowView: View {
    let entry: Catch
    let isPersonalBest: Bool

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let data = entry.thumbnailData, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(FishSpeciesCatalog.color(for: entry.speciesCode).opacity(0.2))
                        .overlay(
                            Image(systemName: "fish")
                                .foregroundStyle(FishSpeciesCatalog.color(for: entry.speciesCode))
                        )
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(FishSpeciesCatalog.color(for: entry.speciesCode))
                        .frame(width: 9, height: 9)
                    Text(entry.speciesDisplayName)
                        .font(.subheadline.weight(.bold))
                    if let size = entry.sizeDisplay {
                        Text("·")
                            .foregroundStyle(.secondary)
                        Text(size)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Text("\(DateFormatter.fiDateTime.string(from: entry.timestamp))\(entry.trip?.title.map { " · \($0)" } ?? "")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isPersonalBest {
                Text("🏆")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.yellow.opacity(0.25), in: Capsule())
            }
        }
    }
}
