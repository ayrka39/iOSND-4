//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by David on 10/9/16.
//  Copyright © 2016 David. All rights reserved.
//

import MapKit
import UIKit
import CoreData

class MapViewController: UIViewController,  UIGestureRecognizerDelegate {
	
	var activeAnnotation: Pin!
	var lastPinTapped: MKPinAnnotationView?
	var coordinate = CLLocationCoordinate2D()
	var initaillyLoaded = false
	var imageFetched = false
	var showMessageButton: UIBarButtonItem!
	let flickrClient = FlickrClient.sharedInstance
	let request: NSFetchRequest<Pin> = Pin.fetchRequest()
	var sharedContext: NSManagedObjectContext {
		return CoreDataStack.sharedInstacne.persistentContainer.viewContext
	}
	
	@IBOutlet weak var mapView: MKMapView!
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		setupToolBar()
		if editing {
			navigationController?.setToolbarHidden(false, animated: true)
		} else {
			navigationController?.setToolbarHidden(true, animated: true)
			mapView.deselectAnnotation(activeAnnotation, animated: false)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		mapViewSetting()
		navBarSetting()
		toolBarSetting()
		longPressRecognized()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		lastPinTapped = nil
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if !initaillyLoaded {
			if let savedRegion = UserDefaults.standard.object(forKey: "savedMapRegion") as? [String: Double] {
				let center = CLLocationCoordinate2D(latitude: savedRegion["mapRegionCenterLat"]!, longitude: savedRegion["mapRegionCenterLon"]!)
				let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapRegionSpanLatDelta"]!, longitudeDelta: savedRegion["mapRegionSpanLonDelta"]!)
				mapView.region = MKCoordinateRegion(center: center, span: span)
			}
			let annotationsToLoad = loadAllPins()
			mapView.addAnnotations(annotationsToLoad)

		}
	}

	func longPressRecognized() {
		let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
		longPressRecognizer.delegate = self
		mapView.addGestureRecognizer(longPressRecognizer)
		
	}
	
	func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
		
		if !isEditing {
			
			let location = gestureRecognizer.location(in: mapView)
			let annotation = MKPointAnnotation()
			annotation.coordinate = coordinate
			coordinate = mapView.convert(location, toCoordinateFrom: mapView)
			
			switch (gestureRecognizer.state) {
			case .began:
				print("ready to add pin")
				return
			case .changed:
				print("coordinate changed")
			case .ended:
				let newAnnotation = Pin(annotation: annotation, context: sharedContext)
				activeAnnotation = newAnnotation
				mapView.addAnnotation(activeAnnotation)
				mapView.removeAnnotation(annotation)
				lookUpLocation(activeAnnotation)
				getPhotosAtLocation(activeAnnotation.coordinate)
				
				do {
					try sharedContext.save()
				} catch {}
	
			default:
				break
			}
			
		}
	}
	
	// determines a string-based location for the user's pin using reverse geocoding
	func lookUpLocation(_ annotation: MKAnnotation) {
		let geocoder = CLGeocoder()
		let location = CLLocation(latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude)
		
		geocoder.reverseGeocodeLocation(location) { [unowned self] (placemarksArray, error) in
			guard let placemarks = placemarksArray else {
				return
			}
			DispatchQueue.main.async(execute: { 
				guard let locality = placemarks[0].locality else {
					return
				}
				self.activeAnnotation.title = locality
				do {
					try self.sharedContext.save()
				} catch { }
			})
		}
	}
	
	// takes a coordinate and executes the flickr search for images
	func getPhotosAtLocation(_ coordinate: CLLocationCoordinate2D) {
		imageFetched = true
		flickrClient.getImagesByLocation(latitude: coordinate.latitude, longitude: coordinate.longitude) { [unowned self] (photoArray, error) in
			DispatchQueue.main.async {
				guard error == nil else {
					print("error")
					return
				}
				guard let photoArray = photoArray else {
					print("No photos why?")
					return
				}
				self.savePhotosToPin(photoArray, pinToSave: self.activeAnnotation)
				self.imageFetched = false
			}
		}
	}
	
	// takes the photo array data from the flickr search
	func savePhotosToPin(_ photoDataToSave: [Dict], pinToSave: Pin) {
		let photoDataMutable = photoDataToSave
	
			for photo in photoDataMutable {
				if let imageURL = photo["url_m"] as? String,
					let photoID = photo["id"] as? String {
					let newPhoto = Photo(imageID: photoID, imagePath: imageURL, context: sharedContext)
					newPhoto.pin = pinToSave
				}
			}
		
		do {
			try sharedContext.save()
		} catch {
			fatalError("error")
		}
	}
	
	func deletePinFromMap() {
		setupToolBar()
		guard let annotationToDelete = activeAnnotation else {
			return
		}
		sharedContext.delete(annotationToDelete)
		do {
			try sharedContext.save()
			mapView.removeAnnotation(annotationToDelete)
		} catch {
			fatalError("error deleting the pin")
		}
		
	}
	
	// loads all the Pins from the persistent store 
	func loadAllPins() -> [Pin] {
		do {
			return try sharedContext.fetch(request)
		} catch {
			return [Pin]()
		}
	}

	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "photoAlbum" {
			if let controller = segue.destination as? PhotoAlbumViewController {
				controller.annotationToShow = activeAnnotation
				if imageFetched {
					controller.loadingText = "retrieving images..."
				}
			}
			
		}
	}
	
	// detect whether the map region was updated
	func mapViewRegionDidChange() -> Bool {
		let view = self.mapView.subviews[0]
		guard let gestureRecognizers = view.gestureRecognizers else {
			return false
		}
		for recognizer in gestureRecognizers {
			let gestureState = UIGestureRecognizerState.self
			if recognizer.state == gestureState.began || recognizer.state == gestureState.ended {
				return true
			}
		}
		return false
	}
}

extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		
		var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") as? MKPinAnnotationView
		
		if pinView == nil {
			pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
			pinView?.animatesDrop = true
		} else {
			pinView?.annotation = annotation
			
		}
		return pinView
	}
	
	func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
		
		guard let annotation = view.annotation, annotation.isKind(of: Pin.self) else {
			return
		}
		lastPinTapped = view as? MKPinAnnotationView
		activeAnnotation = annotation as? Pin
		
		if isEditing {
			self.deletePinFromMap()
			
		} else {
			
			performSegue(withIdentifier: "photoAlbum", sender: view)
			mapView.deselectAnnotation(view.annotation, animated: true)
		}
		
	}
	// gets called when the user changes the zoom or scroll of the map
	func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
		if mapViewRegionDidChange() {
			let regionToSave = [
				"mapRegionCenterLat": mapView.region.center.latitude,
				"mapRegionCenterLon": mapView.region.center.longitude,
				"mapRegionSpanLatDelta": mapView.region.span.latitudeDelta,
				"mapRegionSpanLonDelta": mapView.region.span.longitudeDelta
			]
			UserDefaults.standard.set(regionToSave, forKey: "savedMapRegion")
		}
	}
	
}

