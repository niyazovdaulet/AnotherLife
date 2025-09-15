//
//  DateFormatter+Extensions.swift
//  AnotherLife
//
//  Created by Daulet on 04/09/2025.
//

import Foundation

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let dateKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
