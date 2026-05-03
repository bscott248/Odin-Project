import SwiftUI
import SwiftData

struct TripListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CampingTrip.startDate, order: .reverse) private var trips: [CampingTrip]

    @State private var showAddSheet = false

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        NavigationStack {
            Group {
                if trips.isEmpty {
                    ContentUnavailableView(
                        "No Trips Yet",
                        systemImage: "tent.fill",
                        description: Text("Tap + to log your first camping trip.")
                    )
                } else {
                    List {
                        ForEach(trips) { trip in
                            NavigationLink(destination: TripDetailView(trip: trip)) {
                                TripRowView(trip: trip)
                            }
                        }
                        .onDelete(perform: deleteTrips)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Camping Trips")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                if !trips.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        EditButton()
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddEditTripView()
            }
        }
    }

    private func deleteTrips(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(trips[index])
        }
        try? modelContext.save()
    }
}

private struct TripRowView: View {
    let trip: CampingTrip

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trip.name)
                .font(.headline)

            HStack(spacing: 4) {
                Text(Self.dateFormatter.string(from: trip.startDate))
                Text("–")
                Text(Self.dateFormatter.string(from: trip.endDate))
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            HStack {
                let nights = trip.nights
                Text("\(nights) night\(nights == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                if let setupName = trip.setup?.name {
                    Text("· \(setupName)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Spacer()

                if trip.rating > 0 {
                    StarRatingReadOnly(rating: trip.rating)
                        .scaleEffect(0.7, anchor: .trailing)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
