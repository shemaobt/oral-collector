import ActivityKit
import WidgetKit
import SwiftUI

struct LiveActivitiesAppAttributes: ActivityAttributes, Identifiable {
    public typealias LiveDeliveryData = ContentState

    public struct ContentState: Codable, Hashable {}

    var id = UUID()
}

extension LiveActivitiesAppAttributes {
    func prefixedKey(_ key: String) -> String {
        return "\(id)_\(key)"
    }
}

private let sharedDefaults = UserDefaults(suiteName: "group.com.shema.oralCollector")
private let stopURL = URL(string: "oralcollector://stop-recording")!

private enum Brand {
    static let accent = Color(red: 190.0 / 255.0, green: 74.0 / 255.0, blue: 1.0 / 255.0)
    static let surface = Color(red: 250.0 / 255.0, green: 244.0 / 255.0, blue: 232.0 / 255.0)
}

private enum LiveActivityKind {
    case recording
    case upload
}

private struct LiveActivityData {
    let kind: LiveActivityKind

    // Recording fields
    let genre: String
    let subcategory: String
    let elapsedLabel: String
    let isPaused: Bool

    // Upload fields
    let fileName: String
    let progressPercent: Int

    // Localized labels (resolved on the Dart side from AppLocalizations and
    // passed in via the App Group UserDefaults payload). Fall back to English
    // so the widget never blanks out if the Dart side forgets a key.
    let recordingStatusLabel: String
    let recordingPausedStatusLabel: String
    let uploadingStatusLabel: String
    let uploadingRecordingTitleLabel: String
    let stopActionLabel: String

    init(attributes: LiveActivitiesAppAttributes) {
        let defaults = sharedDefaults
        let rawKind = defaults?.string(forKey: attributes.prefixedKey("kind")) ?? "recording"
        kind = rawKind == "upload" ? .upload : .recording

        genre = defaults?.string(forKey: attributes.prefixedKey("genre")) ?? ""
        subcategory = defaults?.string(forKey: attributes.prefixedKey("subcategory")) ?? ""
        elapsedLabel = defaults?.string(forKey: attributes.prefixedKey("elapsedLabel")) ?? "00:00"
        let pausedRaw = defaults?.string(forKey: attributes.prefixedKey("isPaused")) ?? "false"
        isPaused = pausedRaw == "true"

        fileName = defaults?.string(forKey: attributes.prefixedKey("fileName")) ?? ""
        let progressRaw = defaults?.string(forKey: attributes.prefixedKey("progressPercent")) ?? "0"
        progressPercent = Int(progressRaw) ?? 0

        recordingStatusLabel = defaults?.string(forKey: attributes.prefixedKey("localizedRecordingStatus")) ?? "Recording"
        recordingPausedStatusLabel = defaults?.string(forKey: attributes.prefixedKey("localizedRecordingPausedStatus")) ?? "Recording paused"
        uploadingStatusLabel = defaults?.string(forKey: attributes.prefixedKey("localizedUploadingStatus")) ?? "Uploading"
        uploadingRecordingTitleLabel = defaults?.string(forKey: attributes.prefixedKey("localizedUploadingRecordingTitle")) ?? "Uploading recording"
        stopActionLabel = defaults?.string(forKey: attributes.prefixedKey("localizedStopAction")) ?? "Stop"
    }

    var detailLine: String {
        let g = genre.trimmingCharacters(in: .whitespaces)
        let s = subcategory.trimmingCharacters(in: .whitespaces)
        if g.isEmpty && s.isEmpty { return "" }
        if s.isEmpty { return g }
        if g.isEmpty { return s }
        return "\(g) · \(s)"
    }

    var statusTitle: String {
        switch kind {
        case .upload:
            return uploadingStatusLabel
        case .recording:
            return isPaused ? recordingPausedStatusLabel : recordingStatusLabel
        }
    }

    var compactIcon: String {
        switch kind {
        case .upload:
            return "arrow.up.circle.fill"
        case .recording:
            return isPaused ? "pause.fill" : "mic.fill"
        }
    }
}

private struct StopButton: View {
    let label: String
    var compact: Bool = false

    var body: some View {
        Link(destination: stopURL) {
            Text(label)
                .font(compact ? .subheadline : .headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, compact ? 12 : 16)
                .padding(.vertical, compact ? 6 : 9)
                .background(Brand.accent)
                .clipShape(Capsule())
        }
    }
}

private struct RecordingLockScreenView: View {
    let data: LiveActivityData

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            if data.isPaused {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Brand.accent)
                    .frame(width: 50)
            } else {
                Image("BrandLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 40)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(data.statusTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if !data.detailLine.isEmpty {
                    Text(data.detailLine)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(data.elapsedLabel)
                    .font(.footnote)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            StopButton(label: data.stopActionLabel)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

private struct UploadLockScreenView: View {
    let data: LiveActivityData

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Brand.accent)
                VStack(alignment: .leading, spacing: 2) {
                    Text(data.uploadingRecordingTitleLabel)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if !data.fileName.isEmpty {
                        Text(data.fileName)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text("\(data.progressPercent)%")
                    .font(.subheadline)
                    .monospacedDigit()
                    .fontWeight(.semibold)
                    .foregroundStyle(Brand.accent)
            }
            ProgressView(value: Double(data.progressPercent) / 100.0)
                .progressViewStyle(.linear)
                .tint(Brand.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct RecordingLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let data = LiveActivityData(attributes: context.attributes)
            Group {
                switch data.kind {
                case .upload:
                    UploadLockScreenView(data: data)
                case .recording:
                    RecordingLockScreenView(data: data)
                }
            }
            .environment(\.colorScheme, .light)
            .activityBackgroundTint(Brand.surface)
            .activitySystemActionForegroundColor(Brand.accent)
        } dynamicIsland: { context in
            let data = LiveActivityData(attributes: context.attributes)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
                        switch data.kind {
                        case .upload:
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(Brand.accent)
                        case .recording:
                            if data.isPaused {
                                Image(systemName: "pause.circle.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(Brand.accent)
                            } else {
                                Image("BrandLogo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 30, height: 24)
                            }
                        }
                        Text(data.statusTitle)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    switch data.kind {
                    case .upload:
                        Text("\(data.progressPercent)%")
                            .font(.headline)
                            .monospacedDigit()
                            .foregroundStyle(Brand.accent)
                    case .recording:
                        StopButton(label: data.stopActionLabel, compact: true)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    switch data.kind {
                    case .upload:
                        ProgressView(value: Double(data.progressPercent) / 100.0)
                            .progressViewStyle(.linear)
                            .tint(Brand.accent)
                    case .recording:
                        HStack {
                            if !data.detailLine.isEmpty {
                                Text(data.detailLine)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(data.elapsedLabel)
                                .font(.footnote)
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: data.compactIcon)
                    .foregroundStyle(Brand.accent)
            } compactTrailing: {
                switch data.kind {
                case .upload:
                    Text("\(data.progressPercent)%")
                        .monospacedDigit()
                        .foregroundStyle(Brand.accent)
                case .recording:
                    Text(data.elapsedLabel)
                        .monospacedDigit()
                        .foregroundStyle(Brand.accent)
                }
            } minimal: {
                Image(systemName: data.compactIcon)
                    .foregroundStyle(Brand.accent)
            }
            .keylineTint(Brand.accent)
        }
    }
}
