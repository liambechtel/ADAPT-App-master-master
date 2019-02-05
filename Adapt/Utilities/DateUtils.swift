//
//  DateUtility.swift
//  Adapt
//
//  Created by Timmy Gouin on 3/20/18.
//  Copyright © 2018 Timmy Gouin. All rights reserved.
//

import Foundation

class DateUtils {
    static var dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    static var dateFormat2 = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    static func parseMySQLDate(date: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateUtils.dateFormat
        if let parsed = dateFormatter.date(from: date) {
            return parsed
        }
        return nil
    }
    
    static func getMySQLDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = DateUtils.dateFormat2
        return dateFormatter.string(from: date)
    }
}
