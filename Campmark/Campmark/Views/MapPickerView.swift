import SwiftUI
import MapKit
import CoreLocation

final class MapPickerCoordinator: NSObject, MKMapViewDelegate {
    var parent: MapPickerView

    init(_ parent: MapPickerView) {
        self.parent = parent
    }

    func mapView(
        _ mapView: MKMapView,
        annotationView view: MKAnnotationView,
        didChange newState: MKAnnotationView.DragState,
        fromOldState oldState: MKAnnotationView.DragState
    ) {
        if newState == .ending || newState == .canceling {
            guard let coord = view.annotation?.coordinate else { return }
            DispatchQueue.main.async {
                self.parent.coordinate = coord
                self.parent.onCoordinateChanged(coord)
            }
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let reuseId = "DraggablePin"
        let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
            as? MKMarkerAnnotationView
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView.isDraggable = true
        pinView.canShowCallout = false
        pinView.markerTintColor = .systemGreen
        return pinView
    }
}

struct MapPickerView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    var onCoordinateChanged: (CLLocationCoordinate2D) -> Void

    func makeCoordinator() -> MapPickerCoordinator {
        MapPickerCoordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)

        let region = MKCoordinateRegion(
            center: coordinate,
            latitudinalMeters: 2000,
            longitudinalMeters: 2000
        )
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        guard let annotation = mapView.annotations
            .first(where: { !($0 is MKUserLocation) }) as? MKPointAnnotation
        else { return }

        let delta = abs(annotation.coordinate.latitude - coordinate.latitude)
                  + abs(annotation.coordinate.longitude - coordinate.longitude)
        if delta > 0.00001 {
            annotation.coordinate = coordinate
            let region = MKCoordinateRegion(
                center: coordinate,
                latitudinalMeters: 2000,
                longitudinalMeters: 2000
            )
            mapView.setRegion(region, animated: true)
        }
    }
}
