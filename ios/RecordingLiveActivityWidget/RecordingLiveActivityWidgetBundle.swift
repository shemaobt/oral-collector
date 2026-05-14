//
//  RecordingLiveActivityWidgetBundle.swift
//  RecordingLiveActivityWidget
//
//  Created by Henok Teixeira on 14/05/26.
//

import WidgetKit
import SwiftUI

@main
struct RecordingLiveActivityWidgetBundle: WidgetBundle {
    var body: some Widget {
        RecordingLiveActivityWidget()
        RecordingLiveActivityWidgetControl()
        RecordingLiveActivityWidgetLiveActivity()
    }
}
