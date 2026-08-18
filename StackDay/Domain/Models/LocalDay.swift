//
//  LocalDay.swift
//  StackDay
//

import Foundation

struct LocalDay: Equatable, Hashable, Codable {
    let year: Int
    let month: Int
    let day: Int

    init(year: Int, month: Int, day: Int) throws {
        let calendar = Self.gregorianCalendar(timeZone: .gmt)
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else {
            throw LocalDayError.invalidDate
        }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year,
              resolved.month == month,
              resolved.day == day
        else {
            throw LocalDayError.invalidDate
        }

        self.year = year
        self.month = month
        self.day = day
    }

    func addingDays(_ value: Int) throws -> LocalDay {
        let calendar = Self.gregorianCalendar(timeZone: .gmt)
        let components = DateComponents(year: year, month: month, day: day)
        guard let date = calendar.date(from: components) else {
            throw LocalDayError.conversionFailed
        }
        guard let result = calendar.date(byAdding: .day, value: value, to: date) else {
            throw LocalDayError.arithmeticFailed
        }
        let resolved = calendar.dateComponents([.year, .month, .day], from: result)

        guard let year = resolved.year,
              let month = resolved.month,
              let day = resolved.day
        else {
            throw LocalDayError.conversionFailed
        }

        return try LocalDay(year: year, month: month, day: day)
    }

    private static func gregorianCalendar(timeZone: TimeZone) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar
    }
}

// MARK: - Date Conversion

extension LocalDay {
    init(date: Date, timeZone: TimeZone) throws {
        let calendar = Self.gregorianCalendar(timeZone: timeZone)
        let components = calendar.dateComponents(
            [.year, .month, .day],
            from: date
        )
        guard let year = components.year,
              let month = components.month,
              let day = components.day
        else {
            throw LocalDayError.conversionFailed
        }
        
        try self.init(year: year, month: month, day: day)
    }
    
    func startDate(in timeZone: TimeZone) throws -> Date {
        let calendar = Self.gregorianCalendar(timeZone: timeZone)
        let components = DateComponents(
            year: year,
            month: month,
            day: day
        )
        guard let date = calendar.date(from: components) else {
            throw LocalDayError.conversionFailed
        }

        return date
    }
}

// MARK: - Comparable

extension LocalDay: Comparable {
    static func < (lhs: LocalDay, rhs: LocalDay) -> Bool {
        if lhs.year != rhs.year {
            return lhs.year < rhs.year
        }
        if lhs.month != rhs.month {
            return lhs.month < rhs.month
        }
        return lhs.day < rhs.day
    }
}

// MARK: - Error

enum LocalDayError: Error, Equatable {
    case invalidDate
    case conversionFailed
    case arithmeticFailed
}
