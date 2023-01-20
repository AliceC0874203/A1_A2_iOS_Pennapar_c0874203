//
//  ViewController.swift
//  A1_A2_iOS_Pennapar_c0874203
//
//  Created by Alice’z Poy on 2023-01-20.
//

import UIKit
import MapKit

class ViewController: UIViewController {
    
    @IBOutlet weak var directBtn: UIButton!
    @IBOutlet weak var map: MKMapView!
    
    // create location manager
    var locationMnager = CLLocationManager()
    
    var destination = [CLLocationCoordinate2D]()
    var points : [CGPoint] = []
    
    var dropCount = 0
    var citySelection = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.isZoomEnabled = false
        map.showsUserLocation = true
        
        directBtn.isHidden = true
        
        locationMnager.delegate = self
        map.delegate = self
        
        locationMnager.desiredAccuracy = kCLLocationAccuracyBest
        locationMnager.requestWhenInUseAuthorization()
        locationMnager.startUpdatingLocation()
        
        // add double tap for add markers
        addDoubleTap()
    }
    
    func drawDestinationRoute(sourceCoordinate : CLLocationCoordinate2D , destinationCoordinate : CLLocationCoordinate2D){
        
        let sourcePlaceMark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlaceMark = MKPlacemark(coordinate: destinationCoordinate)
              
        let directionRequest = MKDirections.Request()
        
        directionRequest.source = MKMapItem(placemark: sourcePlaceMark)
        directionRequest.destination = MKMapItem(placemark: destinationPlaceMark)
        
        directionRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionRequest)
        directions.calculate { (response, error) in
            guard let directionResponse = response else {return}
            
            let route = directionResponse.routes[0]
            
            self.map.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            
            self.map.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 100, left: 100, bottom: 100, right: 100), animated: true)
            
            self.map.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    @IBAction func currentLocationAction(_ sender: Any) {
        map.removeOverlays(map.overlays)
        if destination.count == 3 {
            drawDestinationRoute(sourceCoordinate: destination[0], destinationCoordinate: destination[1])
            drawDestinationRoute(sourceCoordinate: destination[1], destinationCoordinate: destination[2])
            drawDestinationRoute(sourceCoordinate: destination[2], destinationCoordinate: destination[0])
        }
    }
    
    //MARK: - double tap func
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        doubleTap.numberOfTapsRequired = 2
        map.addGestureRecognizer(doubleTap)
        
    }
    
    //MARK: - polyline method
    func addPolyline() {
        if  destination.count > 0 {
            let polyline = MKPolyline(coordinates: destination, count: destination.count)
            map.addOverlay(polyline)
        }
    }
    
    //MARK: - polygon method
    func addPolygon() {
        if  destination.count > 0 {
            let polygon = MKPolygon(coordinates: destination, count: destination.count)
            map.addOverlay(polygon)
        }
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        if (dropCount < 3){
            citySelection = true
            // add annotation
            let touchPoint = sender.location(in: map)
            let coordinate = map.convert(touchPoint, toCoordinateFrom: map)
            
            for des in destination {
                if des == coordinate {
                    if let index = destination.firstIndex(of: des) {
                        destination.remove(at: index)
                    }
                    removePin(coordinate: des)
                    dropCount -= 1
                    return
                }
            }
            getLocationAddressAndAddPin(latitude: coordinate.latitude, longitude: coordinate.longitude)
            points.append(CGPoint(x: touchPoint.x, y: touchPoint.y))
            destination.append(coordinate)
            dropCount += 1
            
            if dropCount == 3 {
                //  addPolyline()
                addPolygon()
                addDistanceLable()
            }
        }
        else{
            citySelection = false
            let alertController = UIAlertController(title: "Max Location Selection", message: "You already selected the maximum no of places", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func addDistanceLable(){
        let distance = calculatedistance(from: destination[0], to: destination[1])
        
        self.createDistanceLable(text:String(format: "%.2f", distance), from: points[0],to: points[1])
        
        let distance2 = calculatedistance(from: destination[1], to: destination[2])
        
        self.createDistanceLable(text:String(format: "%.2f", distance2), from: points[1],to: points[2])
        
        let distance3 = calculatedistance(from: destination[2], to: destination[0])
        
        self.createDistanceLable(text:String(format: "%.2f", distance3), from: points[2],to: points[0])
    }
    
    func calculatedistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)/1000
    }
    
    func removePin(coordinate : CLLocationCoordinate2D){
        for annotation in map.annotations {
            if annotation.coordinate.latitude == coordinate.latitude && annotation.coordinate.longitude == coordinate.longitude{
                map.removeAnnotation(annotation)
            }
        }
    }
    
    func removePin() {
        for annotation in map.annotations {
            map.removeAnnotation(annotation)
        }
    }
    
    //MARK: - display user location method
    func displayLocation(latitude: CLLocationDegrees,
                         longitude: CLLocationDegrees,
                         title: String,
                         subtitle: String) {
        // 2nd step - define span
        let latDelta: CLLocationDegrees = 0.05
        let lngDelta: CLLocationDegrees = 0.05
        
        let span = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lngDelta)
        // 3rd step is to define the location
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        // 4th step is to define the region
        let region = MKCoordinateRegion(center: location, span: span)
        
        // 5th step is to set the region for the map
        map.setRegion(region, animated: true)
        
        // 6th step is to define annotation
        let annotation = MKPointAnnotation()
        annotation.title = title
        annotation.subtitle = subtitle
        annotation.coordinate = location
        map.addAnnotation(annotation)
    }
    
    func getLocationAddressAndAddPin(latitude: CLLocationDegrees, longitude : CLLocationDegrees) {
        
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = latitude
        center.longitude = longitude
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
                                    {(placemarks, error) in
            if (error != nil)
            {
                print("reverse geodcode fail: \(error!.localizedDescription)")
            }
            let pm = placemarks! as [CLPlacemark]
            
            if pm.count > 0 {
                if let placemark = placemarks?[0] {
                    var address = ""
                    var location = ""
                    
                    if placemark.name != nil {
                        address += placemark.name! + " "
                        location = placemark.name!
                    }
                    
                    if placemark.subThoroughfare != nil {
                        address += placemark.subThoroughfare! + " "
                    }
                    
                    if placemark.thoroughfare != nil {
                        address += placemark.thoroughfare! + "\n"
                    }
                    
                    if placemark.subLocality != nil {
                        address += placemark.subLocality! + "\n"
                    }
                    
                    if placemark.subAdministrativeArea != nil {
                        address += placemark.subAdministrativeArea! + "\n"
                    }
                    
                    if placemark.postalCode != nil {
                        address += placemark.postalCode! + "\n"
                    }
                    
                    if placemark.country != nil {
                        address += placemark.country! + "\n"
                    }
                    
                    self.displayLocation(latitude: latitude, longitude: longitude, title: location, subtitle: address)
                }
            }
        })
    }
}

