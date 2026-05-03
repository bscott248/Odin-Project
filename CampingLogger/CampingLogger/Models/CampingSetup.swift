import Foundation
import SwiftData

@Model
final class CampingSetup {
    var id: UUID
    var name: String
    var cost: Double

    @Relationship(deleteRule: .nullify, inverse: \CampingTrip.setup)
    var trips: [CampingTrip]

    init(
        id: UUID = UUID(),
        name: String = "",
        cost: Double = 0,
        trips: [CampingTrip] = []
    ) {
        self.id = id
        self.name = name
        self.cost = cost
        self.trips = trips
    }

    var totalNights: Int {
        trips.reduce(0) { $0 + $1.nights }
    }

    var costPerNight: Double {
        totalNights > 0 ? cost / Double(totalNights) : 0
    }
}
