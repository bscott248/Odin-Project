import Foundation
import SwiftData

@Model
final class CampingTrip {
    var id: UUID
    var name: String
    var notes: String
    var latitude: Double
    var longitude: Double
    var locationName: String
    var startDate: Date
    var endDate: Date
    var rating: Int
    var photoData: [Data]
    var setup: CampingSetup?

    init(
        id: UUID = UUID(),
        name: String = "",
        notes: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        locationName: String = "",
        startDate: Date = .now,
        endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now)!,
        rating: Int = 0,
        photoData: [Data] = [],
        setup: CampingSetup? = nil
    ) {
        self.id = id
        self.name = name
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
        self.locationName = locationName
        self.startDate = startDate
        self.endDate = endDate
        self.rating = rating
        self.photoData = photoData
        self.setup = setup
    }

    var nights: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(0, days)
    }
}
