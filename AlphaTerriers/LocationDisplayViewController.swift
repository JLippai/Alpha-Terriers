//
//  LocationDisplayViewController.swift
//  MySampleApp
//
//  Created by Christopher Liao on 4/21/16.
//  Copyright © 2016 Amazon. All rights reserved.
//
import UIKit
import AWSMobileHubHelper
import CoreLocation
import MapKit

class LocationDisplayViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var regionLabel: UILabel! //displays name of region you would be checking into
    var locationManager: CLLocationManager!
    var canContinue: Bool = false //if false, display button will not work
    var locationID : NSInteger = 10 //ID of location in right now as dtermined by C++ inrange function
    var locationTimer : NSTimer! // Timer that executes updateLocationInfo
    let regionDict : [Int:String] = [0 : "PHO", 1:"EPIC", 2:"GSU", 3:"CAS"] // MODIFY IF SCALING APP
    
    override func viewWillAppear(animated: Bool) {
        //executed before scene is displayed
        super.viewWillAppear(animated)
        locationManager = CLLocationManager()
        
        // Ask for Authorisation from the User.
        self.locationManager.requestAlwaysAuthorization()
        
        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        //START MapView config. Note: coordinates are hardcoded
        self.mapView.delegate = self
        
        let theSpan:MKCoordinateSpan = MKCoordinateSpanMake(0.01 , 0.01)
        let location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 42.349899, longitude: -71.105742)
        let theRegion:MKCoordinateRegion = MKCoordinateRegionMake(location, theSpan)
        
        mapView.setRegion(theRegion, animated: true)
        
        let gsuLocation = CLLocationCoordinate2DMake(42.350852, -71.108848)
        let gsuPin = MKPointAnnotation()
        gsuPin.coordinate = gsuLocation
        gsuPin.title = "GSU"
        
        let casLocation = CLLocationCoordinate2DMake(42.350460, -71.105742)
        let casPin = MKPointAnnotation()
        casPin.coordinate = casLocation
        casPin.title = "CAS"
        
        let phoLocation = CLLocationCoordinate2DMake(42.349324, -71.106176)
        let phoPin = MKPointAnnotation()
        phoPin.coordinate = phoLocation
        phoPin.title = "PHO"
        
        let epicLocation = CLLocationCoordinate2DMake(42.349899, -71.107995)
        let epicPin = MKPointAnnotation()
        epicPin.coordinate = epicLocation
        epicPin.title = "EPIC"
        
        mapView.addAnnotation(epicPin)
        mapView.addAnnotation(gsuPin)
        mapView.addAnnotation(casPin)
        mapView.addAnnotation(phoPin)
        mapView.showsUserLocation = true
        //END MapView config
    }
    
    override func viewDidAppear(animated: Bool) {
        //This executes after secene appears
        self.locationTimer = NSTimer(timeInterval: 1.0, target: self, selector: #selector(LocationDisplayViewController.updateLocationInfo), userInfo: nil, repeats: true)
        NSRunLoop.currentRunLoop().addTimer(self.locationTimer, forMode: NSRunLoopCommonModes)
    }
    
    func updateLocationInfo() {
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation() //force update
        if let locValue:CLLocationCoordinate2D = locationManager.location?.coordinate {
            latitudeLabel.text = (String)(locValue.latitude)
            longitudeLabel.text = (String)(locValue.longitude)
            locationID = Int(inrange(locValue.latitude,locValue.longitude))
            regionLabel.text = "You are in \(self.regionDict[locationID]!)"
            canContinue = true
        }
    }
    
    @IBAction func DisplayAction(sender: UIButton) {
        if (self.canContinue) {
            self.locationTimer.invalidate() // stop updating location
            performSegueWithIdentifier("DisplaySegue", sender: self) //move to Challenge scenet
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "DisplaySegue") {
            let nextViewController = segue.destinationViewController as! LocationChallengeViewController;
            nextViewController.locationID = self.locationID
        }
    }
}