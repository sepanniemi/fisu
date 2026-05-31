import SwiftUI

struct CatchOverlayCard: View {
    let entry: Catch
    let onDismiss: () -> Void
    let onOpenDetail: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(FishSpeciesCatalog.color(for: entry.speciesCode))
                            .frame(width: 12, height: 12)
                        Text(entry.speciesDisplayName)
                            .font(.headline)
                    }
                    Text(DateFormatter.fiDateTime.string(from: entry.timestamp))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let size = entry.sizeDisplay {
                        Text(size)
                            .font(.subheadline.weight(.medium))
                            .padding(.top, 4)
                    }
                }
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)

            Divider()

            Button(action: onOpenDetail) {
                HStack {
                    Text("Open full details")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                }
                .foregroundStyle(.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
    }
}
