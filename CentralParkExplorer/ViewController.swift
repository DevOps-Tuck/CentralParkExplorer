// ViewController.swift — Central Park Explorer with Hex Tiles and Trail
// CentralParkExplorer
//
// This version includes:
// - Hex tile-based exploration
// - Trail of past user locations
// - Restriction to a Central Park rectangular boundary
// - Accurate % explored tracking

import UIKit
import MapKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    let mapView = MKMapView()
    let exploredLabel = UILabel()
    let locationManager = CLLocationManager()

    var exploredTiles = Set<String>()
    var previousLocation: CLLocationCoordinate2D?
    var trailCoordinates: [CLLocationCoordinate2D] = []
    var milestonesSent: Set<Int> = []
    
    
    var totalTilesInPark: Int = 0

    let tileSize = 0.001
    let centralParkBoundary: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 40.7969, longitude: -73.9495),
        CLLocationCoordinate2D(latitude: 40.800686, longitude: -73.9580727),
        CLLocationCoordinate2D(latitude: 40.7682567, longitude: -73.9820194),
        CLLocationCoordinate2D(latitude: 40.7645514, longitude: -73.9731789),
        CLLocationCoordinate2D(latitude: 40.7969, longitude: -73.9495) // close the loop
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupLabel()
        setupLocation()
        setupBackButton()
        requestNotificationPermission()
        calculateTotalTilesInPark()
        addBlurMask()
    }

    func setupMapView() {
        mapView.frame = view.bounds
        mapView.delegate = self
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        view.addSubview(mapView)

        let center = CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654)
        let region = MKCoordinateRegion(center: center,
                                        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        mapView.setRegion(region, animated: true)
    }

    func setupLabel() {
        exploredLabel.frame = CGRect(x: 16, y: 60, width: view.bounds.width - 32, height: 30)
        exploredLabel.textColor = .black
        exploredLabel.font = .boldSystemFont(ofSize: 18)
        exploredLabel.text = "Explored: 0%"
        exploredLabel.backgroundColor = .white.withAlphaComponent(0.6)
        exploredLabel.layer.cornerRadius = 8
        exploredLabel.clipsToBounds = true
        exploredLabel.textAlignment = .left
        view.addSubview(exploredLabel)
    }

    func setupLocation() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        backButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        backButton.layer.cornerRadius = 8
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            backButton.widthAnchor.constraint(equalToConstant: 70),
            backButton.heightAnchor.constraint(equalToConstant: 35)
        ])
    }

    @objc func backTapped() {
        dismiss(animated: true)
    }
    
    func addBlurMask() {
        _ = MKMapRect.world
        _ = CGMutablePath()

        // Convert Central Park boundary to MKMapPoints
        let parkPoints = centralParkBoundary.map { MKMapPoint($0) }

        // Create full outer rectangle
        let outerCoords: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 90.0, longitude: -180.0),
            CLLocationCoordinate2D(latitude: 90.0, longitude: 180.0),
            CLLocationCoordinate2D(latitude: -90.0, longitude: 180.0),
            CLLocationCoordinate2D(latitude: -90.0, longitude: -180.0),
            CLLocationCoordinate2D(latitude: 90.0, longitude: -180.0)
        ]
        
        let outerPoints = outerCoords.map { MKMapPoint($0) }

        // Create the "hole" for Central Park
        let outerPolygon = MKPolygon(points: outerPoints, count: outerPoints.count)
        let holePolygon = MKPolygon(points: parkPoints, count: parkPoints.count)

        // Subtract Central Park from the full map
        let mask = MKPolygon(points: outerPolygon.points(), count: outerPolygon.pointCount, interiorPolygons: [holePolygon])

        mapView.addOverlay(mask)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let current = locations.last?.coordinate else { return }
        print("LOCATION UPDATE: \(current.latitude), \(current.longitude)")
        trailCoordinates.append(current)
        drawTrail()

        if let previous = previousLocation {
            let interpolated = interpolateTiles(from: previous, to: current)
            for coord in interpolated {
                exploreTile(at: coord)
            }
        } else {
            exploreTile(at: current)
        }

        previousLocation = current
    }

    func isInsideCentralPark(_ coord: CLLocationCoordinate2D) -> Bool {
        let path = CGMutablePath()
        let points = centralParkBoundary.map { point in
            CGPoint(x: point.longitude, y: point.latitude)
        }

        guard let first = points.first else { return false }

        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()

        let testPoint = CGPoint(x: coord.longitude, y: coord.latitude)
        return path.contains(testPoint)
    }

    func tileKey(for coordinate: CLLocationCoordinate2D) -> String {
        let latIndex = Int(coordinate.latitude / tileSize)
        let lonIndex = Int(coordinate.longitude / tileSize)
        return "\(latIndex)_\(lonIndex)"
    }

    func exploreTile(at coordinate: CLLocationCoordinate2D) {
        guard isInsideCentralPark(coordinate) else { return }
        let key = tileKey(for: coordinate)
        if exploredTiles.contains(key) { return }

        exploredTiles.insert(key)

        let lat = floor(coordinate.latitude / tileSize) * tileSize
        let lon = floor(coordinate.longitude / tileSize) * tileSize
        let hex = hexagon(at: CLLocationCoordinate2D(latitude: lat + tileSize / 2,
                                                     longitude: lon + tileSize / 2))
        mapView.addOverlay(hex)
        updateExploredLabel()
    }

    func hexagon(at center: CLLocationCoordinate2D) -> MKPolygon {
        let radius = tileSize / 1.5
        var coords: [CLLocationCoordinate2D] = []

        for i in 0..<6 {
            let angle = (Double(i) * 60.0) * Double.pi / 180.0
            let dx = radius * cos(angle)
            let dy = radius * sin(angle)
            let point = CLLocationCoordinate2D(latitude: center.latitude + dy,
                                               longitude: center.longitude + dx / cos(center.latitude * Double.pi / 180))
            coords.append(point)
        }

        return MKPolygon(coordinates: coords, count: coords.count)
    }

    func drawTrail() {
        mapView.overlays.filter { $0 is MKPolyline }.forEach { mapView.removeOverlay($0) }
        let polyline = MKPolyline(coordinates: trailCoordinates, count: trailCoordinates.count)
        mapView.addOverlay(polyline)
    }

    func interpolateTiles(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> [CLLocationCoordinate2D] {
        let steps = max(
            abs(Int((to.latitude - from.latitude) / tileSize)),
            abs(Int((to.longitude - from.longitude) / tileSize))
        )

        guard steps > 0 else { return [to] }

        var coords: [CLLocationCoordinate2D] = []
        for i in 0...steps {
            let lat = from.latitude + Double(i) * (to.latitude - from.latitude) / Double(steps)
            let lon = from.longitude + Double(i) * (to.longitude - from.longitude) / Double(steps)
            coords.append(CLLocationCoordinate2D(latitude: lat, longitude: lon))
        }
        return coords
    }
    func calculateTotalTilesInPark() {
        var count = 0
        let latRange = stride(from: 40.764, through: 40.800, by: tileSize)
        let lonRange = stride(from: -73.981, through: -73.949, by: tileSize)

        for lat in latRange {
            for lon in lonRange {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                if isInsideCentralPark(coord) {
                    count += 1
                }
            }
        }
        totalTilesInPark = count
    }
    
    func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.text = message
        toastLabel.textColor = .white
        toastLabel.backgroundColor = UIColor.systemPink.withAlphaComponent(0.95)
        toastLabel.textAlignment = .center
        toastLabel.font = UIFont.systemFont(ofSize: 24, weight: .heavy)
        toastLabel.numberOfLines = 0
        toastLabel.alpha = 0.0
        toastLabel.layer.cornerRadius = 20
        toastLabel.clipsToBounds = true

        let labelHeight: CGFloat = 100
        let labelWidth: CGFloat = view.frame.size.width - 40
        toastLabel.frame = CGRect(x: 20, y: view.frame.size.height / 2 - labelHeight / 2, width: labelWidth, height: labelHeight)

        view.addSubview(toastLabel)
        view.bringSubviewToFront(toastLabel) // Ensure it appears above everything

        UIView.animate(withDuration: 0.4, animations: {
            toastLabel.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.4, delay: 3.5, options: .curveEaseOut, animations: {
                toastLabel.alpha = 0.0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
    
    func showConfetti() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: view.bounds.width / 2, y: -10)
        emitter.emitterShape = .line
        emitter.emitterSize = CGSize(width: view.bounds.size.width, height: 2)

        let colors: [UIColor] = [.systemPink, .systemBlue, .systemYellow, .systemGreen, .systemPurple]
        let emojis = ["⭐️", "✨","🗽","🚕"]

        var cells: [CAEmitterCell] = []

        for emoji in emojis {
            let cell = CAEmitterCell()
            let image = emojiToImage(emoji: emoji)
            cell.contents = image.cgImage
            cell.birthRate = 6
            cell.lifetime = 5.0
            cell.velocity = 200
            cell.velocityRange = 50
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 4
            cell.spin = 2
            cell.spinRange = 3
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cells.append(cell)
        }

        emitter.emitterCells = cells
        view.layer.addSublayer(emitter)

        // Remove after 5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            emitter.removeFromSuperlayer()
        }
    }
    
    func emojiToImage(emoji: String) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        UIColor.clear.set()
        let rect = CGRect(origin: .zero, size: size)
        UIRectFill(rect)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 32),
            .paragraphStyle: paragraphStyle
        ]

        emoji.draw(in: rect, withAttributes: attrs)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    func updateExploredLabel() {
        guard totalTilesInPark > 0 else { return }
        let percent = Double(exploredTiles.count) / Double(totalTilesInPark) * 100.0
        exploredLabel.text = String(format: "Explored: %.0f%%", percent)

        let milestonePercents = [10, 25, 50, 75, 100]
        let currentPercent = Int(percent)

        for milestone in milestonePercents {
            if currentPercent >= milestone && !milestonesSent.contains(milestone) {
                milestonesSent.insert(milestone)
                sendMilestoneNotification(for: milestone)
            }
        }
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polygon = overlay as? MKPolygon {
            let renderer = MKPolygonRenderer(polygon: polygon)

            if polygon.interiorPolygons?.isEmpty == false {
                // This is the blur mask with a hole for Central Park
                renderer.fillColor = UIColor.black.withAlphaComponent(0.6)
                renderer.strokeColor = .clear
            } else {
                // These are the green hex tiles
                renderer.fillColor = UIColor.green.withAlphaComponent(0.3)
                renderer.strokeColor = UIColor.green
                renderer.lineWidth = 1
            }

            return renderer

        } else if let polyline = overlay as? MKPolyline {
            // This is the user trail
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .blue
            renderer.lineWidth = 2.5
            return renderer
        }

        return MKOverlayRenderer()
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func sendMilestoneNotification(for percent: Int) {
        var message = ""

        switch percent {
        case 10:
            message = "🔟% Explored! You're just getting started 🎉"
        case 25:
            message = "🎉 25% Explored! Keep going, you're making great progress!"
        case 50:
            message = "🎉 Halfway There! You’ve explored 50% of Central Park! 🔟🎉"
        case 75:
            message = "🎯 75% Explored! Almost there — just a little more to go!"
        case 100:
            message = "🏁 100% Complete! You've explored all of Central Park! Incredible work! 🎉"
        default:
            message = "\(percent)% Explored — keep it up!"
        }

        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        var stored = UserDefaults.standard.array(forKey: "earnedMilestones") as? [Int] ?? []
        if !stored.contains(percent) {
            stored.append(percent)
            UserDefaults.standard.set(stored, forKey: "earnedMilestones")
        }
        showToast(message: message)
        showConfetti()
    }
}
