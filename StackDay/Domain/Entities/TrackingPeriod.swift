import Foundation

struct TrackingPeriod: Equatable {
    let startedOn: LocalDay
    private(set) var endedOn: LocalDay?

    init(startedOn: LocalDay, endedOn: LocalDay? = nil) throws {
        if let endedOn, endedOn < startedOn {
            throw TrackingPeriodError.endsBeforeStart
        }
        self.startedOn = startedOn
        self.endedOn = endedOn
    }

    func contains(_ day: LocalDay) -> Bool {
        day >= startedOn && (endedOn.map { day <= $0 } ?? true)
    }

    mutating func end(on day: LocalDay) throws {
        guard day >= startedOn else { throw TrackingPeriodError.endsBeforeStart }
        guard endedOn == nil else { throw TrackingPeriodError.alreadyEnded }
        endedOn = day
    }

    mutating func reopen() throws {
        guard endedOn != nil else { throw TrackingPeriodError.alreadyOpen }
        endedOn = nil
    }
}

enum TrackingPeriodError: Error, Equatable {
    case endsBeforeStart
    case alreadyEnded
    case alreadyOpen
}
