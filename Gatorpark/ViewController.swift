import UIKit
import MapKit
import UserNotifications
import CoreLocation

class ViewController: UIViewController {

    // MARK: - UI
    let mapView = MKMapView()
    let searchBar = UISearchBar()
    let suggestionsTableView = UITableView()
    let suggestionsBlurView: UIVisualEffectView = {
        let effect: UIBlurEffect
        if #available(iOS 13.0, *) {
            effect = UIBlurEffect(style: .systemMaterial)
        } else {
            effect = UIBlurEffect(style: .light)
        }
        let view = UIVisualEffectView(effect: effect)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    private var filteredGarages: [Garage] = []
    private var checkedInGarage: String?

    // MARK: - Location
    private let locationManager = CLLocationManager()

    // MARK: - Data
    var garages: [Garage] = []
    private var allGarages: [Garage] = []
    private var hasAnimatedInitialPins = false
    private let checkoutReminderID = "checkoutReminder"
    private let suggestionCellID = "SuggestionCell"

    // MARK: - Annotation
    class GarageAnnotation: NSObject, MKAnnotation {
        var garage: Garage
        var coordinate: CLLocationCoordinate2D { garage.coordinate }
        var title: String? { garage.name }
        var subtitle: String? {
            let occupied = garage.currentCount
            let capacity = garage.capacity
            let availability: String
            switch occupied {
            case 0..<4:
                availability = "high availability"
            case 4..<8:
                availability = "moderate availability"
            case 8...capacity:
                availability = "low availability"
            default:
                availability = "low availability"
            }
            let percentage = Int(occupancy * 100)
            return "Spaces: \(occupied)/\(capacity) (\(percentage)% full) - \(availability)"
        }
        var occupancy: Float {
            guard garage.capacity > 0 else { return 0 }
            return Float(garage.currentCount) / Float(garage.capacity)
        }
        var percentageText: String { "\(Int(occupancy * 100))% full" }
        var isFull: Bool { garage.currentCount >= garage.capacity }

        init(garage: Garage) {
            self.garage = garage
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupSearchBar()
        setupSuggestionsTableView()
        setupLocationManager()

        GarageService.shared.observeGarages { [weak self] garages in
            self?.garages = garages
            self?.allGarages = garages
            self?.addGaragePins()
        }

        addZoomButtons()
        addNearestGarageButton()
        addUserTrackingButton()
        addAppInfoButton()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentOnboardingIfNeeded()
    }

