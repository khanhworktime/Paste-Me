//
//  Item.swift
//  PasteMe
//
//  Created by Krist Dev on 20/1/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
