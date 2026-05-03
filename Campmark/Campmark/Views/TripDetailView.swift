import SwiftUI
import MapKit

struct TripDetailView: View {
    let trip: CampingTrip
    @State private var showEditSheet = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                mapSection
                    .frame(height: 220)

                VStack(alignment: .leading, spacing: 16) {
                    infoSection

                    Divider()

                    if trip.rating > 0 {
                        StarRatingReadOnly(rating: trip.rating)
                    }

                    if !trip.notes.isEmpty {
                        Divider()
                        Text("Notes")
                            .font(.headline)
                        Text(trip.notes)
                            .font(.body)
                    }

                    if !trip.photoData.isEmpty {
                        Divider()
                        Text("Photos")
                            .font(.headline)
                        photosSection
                    }
                }
                .padding()
            }
        }
        .navigationTitle(trip.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            AddEditTripView(trip: trip)
        }
    }

    @ViewBuilder
    private var mapSection: some View {
        let coord = CLLocationCoordinate2D(latitude: trip.latitude, longitude: trip.longitude)
        Map(initialPosition: .region(MKCoordinateRegion(
            center: coord,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        ))) {
            Marker(trip.name, coordinate: coord)
                .tint(.green)
        }
        .disabled(true)
    }

    @ViewBuilder
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !trip.locationName.isEmpty {
                Label(trip.locationName, systemImage: "mappin.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Label(
                "\(Self.dateFormatter.string(from: trip.startDate)) – \(Self.dateFormatter.string(from: trip.endDate))",
                systemImage: "calendar"
            )
            .font(.subheadline)

            let nights = trip.nights
            Label(
                "\(nights) night\(nights == 1 ? "" : "s")",
                systemImage: "moon.stars.fill"
            )
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if let setup = trip.setup {
                Label(setup.name, systemImage: "backpack.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var photosSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(trip.photoData.enumerated()), id: \.offset) { _, data in
                    if let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 160, height: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }
}