extension ViewController: CLLocationManagerDelegate {
    //MARK: - didupdatelocation method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        removePin()
        let userLocation = locations[0]
        
        let latitude = userLocation.coordinate.latitude
        let longitude = userLocation.coordinate.longitude
        
        displayLocation(latitude: latitude, longitude: longitude, title: "my location", subtitle: "you are here")
    }
}

extension ViewController: MKMapViewDelegate {
    //MARK: - viewFor annotation method
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        if annotation is MKUserLocation {
            return nil
        }
        if citySelection {
            let annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
            annotationView.animatesDrop = true
            annotationView.pinTintColor = #colorLiteral(red: 0.3647058904, green: 0.06666667014, blue: 0.9686274529, alpha: 1)
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
            if dropCount == 1 {
                titleLabel.text = "A"
            } else if dropCount == 2 {
                titleLabel.text = "B"
            } else if dropCount == 3 {
                titleLabel.text = "C"
            }
            
            titleLabel.tag = 42
            titleLabel.backgroundColor = .clear
            titleLabel.textColor = .black
            titleLabel.font = .boldSystemFont(ofSize: 16)
            titleLabel.textAlignment = .center
            titleLabel.minimumScaleFactor = 0.5
            annotationView.addSubview(titleLabel)
            annotationView.frame = titleLabel.frame
            
            return annotationView
        }else{
            let annotationView = map.dequeueReusableAnnotationView(withIdentifier: "customPin") ?? MKMarkerAnnotationView()
            annotationView.image = UIImage(named: "ic_place_2x")
            annotationView.canShowCallout = true
            annotationView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
            let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
            titleLabel.text = "Hey"
            titleLabel.tag = 42
            titleLabel.backgroundColor = .clear
            titleLabel.textColor = .black
            titleLabel.font = .boldSystemFont(ofSize: 16)
            titleLabel.textAlignment = .center
            titleLabel.minimumScaleFactor = 0.5
            annotationView.addSubview(titleLabel)
            annotationView.frame = titleLabel.frame
            
            return annotationView
        }
    }
        
    //MARK: - callout accessory control tapped
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
            let anno = view.annotation
            let title = "Location Details"
            let subtitle =  anno?.subtitle as? String
            let alertController = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
    }
        
    //MARK: - rendrer for overlay func
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer{
        if overlay is MKPolyline {
            let rendrer = MKPolylineRenderer(overlay: overlay)
            rendrer.strokeColor = UIColor.red
            rendrer.lineWidth = 3
            return rendrer
        } else if overlay is MKPolygon {
            let rendrer = MKPolygonRenderer(overlay: overlay)
            rendrer.fillColor = UIColor.red.withAlphaComponent(0.6)
//          rendrer.lineDashPattern = [0,10]
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}

extension CLLocationCoordinate2D: Equatable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        
        let maxLat = lhs.latitude + 0.005
        let minLat = lhs.latitude - 0.005
        
        let maxLong = lhs.longitude + 0.005
        let minLong = lhs.longitude - 0.005
        
        return (maxLat >= rhs.latitude && rhs.latitude > minLat ) && (maxLong >= rhs.longitude && rhs.longitude > minLong)
    }
}

extension UIViewController {
    
    func createDistanceLable(text : String ,from : CGPoint, to : CGPoint){
        
        let position = getCenterPoints(from: from, to: to)
        
        let label = UILabel(frame: CGRect(x: position.x, y: position.y, width: 100, height: 45))
            label.textAlignment = .center
            label.text = text + " km"
        label.backgroundColor = UIColor.blue
        label.textColor = UIColor.white
            self.view.addSubview(label)
    }
    
    private func getCenterPoints(from: CGPoint, to: CGPoint) -> CGPoint {
        let dx = (from.x )
        let dy = (from.y )
        
        return CGPoint(x: dx, y: dy)
    }
}