    // MARK: - Setup
    private func setupMap() {
        mapView.frame = view.bounds
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(mapView)

        if #available(iOS 13.0, *) {
            mapView.overrideUserInterfaceStyle = .dark
            let config = MKStandardMapConfiguration(elevationStyle: .realistic,
                                                    emphasisStyle: .muted)
            mapView.preferredConfiguration = config
        } else {
            mapView.mapType = .standard
        }

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 29.6467, longitude: -82.3481),
            span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2)
        )
        mapView.setRegion(region, animated: true)

        mapView.delegate = self
        mapView.showsUserLocation = false
    }

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.showsCancelButton = true
        searchBar.placeholder = "Search garages or open spots"
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundImage = UIImage()

        if #available(iOS 13.0, *) {
            let textField = searchBar.searchTextField
            textField.backgroundColor = .white
            textField.textColor = .black
            textField.tintColor = .black
            textField.layer.cornerRadius = 10
            textField.layer.masksToBounds = true
            if let leftView = textField.leftView as? UIImageView {
                leftView.tintColor = .black
            }
        }

        searchBar.tintColor = .black

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8)
        ])
    }

    private func setupSuggestionsTableView() {
        suggestionsTableView.delegate = self
        suggestionsTableView.dataSource = self
        suggestionsTableView.backgroundColor = .clear
        suggestionsTableView.register(UITableViewCell.self, forCellReuseIdentifier: suggestionCellID)
        suggestionsTableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(suggestionsBlurView)
        suggestionsBlurView.contentView.addSubview(suggestionsTableView)
        setSuggestionsHidden(true)

        NSLayoutConstraint.activate([
            suggestionsBlurView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            suggestionsBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            suggestionsBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            suggestionsBlurView.heightAnchor.constraint(equalToConstant: 200),

            suggestionsTableView.topAnchor.constraint(equalTo: suggestionsBlurView.contentView.topAnchor),
            suggestionsTableView.leadingAnchor.constraint(equalTo: suggestionsBlurView.contentView.leadingAnchor),
            suggestionsTableView.trailingAnchor.constraint(equalTo: suggestionsBlurView.contentView.trailingAnchor),
            suggestionsTableView.bottomAnchor.constraint(equalTo: suggestionsBlurView.contentView.bottomAnchor)
        ])
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    // MARK: - Helpers
    private func setSuggestionsHidden(_ hidden: Bool) {
        suggestionsTableView.isHidden = hidden
        suggestionsBlurView.isHidden = hidden
    }

    private func addGaragePins(fitAll: Bool = true) {
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
        for garage in garages {
            let annotation = GarageAnnotation(garage: garage)
            mapView.addAnnotation(annotation)
        }
        guard fitAll else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let pins = self.mapView.annotations.filter { !($0 is MKUserLocation) }
            self.mapView.showAnnotations(pins, animated: true)
        }
    }

    private func addZoomButtons() {
        let zoomInButton = UIButton(type: .system)
        zoomInButton.setTitle("+", for: .normal)
        zoomInButton.tintColor = .black
        zoomInButton.backgroundColor = .white
        zoomInButton.addTarget(self, action: #selector(zoomIn), for: .touchUpInside)

        let zoomOutButton = UIButton(type: .system)
        zoomOutButton.setTitle("-", for: .normal)
        zoomOutButton.tintColor = .black
        zoomOutButton.backgroundColor = .white
        zoomOutButton.addTarget(self, action: #selector(zoomOut), for: .touchUpInside)

        let zoomInFrame = CGRect(x: view.bounds.width - 60, y: 120, width: 40, height: 40)
        let zoomOutFrame = CGRect(x: view.bounds.width - 60, y: 170, width: 40, height: 40)

        view.addSubview(makeBlurContainer(for: zoomInButton, frame: zoomInFrame, cornerRadius: 8))
        view.addSubview(makeBlurContainer(for: zoomOutButton, frame: zoomOutFrame, cornerRadius: 8))
    }

    private func addNearestGarageButton() {
        let button = UIButton(type: .system)
        button.setTitle("Nearest", for: .normal)
        button.tintColor = .black
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(findNearestGarage), for: .touchUpInside)

        let frame = CGRect(x: view.bounds.width - 90, y: 220, width: 70, height: 40)
        view.addSubview(makeBlurContainer(for: button, frame: frame, cornerRadius: 8))
    }

    private func addUserTrackingButton() {
        let trackingButton = MKUserTrackingButton(mapView: mapView)
        trackingButton.tintColor = .black
        trackingButton.backgroundColor = .white

        let frame = CGRect(x: view.bounds.width - 60, y: 270, width: 40, height: 40)
        view.addSubview(makeBlurContainer(for: trackingButton, frame: frame, cornerRadius: 8))
    }

    private func addAppInfoButton() {
        let infoButton = UIButton(type: .infoLight)
        infoButton.tintColor = .black
        infoButton.accessibilityLabel = "App information"
        infoButton.addTarget(self, action: #selector(presentAppInfo), for: .touchUpInside)

        let frame = CGRect(x: view.bounds.width - 60, y: 70, width: 40, height: 40)
        view.addSubview(makeBlurContainer(for: infoButton, frame: frame, cornerRadius: 8))
    }

    private func requestLocationAuthorizationIfNeeded() {
        let status = currentLocationAuthorizationStatus()
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.follow, animated: true)
        case .restricted, .denied:
            mapView.showsUserLocation = false
        @unknown default:
            break
        }
    }

    private func currentLocationAuthorizationStatus() -> CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
    }

    private func makeBlurContainer(for control: UIView, frame: CGRect, cornerRadius: CGFloat) -> UIView {
        if #available(iOS 13.0, *) {
            let container = UIView(frame: frame)
            container.backgroundColor = .white
            container.layer.cornerRadius = cornerRadius
            container.clipsToBounds = true
            control.frame = container.bounds
            control.backgroundColor = .white
            container.addSubview(control)
            return container
        } else {
            control.frame = frame
            control.backgroundColor = .white
            control.layer.cornerRadius = cornerRadius
            return control
        }
    }

    private func updateAnnotationColors() {
        for annotation in mapView.annotations {
            guard let view = mapView.view(for: annotation) as? MKMarkerAnnotationView,
                  let garageAnnotation = annotation as? GarageAnnotation else { continue }
            if garageAnnotation.garage.name == checkedInGarage {
                view.markerTintColor = .systemGreen
            } else {
                let color = garageAnnotation.isFull ? UIColor.systemRed : UIColor.systemBlue
                view.markerTintColor = color
            }
        }
    }

    @objc private func zoomIn() {
        var r = mapView.region
        r.span.latitudeDelta *= 0.5
        r.span.longitudeDelta *= 0.5
        mapView.setRegion(r, animated: true)
    }

    @objc private func zoomOut() {
        var r = mapView.region
        r.span.latitudeDelta *= 2
        r.span.longitudeDelta *= 2
        mapView.setRegion(r, animated: true)
    }

    @objc private func findNearestGarage() {
        guard let userLocation = locationManager.location else {
            showAlert(title: "Location Unavailable", message: "Unable to determine current location.")
            return
        }

        let openGarages = allGarages.filter { $0.isOpen }
        guard let nearest = openGarages.min(by: { first, second in
            let firstLoc = CLLocation(latitude: first.coordinate.latitude, longitude: first.coordinate.longitude)
            let secondLoc = CLLocation(latitude: second.coordinate.latitude, longitude: second.coordinate.longitude)
            return userLocation.distance(from: firstLoc) < userLocation.distance(from: secondLoc)
        }) else {
            showAlert(title: "No Open Garages", message: "There are no open garages available.")
            return
        }

        garages = allGarages
        addGaragePins(fitAll: false)

        let region = MKCoordinateRegion(center: nearest.coordinate,
                                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        mapView.setRegion(region, animated: true)

        if let annotation = mapView.annotations.first(where: {
            ($0 as? GarageAnnotation)?.garage.id == nearest.id
        }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.mapView.selectAnnotation(annotation, animated: true)
            }
        }
    }

    // MARK: - Notifications
    private func scheduleCheckoutReminder(for garage: Garage) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [checkoutReminderID])
        let content = UNMutableNotificationContent()
        content.title = "Checkout Reminder"
        content.body = "Don't forget to check out of \(garage.name)."
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2.5 * 60 * 60, repeats: false)
        let request = UNNotificationRequest(identifier: checkoutReminderID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    private func cancelCheckoutReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [checkoutReminderID])
        center.removeDeliveredNotifications(withIdentifiers: [checkoutReminderID])
    }

    // MARK: - Check-in/out
    private func didTapCheckIn(for garage: Garage) {
        GarageService.shared.checkIn(to: garage) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.checkedInGarage = garage.name
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self?.scheduleCheckoutReminder(for: garage)
                    self?.updateAnnotationColors()
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func didTapCheckOut(for garage: Garage) {
        GarageService.shared.checkOut(from: garage) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.checkedInGarage = nil
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    self?.cancelCheckoutReminder()
                    self?.updateAnnotationColors()
                case .failure(let error):
                    self?.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func presentOnboardingIfNeeded() {
        let defaults = UserDefaults.standard

        if defaults.bool(forKey: AppStorageKey.hasCompletedOnboarding) {
            requestLocationAuthorizationIfNeeded()
            NotificationPermissionManager.shared.requestAuthorizationIfNeeded()
            return
        }

        guard !(presentedViewController is OnboardingViewController) else { return }

        let onboarding = OnboardingViewController()
        onboarding.modalPresentationStyle = .formSheet
        onboarding.completion = { [weak self] in
            self?.requestLocationAuthorizationIfNeeded()
            NotificationPermissionManager.shared.requestAuthorizationIfNeeded()
        }
        present(onboarding, animated: true)
    }

    @objc private func presentAppInfo() {
        let infoVC = AppInfoViewController()
        let nav = UINavigationController(rootViewController: infoVC)
        nav.modalPresentationStyle = .formSheet
        present(nav, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate
extension ViewController: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleLocationAuthorizationChange(manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        handleLocationAuthorizationChange(status)
    }

    private func handleLocationAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            print("✅ Location authorized")
            locationManager.startUpdatingLocation()
            mapView.showsUserLocation = true
            mapView.setUserTrackingMode(.follow, animated: true)
        case .denied, .restricted:
            print("❌ Location denied")
            mapView.showsUserLocation = false
            let alert = UIAlertController(title: "Location Access Needed",
                                          message: "Enable location in Settings to find nearby garages.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            })
            present(alert, animated: true)
        case .notDetermined:
            print("ℹ️ Location not determined yet")
            mapView.showsUserLocation = false
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Only recenter the map if we're actively following the user.
        if mapView.userTrackingMode == .follow || mapView.userTrackingMode == .followWithHeading {
            let region = MKCoordinateRegion(center: location.coordinate,
                                            latitudinalMeters: 500,
                                            longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
        print("📍 User location:", location.coordinate)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("⚠️ Location error:", error.localizedDescription)
    }
}


extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }
        let id = "Garage"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: id) as? MKMarkerAnnotationView
        if view == nil {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: id)
            view?.canShowCallout = true

            let checkIn = UIButton(type: .system)
            checkIn.setTitle("In", for: .normal)
            checkIn.tintColor = .black
            checkIn.backgroundColor = .white
            checkIn.frame = CGRect(x: 0, y: 0, width: 60, height: 34)
            checkIn.layer.cornerRadius = 5
            view?.leftCalloutAccessoryView = checkIn

            let checkOut = UIButton(type: .system)
            checkOut.setTitle("Out", for: .normal)
            checkOut.tintColor = .black
            checkOut.backgroundColor = .white
            checkOut.frame = CGRect(x: 0, y: 0, width: 60, height: 34)
            checkOut.layer.cornerRadius = 5
            view?.rightCalloutAccessoryView = checkOut
        } else {
            view?.annotation = annotation
        }
        if let garageAnnotation = annotation as? GarageAnnotation {
            // Reflect the garage availability or check-in status with annotation color.
            if garageAnnotation.garage.name == checkedInGarage {
                view?.markerTintColor = .systemGreen
            } else {
                let color = garageAnnotation.isFull ? UIColor.systemRed : UIColor.systemBlue
                view?.markerTintColor = color
            }
            view?.glyphText = "P"
            view?.glyphTintColor = .white

            // Occupancy percentage within callout
            let statusLabel = UILabel()
            statusLabel.font = UIFont.systemFont(ofSize: 12)
            statusLabel.text = garageAnnotation.percentageText

            let progress = UIProgressView(progressViewStyle: .default)
            progress.progress = garageAnnotation.occupancy

            let stack = UIStackView(arrangedSubviews: [statusLabel, progress])
            stack.axis = .vertical
            stack.spacing = 4
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.widthAnchor.constraint(equalToConstant: 120).isActive = true

            view?.detailCalloutAccessoryView = stack
        }
        return view
    }

    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        guard !hasAnimatedInitialPins else { return }
        hasAnimatedInitialPins = true
        for (index, view) in views.enumerated() {
            guard !(view.annotation is MKUserLocation) else { continue }
            let dropOffset = mapView.bounds.size.height
            view.transform = CGAffineTransform(translationX: 0, y: -dropOffset)
            UIView.animate(
                withDuration: 0.6,
                delay: 0.05 * Double(index),
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.8,
                options: [.curveEaseInOut],
                animations: {
                    view.transform = .identity
                }
            )
        }
    }

    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let garageAnnotation = view.annotation as? GarageAnnotation else { return }

        let isCheckIn = control == view.leftCalloutAccessoryView
        if isCheckIn {
            if let current = checkedInGarage {
                let message = current == garageAnnotation.garage.name ? "You are already checked in here." : "You are already checked in at \(current). Please check out before checking in to another garage."
                showAlert(title: "Already Checked In", message: message)
                return
            }
        } else {
            guard let current = checkedInGarage else {
                showAlert(title: "Not Checked In", message: "You are not currently checked in to any garage.")
                return
            }
            guard current == garageAnnotation.garage.name else {
                showAlert(title: "Wrong Garage", message: "You are checked in at \(current).")
                return
            }
        }

        let actionText = isCheckIn ? "check in" : "check out"
        let alert = UIAlertController(title: "Confirm", message: "Are you sure you want to \(actionText)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let self = self else { return }
            if isCheckIn {
                self.didTapCheckIn(for: garageAnnotation.garage)
            } else {
                self.didTapCheckOut(for: garageAnnotation.garage)
            }
        })
        present(alert, animated: true)
    }
}

