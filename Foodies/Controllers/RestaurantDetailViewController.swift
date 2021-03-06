//
//  RestaurantDetailViewController.swift
//  Foodies
//
//  Created by mohamed fawzy on 10/24/18.
//  Copyright © 2018 mohamed fawzy. All rights reserved.
//

import UIKit
import MapKit

class RestaurantDetailViewController: UITableViewController {
    @IBOutlet weak var ratingView: RatingsView!
    @IBOutlet weak var imageMap: UIImageView!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var overAllRating: UILabel!
    @IBOutlet weak var tableDetailsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var cuisineLabel: UILabel!
    @IBOutlet weak var headerAdressLabel: UILabel!
    
    @IBOutlet weak var heartButton: UIBarButtonItem!
    
    var selectedRestaurant: RestaurantItem?
    let manager = CoreDataManager()
    var tapGesture = UITapGestureRecognizer()
    

    override func viewDidLoad() {
        super.viewDidLoad()
       
        initialize()

    }
    
    override func viewDidAppear(_ animated: Bool) {
        createRating()
    }
    
   
    
    
    
    
   
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Segue.showReview.rawValue {
            let navigationVC = segue.destination as! UINavigationController
            let vc = navigationVC.topViewController as! ReviewFormViewController
            if let id = selectedRestaurant?.restaurantID {
                vc.selectedRestaurantID = id
            }
        }
        else if segue.identifier == Segue.showPhotoReview.rawValue {
            let navigationVC = segue.destination as! UINavigationController
            let vc = navigationVC.topViewController as! PhotoFilterViewController
            if let id = selectedRestaurant?.restaurantID {
                vc.selectedRestaurantID = id
            }
        }
        
        
    }
    
    @IBAction func unwindReviewCancel(segue:UIStoryboardSegue) {}


}






extension RestaurantDetailViewController {
    
    func initialize() {
        setupLabels()
        createMap()
        createTapGesture()
        createRating()
    }
    
    func createRating() {
        ratingView.isEnabled = false
        if let id = selectedRestaurant?.restaurantID {
            let value = manager.fetchRestaurantRating(by: id)
            ratingView.rating = CGFloat(value)
            ratingView.setNeedsDisplay()
            if value.isNaN { overAllRating.text = "0.0" }
            else { overAllRating.text = String(format: "%.1f", value) }
        }
    }
    
    func setupLabels() {
        guard let restaurant = selectedRestaurant else {return }
        if let name = restaurant.name {
            nameLabel.text = name
            title = name
        }
        if let cuisine = restaurant.subtitle { cuisineLabel.text = cuisine }
        if let address = restaurant.address {
            addressLabel.text = address
            headerAdressLabel.text = address
        }
        tableDetailsLabel.text = "Table for 7, tonight at 10:00 PM"
    }
    
    
   
    
   
  
    
    func createMap() {
        guard let annotation = selectedRestaurant, let long = annotation.longitude, let lat = annotation.latitude else{return}
        let location = CLLocationCoordinate2D(latitude: lat,longitude: long)
        takeSnapShot(with: location)
    }
    
    func takeSnapShot(with location: CLLocationCoordinate2D) {
        let mapSnapshotOptions = MKMapSnapshotter.Options()
        var loc = location
        let polyLine = MKPolyline(coordinates: &loc, count: 1)
        let region = MKCoordinateRegion(polyLine.boundingMapRect)
        mapSnapshotOptions.region = region
        mapSnapshotOptions.scale = UIScreen.main.scale
        mapSnapshotOptions.size = CGSize(width: 340, height: 208)
        mapSnapshotOptions.showsBuildings = true
        mapSnapshotOptions.showsPointsOfInterest = true
        let snapShotter = MKMapSnapshotter(options: mapSnapshotOptions)
        snapShotter.start() { snapshot, error in
            guard let snapshot = snapshot else {
                return
            }
            UIGraphicsBeginImageContextWithOptions(mapSnapshotOptions.size, true, 0)
            snapshot.image.draw(at: .zero)
            let identifier = "custompin"
            let annotation = MKPointAnnotation()
            annotation.coordinate = location
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            pinView.image = UIImage(named: "location-pin-active")!
            let pinImage = pinView.image
            var point = snapshot.point(for: location)
            let rect = self.imageMap.bounds
            if rect.contains(point) {
                let pinCenterOffset = pinView.centerOffset
                point.x -= pinView.bounds.size.width / 2
                point.y -= pinView.bounds.size.height / 2
                point.x += pinCenterOffset.x
                point.y += pinCenterOffset.y
                pinImage?.draw(at: point)
            }
            if let image = UIGraphicsGetImageFromCurrentImageContext() {
                UIGraphicsEndImageContext()
                DispatchQueue.main.async {
                    self.imageMap.image = image
                }
            }
            
        }
    }
    
    // open google,maps options when tapping on the map snapshot
    
    func createTapGesture(){
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handelTapGesture(_:)))
        imageMap.addGestureRecognizer(tapGesture)
        tapGesture.numberOfTapsRequired = 1
        tapGesture.numberOfTouchesRequired = 1
        imageMap.isUserInteractionEnabled = true
    }
    
    @objc func handelTapGesture(_ sender: UITapGestureRecognizer){
        openMaps()
    }
   
    
    func openMaps(){
        
        let alert = UIAlertController(title: "OPEN IN", message: "", preferredStyle: .actionSheet)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let googleAction = UIAlertAction(title: "Google Maps", style: .default) { (action) in
            self.openGoogleMaps()
        }
        let mapsAction = UIAlertAction(title: "Maps", style: .default) { (action) in
            self.openAppleMaps()
        }
        
        alert.addAction(cancelAction)
        alert.addAction(googleAction)
        alert.addAction(mapsAction)
        present(alert, animated: true)
        
        
    }
    
    func openGoogleMaps(){
        if (UIApplication.shared.canOpenURL(URL(string:"comgooglemaps://")!)){
            
            let lat = Float((selectedRestaurant?.coordinate.latitude)!)
            let long = Float((selectedRestaurant?.coordinate.longitude)!)
            let url = URL(string:"comgooglemaps://?center=\(lat),\(long)&zoom=14&views=traffic&q=\(lat),\(long)")!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            
        } else
        {
            NSLog("Can't use com.google.maps://");
        }
    }
    
    func openAppleMaps(){
        let coordinates = selectedRestaurant?.coordinate
        let regionDistance:CLLocationDistance = 1000
        
        let regionSpan = MKCoordinateRegion(center: coordinates!, latitudinalMeters: regionDistance, longitudinalMeters: regionDistance)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates!, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = selectedRestaurant?.name
        mapItem.openInMaps(launchOptions: options)
    }
}
