//
//  ViewController.swift
//  A1_A2_iOS_Pennapar_c0874203
//
//  Created by Alice’z Poy on 2023-01-20.
//

import UIKit
import MapKit

protocol HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController {
    
    @IBOutlet weak var directBtn: UIButton!
    @IBOutlet weak var map: MKMapView!
    
    // create location manager
    var locationMnager = CLLocationManager()
    
    var destination = [CLLocationCoordinate2D]()
    var points : [CGPoint] = []
    
    var dropCount = 0
    var citySelection = false
    
    var resultSearchController:UISearchController? = nil
    var selectedPin:MKPlacemark? = nil
    
    var labels = [UILabel]()
    var currentLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        map.showsUserLocation = true
        directBtn.isHidden = true
        
        locationMnager.delegate = self
        map.delegate = self
        
        locationMnager.desiredAccuracy = kCLLocationAccuracyBest
        locationMnager.requestWhenInUseAuthorization()
        locationMnager.startUpdatingLocation()
        
        // add triple tap for add markers
        addTripleTap()
        
        //Setup for searching location
        setUpforSearch()
    }
    
    func setUpforSearch() {
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable as? any UISearchResultsUpdating
        
        let searchBar = resultSearchController?.searchBar
        searchBar?.sizeToFit()
        searchBar?.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.mapView = map
        locationSearchTable.handleMapSearchDelegate = self
    }
    
    //MARK: - Route guidance methods
    
    @IBAction func currentLocationAction(_ sender: Any) {
        map.removeOverlays(map.overlays)
        for label in labels {
            label.removeFromSuperview()
        }
        if destination.count == 3 {
            drawDestinationRoute(sourceCoordinate: destination[0], destinationCoordinate: destination[1])
            drawDestinationRoute(sourceCoordinate: destination[1], destinationCoordinate: destination[2])
            drawDestinationRoute(sourceCoordinate: destination[2], destinationCoordinate: destination[0])
        }
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
    
    //MARK: - double tap func
    func addTripleTap() {
        let tripleTap = UITapGestureRecognizer(target: self, action: #selector(dropPin))
        tripleTap.numberOfTapsRequired = 3
        map.addGestureRecognizer(tripleTap)
    }
    
    //MARK: - polygon method
    func addPolygon() {
        if  destination.count > 0 {
            let polygon = MKPolygon(coordinates: destination, count: destination.count)
            map.addOverlay(polygon)
        }
    }
    
    //MARK: - manage pin methods
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        
        if (dropCount < 3){
            directBtn.isHidden = false
            citySelection = true
            // add annotation
            let touchPoint = sender.location(in: map)
            var coordinate = CLLocationCoordinate2D()
            if let selectPin = selectedPin {
                coordinate = selectPin.coordinate
            } else {
                coordinate = map.convert(touchPoint, toCoordinateFrom: map)
            }
            
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
            setDetailAndAddPin(latitude: coordinate.latitude, longitude: coordinate.longitude)
            
            points.append(CGPoint(x: touchPoint.x, y: touchPoint.y))
            destination.append(coordinate)
            dropCount += 1
            
            if dropCount == 3 {
                addPolygon()
                addDistanceLable()
            }
        }
        else{
            directBtn.isHidden = true
            citySelection = false
            removePin()
            dropCount = 0
            selectedPin = nil
            destination = []
            points = []
            map.removeOverlays(map.overlays)
            
            for label in labels {
                label.removeFromSuperview()
            }
            
            dropPin(sender: sender)
        }
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
    
    func setDetailAndAddPin(latitude: CLLocationDegrees, longitude : CLLocationDegrees) {
        
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = latitude
        center.longitude = longitude
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
                                    {(placemarks, error) in
            
            let pm = placemarks! as [CLPlacemark]
            
            if pm.count > 0 {
                if let placemark = placemarks?[0] {
                    var address = ""
                    
                    if placemark.name != nil {
                        address += placemark.name! + " "
                    }
                    
                    var title = ""
                    if self.dropCount == 1 {
                        title = "A"
                    } else if self.dropCount == 2 {
                        title = "B"
                    } else if self.dropCount == 3 {
                        title = "C"
                    }
                    
                    self.displayLocation(latitude: latitude, longitude: longitude, title: title, subtitle: address)
                }
            }
        })
    }
    
    //MARK: - Make Label
    
    func createDistanceLabel(text : String ,from : CGPoint, to : CGPoint){
        
        let position = getCenterPoints(from: from, to: to)
        
        let label = UILabel(frame: CGRect(x: position.x, y: position.y, width: 100, height: 45))
        label.textAlignment = .center
        label.text = text + " km"
        label.backgroundColor = UIColor.blue
        label.textColor = UIColor.white
        labels.append(label)
        self.view.addSubview(label)
    }
    
    private func getCenterPoints(from: CGPoint, to: CGPoint) -> CGPoint {
        let dx = (from.x )
        let dy = (from.y )
        
        return CGPoint(x: dx, y: dy)
    }
    
    func addDistanceLable(){
        let distance = calculateDistance(from: destination[0], to: destination[1])
        
        self.createDistanceLabel(text:String(format: "%.2f", distance), from: points[0],to: points[1])
        
        let distance2 = calculateDistance(from: destination[1], to: destination[2])
        
        self.createDistanceLabel(text:String(format: "%.2f", distance2), from: points[1],to: points[2])
        
        let distance3 = calculateDistance(from: destination[2], to: destination[0])
        
        self.createDistanceLabel(text:String(format: "%.2f", distance3), from: points[2],to: points[0])
    }
    
    func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return from.distance(from: to)/1000
    }
}

extension ViewController: CLLocationManagerDelegate {
    //MARK: - didupdatelocation method
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        removePin()
        let userLocation = locations[0]
        currentLocation = userLocation
        
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
            
            let distanceLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
            distanceLabel.backgroundColor = .clear
            distanceLabel.textColor = .black
            distanceLabel.font = .boldSystemFont(ofSize: 10)
            distanceLabel.textAlignment = .center

            let titleLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
            if dropCount == 1 {
                distanceLabel.text = calculateDistanceFromCurrentLocation(to: destination[0])
            } else if dropCount == 2 {
                distanceLabel.text = calculateDistanceFromCurrentLocation(to: destination[1])
            } else if dropCount == 3 {
                distanceLabel.text = calculateDistanceFromCurrentLocation(to: destination[2])
            }
            
            titleLabel.text = annotation.title as? String
            annotationView.rightCalloutAccessoryView = distanceLabel
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
            
            return annotationView
        }
    }
    
    func calculateDistanceFromCurrentLocation(to: CLLocationCoordinate2D) -> String {
        let to = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return "\(String(format: "%.2f km", currentLocation.distance(from: to)/1000)) km"
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
            rendrer.strokeColor = UIColor.green
            rendrer.lineWidth = 2
            return rendrer
        }
        return MKOverlayRenderer()
    }
}

extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark:MKPlacemark){
        selectedPin = placemark
        dropPin(sender: UITapGestureRecognizer())
    }
}
