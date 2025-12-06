//
//  Item.swift
//  Daily
//
//  Created by Aaditya Srivastava on 06/12/25.
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
