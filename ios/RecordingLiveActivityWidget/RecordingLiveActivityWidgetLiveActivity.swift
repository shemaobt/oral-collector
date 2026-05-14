//
//  RecordingLiveActivityWidgetLiveActivity.swift
//  RecordingLiveActivityWidget
//
//  Created by Henok Teixeira on 14/05/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RecordingLiveActivityWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RecordingLiveActivityWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RecordingLiveActivityWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RecordingLiveActivityWidgetAttributes {
    fileprivate static var preview: RecordingLiveActivityWidgetAttributes {
        RecordingLiveActivityWidgetAttributes(name: "World")
    }
}

extension RecordingLiveActivityWidgetAttributes.ContentState {
    fileprivate static var smiley: RecordingLiveActivityWidgetAttributes.ContentState {
        RecordingLiveActivityWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RecordingLiveActivityWidgetAttributes.ContentState {
         RecordingLiveActivityWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RecordingLiveActivityWidgetAttributes.preview) {
   RecordingLiveActivityWidgetLiveActivity()
} contentStates: {
    RecordingLiveActivityWidgetAttributes.ContentState.smiley
    RecordingLiveActivityWidgetAttributes.ContentState.starEyes
}
