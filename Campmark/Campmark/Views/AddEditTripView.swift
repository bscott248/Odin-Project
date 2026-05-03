import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import PhotosUI

struct AddEditTripView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CampingSetup.name) private var setups: [CampingSetup]

    var trip: CampingTrip?

    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var startDate: Date = .now
    @State private var endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: .now)!
    @State private var rating: Int = 0
    @State private var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @State private var locationName: String = ""
    @State private var photoData: [Data] = []
    @State private var selectedSetup: CampingSetup? = nil

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var isReverseGeocoding = false
    @State private var saveError: String? = nil
    @State private var locationManager = CLLocationManager()
    @State private var locationDelegate: LocationDelegate? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Campsite") {
                    TextField("Campsite name", text: $name)
                }

                Section("Location") {
                    MapPickerView(coordinate: $coordinate) { newCoord in
                        reverseGeocode(newCoord)
                    }
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .listRowInsets(EdgeInsets())

                    HStack {
                        if isReverseGeocoding {
                            ProgressView()
                                .padding(.trailing, 4)
                        }
                        Text(locationName.isEmpty ? "Drag pin to set location" : locationName)
                            .foregroundStyle(locationName.isEmpty ? .secondary : .primary)
                            .font(.footnote)
                    }

                    Button("Use My Location") {
                        requestCurrentLocation()
                    }
                }

                Section("Dates") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .date)
                    DatePicker("End", selection: $endDate, in: startDate..., displayedComponents: .date)
                    let nights = max(0, Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0)
                    Text("\(nights) night\(nights == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }

                Section("Rating") {
                    StarRatingView(rating: $rating)
                }

                if !setups.isEmpty {
                    Section("Setup") {
                        Picker("Setup", selection: $selectedSetup) {
                            Text("None").tag(Optional<CampingSetup>.none)
                            ForEach(setups) { setup in
                                Text(setup.name).tag(Optional(setup))
                            }
                        }
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                Section("Photos") {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        Label("Add Photos", systemImage: "photo.badge.plus")
                    }

                    if !photoData.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(photoData.enumerated()), id: \.offset) { index, data in
                                    if let uiImage = UIImage(data: data) {
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                            Button {
                                                photoData.remove(at: index)
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundStyle(.white)
                                                    .background(
                                                        Color.black.opacity(0.5)
                                                            .clipShape(Circle())
                                                    )
                                            }
                                            .padding(2)
                                        }
                                    }
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8))
                    }
                }

                if let error = saveError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle(trip == nil ? "New Trip" : "Edit Trip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: selectedPhotos) { _, newValue in
                loadPhotos(newValue)
            }
            .onAppear {
                populateFields()
                setupLocationManager()
            }
        }
    }

    private func populateFields() {
        guard let trip else { return }
        name = trip.name
        notes = trip.notes
        startDate = trip.startDate
        endDate = trip.endDate
        rating = trip.rating
        coordinate = CLLocationCoordinate2D(latitude: trip.latitude, longitude: trip.longitude)
        locationName = trip.locationName
        photoData = trip.photoData
        selectedSetup = trip.setup
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }
        guard endDate >= startDate else {
            saveError = "End date must be on or after start date."
            return
        }
        saveError = nil

        if let trip {
            trip.name = trimmedName
            trip.notes = notes
            trip.startDate = startDate
            trip.endDate = endDate
            trip.rating = rating
            trip.latitude = coordinate.latitude
            trip.longitude = coordinate.longitude
            trip.locationName = locationName
            trip.photoData = photoData
            trip.setup = selectedSetup
        } else {
            let newTrip = CampingTrip(
                name: trimmedName,
                notes: notes,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                locationName: locationName,
                startDate: startDate,
                endDate: endDate,
                rating: rating,
                photoData: photoData,
                setup: selectedSetup
            )
            modelContext.insert(newTrip)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "Failed to save: \(error.localizedDescription)"
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        isReverseGeocoding = true
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        geocoder.reverseGeocodeLocation(location) { placemarks, _ in
            DispatchQueue.main.async {
                isReverseGeocoding = false
                if let placemark = placemarks?.first {
                    var parts: [String] = []
                    if let n = placemark.name { parts.append(n) }
                    if let area = placemark.administrativeArea { parts.append(area) }
                    if let country = placemark.country { parts.append(country) }
                    locationName = parts.joined(separator: ", ")
                }
            }
        }
    }

    private func setupLocationManager() {
        let delegate = LocationDelegate { location in
            self.coordinate = location.coordinate
            self.reverseGeocode(location.coordinate)
        }
        locationDelegate = delegate
        locationManager.delegate = delegate
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    private func requestCurrentLocation() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        case .denied, .restricted:
            saveError = "Location access denied. Enable it in Settings > Privacy > Location Services."
        @unknown default:
            break
        }
    }

    private func loadPhotos(_ items: [PhotosPickerItem]) {
        Task {
            var newData: [Data] = []
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data),
                   let jpegData = uiImage.jpegData(compressionQuality: 0.8) {
                    newData.append(jpegData)
                }
            }
            await MainActor.run {
                photoData.append(contentsOf: newData)
                selectedPhotos = []
            }
        }
    }
}

final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    private let onLocation: (CLLocation) -> Void

    init(onLocation: @escaping (CLLocation) -> Void) {
        self.onLocation = onLocation
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        onLocation(loc)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
