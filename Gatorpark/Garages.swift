import Foundation
import CoreLocation
import FirebaseFirestore

struct Garage {
    let id: String
    let name: String
    let coordinate: CLLocationCoordinate2D
    let capacity: Int
    var currentCount: Int
    let isOpen: Bool

    init?(from document: DocumentSnapshot) {
        guard let data = document.data(),
              let name = data["Name"] as? String,
              let location = data["Location"] as? GeoPoint,
              let capacity = data["Capacity"] as? Int,
              let currentCount = data["Currentcount"] as? Int,
              let isOpen = data["Isopen"] as? Bool else {
            return nil
        }
        self.id = document.documentID
        self.name = name
        self.coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        self.capacity = capacity
        self.currentCount = currentCount
        self.isOpen = isOpen
    }
}
