//
//  Item.swift
//  identitybuilder
//
//  Created by ndrios on 10/8/25.
//

import Foundation
import SwiftData

// Legacy Item model for compatibility
@Model
final class Item {
    var timestamp: Date

    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