extension ViewController: UISearchBarDelegate {
    private func performSearch(text: String) {
        if let spots = Int(text) {
            garages = allGarages.filter { $0.capacity - $0.currentCount > spots }
            addGaragePins()
        } else if let garage = allGarages.first(where: { $0.name.lowercased().contains(text.lowercased()) }) {
            garages = allGarages
            addGaragePins(fitAll: false)
            let region = MKCoordinateRegion(center: garage.coordinate,
                                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            mapView.setRegion(region, animated: true)
            if let annotation = mapView.annotations.first(where: {
                ($0 as? GarageAnnotation)?.garage.name == garage.name
            }) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                    self?.mapView.selectAnnotation(annotation, animated: true)
                }
            }
        }
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
        setSuggestionsHidden(true)
        guard let text = searchBar.text, !text.isEmpty else { return }
        performSearch(text: text)
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredGarages.removeAll()
            setSuggestionsHidden(true)
            garages = allGarages
            addGaragePins()
        } else if Int(searchText) == nil {
            filteredGarages = allGarages.filter { $0.name.lowercased().contains(searchText.lowercased()) }
            setSuggestionsHidden(filteredGarages.isEmpty)
            suggestionsTableView.reloadData()
        } else {
            filteredGarages.removeAll()
            setSuggestionsHidden(true)
        }
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        filteredGarages.removeAll()
        setSuggestionsHidden(true)
        garages = allGarages
        addGaragePins()
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredGarages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: suggestionCellID, for: indexPath)
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        cell.textLabel?.text = filteredGarages[indexPath.row].name
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let garage = filteredGarages[indexPath.row]
        searchBar.text = garage.name
        setSuggestionsHidden(true)
        searchBar.resignFirstResponder()
        performSearch(text: garage.name)
    }
}
