import CoreLocation
import Foundation

final class LocationPermissionRequester: NSObject {
    private let locationManager = CLLocationManager()
    private var hasRequestedPermission = false

    override init() {
        super.init()
        locationManager.delegate = self
    }

    func requestWhenInUseAuthorizationIfNeeded() {
        guard !hasRequestedPermission else { return }
        hasRequestedPermission = true

        guard CLLocationManager.locationServicesEnabled() else { return }
        guard CLLocationManager.authorizationStatus() == .notDetermined else { return }
        locationManager.requestWhenInUseAuthorization()
    }
}

extension LocationPermissionRequester: CLLocationManagerDelegate {}
