//
//  MainViewController.swift
//  Bourdain
//
//  Created by Karen Ho on 9/16/17.
//  Copyright © 2017 Karen Ho. All rights reserved.
//

import UIKit
import ArcGIS

class MainViewController: UIViewController, AGSGeoViewTouchDelegate {
    
    @IBOutlet private weak var mapView: AGSMapView!
    @IBOutlet private weak var detailView: UIView!
    
    @IBOutlet private weak var restaurantTitle: UILabel!
    @IBOutlet private weak var restaurantAddress: UILabel!
    @IBOutlet private weak var activeUsers: UILabel!
    @IBOutlet private weak var messageNumbers: UILabel!
    @IBOutlet private weak var chatButton: UIButton!
    @IBOutlet private weak var orderTakeoutButton: UIButton!
    @IBOutlet private weak var restaurantImage: UIImageView!
    
    private var map: AGSMap!
    private var graphicsOverlay: AGSGraphicsOverlay!
    private var locatorTask: AGSLocatorTask!
    
    let restaurantNames: [String] = ["Perry's"]//["Sankra", "398 Brasserie", "The Halal Guys", "Liloliho Yacht Club", "Osha Thai Noodle Cafe"]
    
    let restaurantAddresses: [String] = ["601 Mission Bay"] //["704 Sutter St", "398 Geary St", "340 O'Farrell St", "871 Sutter St", "696 Geary St"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.map = AGSMap(basemap: AGSBasemap.streets())
        self.mapView.map = self.map
        self.mapView.touchDelegate = self
        
        //instantiate the graphicsOverlay and add to the map view
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.add(self.graphicsOverlay)
        
        self.locatorTask = AGSLocatorTask(url: URL(string: "https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer")!)
        
        let currentLocation = CLLocationCoordinate2D(latitude: 37.7756433, longitude: -122.3889372)
        let currentPoint = AGSPoint(clLocationCoordinate2D: currentLocation)
        
        self.geocodePOIs("restaurants", location: currentPoint, extent: nil)
                
        startLocationDisplay(with: .recenter)
        
        self.detailView.layer.cornerRadius = 5.0
        self.detailView.dropShadow()
        self.chatButton.layer.cornerRadius = 5.0
        self.orderTakeoutButton.layer.cornerRadius = 5.0
        self.restaurantImage.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func startLocationDisplay(with autoPanMode: AGSLocationDisplayAutoPanMode) {
        self.mapView.locationDisplay.autoPanMode = autoPanMode
        self.mapView.locationDisplay.start { (error:Error?) -> Void in
            if let error = error {
                NSLog("\(error)")
            }
        }
    }
    
    func handleGeocodeResultsForPOIs(_ geocodeResults: [AGSGeocodeResult]?, areExtentBased: Bool) {
        if let results = geocodeResults , results.count > 0 {
            //show the graphics on the map
            for result in results {
                let graphic = self.graphicForPoint(result.displayLocation!, attributes: result.attributes as [String : AnyObject]?)
                                
                self.graphicsOverlay.graphics.add(graphic)
            }
        }
        else {
            //show alert for no results
            print("No results found")
        }
    }

    
    private func graphicForPoint(_ point: AGSPoint, attributes:[String:AnyObject]?) -> AGSGraphic {
        let markerImage = UIImage(named: "marker")!
        let symbol = AGSPictureMarkerSymbol(image: markerImage)
        symbol.leaderOffsetY = markerImage.size.height/2
        symbol.offsetY = markerImage.size.height/2
        let graphic = AGSGraphic(geometry: point, symbol: symbol, attributes: attributes)
        return graphic
    }
    
    private func geocodePOIs(_ poi: String, location: AGSPoint?, extent: AGSGeometry?) {
        //hide callout if already visible
        self.mapView.callout.dismiss()
        
        //remove all previous graphics
        self.graphicsOverlay.graphics.removeAllObjects()
        
        //parameters for geocoding POIs
        let params = AGSGeocodeParameters()
        params.preferredSearchLocation = location
        params.searchArea = extent
        params.outputSpatialReference = self.mapView.spatialReference
        params.resultAttributeNames.append(contentsOf: ["*"])
        
        
        //geocode using the search text and params
        self.locatorTask.geocode(withSearchText: poi, parameters: params) { [weak self] (results:[AGSGeocodeResult]?, error:Error?) -> Void in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                self?.handleGeocodeResultsForPOIs(results, areExtentBased: (extent != nil))
            }
        }
    }
    
    //MARK: - AGSGeoViewTouchDelegate
    
    func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        //dismiss the callout if already visible
        self.mapView.callout.dismiss()
        
        //identify graphics at the tapped location
        self.mapView.identify(self.graphicsOverlay, screenPoint: screenPoint, tolerance: 12, returnPopupsOnly: false, maximumResults: 1) { (result: AGSIdentifyGraphicsOverlayResult) -> Void in
            if let error = result.error {
                print(error)
            }
            else if result.graphics.count > 0 {
                let randomIndex = Int(arc4random_uniform(UInt32(self.restaurantNames.count)))
                self.restaurantTitle.text = self.restaurantNames[randomIndex]
                self.restaurantAddress.text = self.restaurantAddresses[randomIndex]
                self.activeUsers.text = "\(Int(arc4random_uniform(UInt32(10)) + 1))"
                self.messageNumbers.text = "\(Int(arc4random_uniform(UInt32(10))) + 30)"
                self.detailView.isHidden = false
            }
        }
    }
    
    @IBAction func close(_ sender: UIButton) {
        self.detailView.isHidden = true
    }
}

