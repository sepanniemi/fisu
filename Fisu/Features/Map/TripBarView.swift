import SwiftUI

struct TripBarView: View {
    @Environment(TripRecorder.self) private var recorder
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            if recorder.state != .idle {
                activeBar
            } else {
                startBar
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 8, y: 2)
    }

    private var startBar: some View {
        Button {
            recorder.start()
        } label: {
            HStack {
                Image(systemName: "play.fill")
                Text("Start trip")
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundStyle(.green)
        }
    }

    private var activeBar: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.28)) { isExpanded.toggle() }
            } label: {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 9, height: 9)
                    Text("\(recorder.distanceKmFormatted) · \(recorder.durationFormatted)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
            }

            if isExpanded {
                Divider()
                HStack(spacing: 0) {
                    tripActionButton(
                        recorder.state == .recording ? "Pause" : "Resume",
                        icon: recorder.state == .recording ? "pause.fill" : "play.fill",
                        color: .green
                    ) {
                        if recorder.state == .recording { recorder.pause() } else { recorder.resume() }
                        isExpanded = false
                    }
                    Divider().frame(height: 40)
                    tripActionButton("Stop", icon: "stop.fill", color: .red) {
                        recorder.stop()
                        isExpanded = false
                    }
                }
            }
        }
    }

    private func tripActionButton(_ label: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title3)
                Text(label).font(.caption.weight(.semibold))
            }
            .foregroundStyle(color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
        }
    }
}
