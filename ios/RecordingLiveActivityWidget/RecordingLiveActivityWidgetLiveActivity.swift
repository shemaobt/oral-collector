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

private struct LiveActivityData {
    let genre: String
    let subcategory: String
    let elapsedLabel: String
    let isPaused: Bool

    init(attributes: LiveActivitiesAppAttributes) {
        let defaults = sharedDefaults
        genre = defaults?.string(forKey: attributes.prefixedKey("genre")) ?? ""
        subcategory = defaults?.string(forKey: attributes.prefixedKey("subcategory")) ?? ""
        elapsedLabel = defaults?.string(forKey: attributes.prefixedKey("elapsedLabel")) ?? "00:00"
        let pausedRaw = defaults?.string(forKey: attributes.prefixedKey("isPaused")) ?? "false"
        isPaused = pausedRaw == "true"
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
        isPaused ? "Recording paused" : "Recording"
    }

    var compactIcon: String {
        isPaused ? "pause.fill" : "mic.fill"
    }
}

private struct StopButton: View {
    var compact: Bool = false

    var body: some View {
        Link(destination: stopURL) {
            Text("Stop")
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

struct RecordingLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveActivitiesAppAttributes.self) { context in
            let data = LiveActivityData(attributes: context.attributes)
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
                StopButton()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .environment(\.colorScheme, .light)
            .activityBackgroundTint(Brand.surface)
            .activitySystemActionForegroundColor(Brand.accent)
        } dynamicIsland: { context in
            let data = LiveActivityData(attributes: context.attributes)
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 8) {
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
                        Text(data.statusTitle)
                            .font(.headline)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    StopButton(compact: true)
                }
                DynamicIslandExpandedRegion(.bottom) {
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
            } compactLeading: {
                Image(systemName: data.compactIcon)
                    .foregroundStyle(Brand.accent)
            } compactTrailing: {
                Text(data.elapsedLabel)
                    .monospacedDigit()
                    .foregroundStyle(Brand.accent)
            } minimal: {
                Image(systemName: data.compactIcon)
                    .foregroundStyle(Brand.accent)
            }
            .keylineTint(Brand.accent)
        }
    }
}
