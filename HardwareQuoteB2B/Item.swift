//
//  Item.swift
//  HardwareQuoteB2B
//
//  Created by Diego Arturo Aragon Murillo on 17/10/26.
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
