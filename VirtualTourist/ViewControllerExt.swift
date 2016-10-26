//
//  MapView.swift
//  VirtualTourist
//
//  Created by David on 10/9/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit
import MapKit

extension MapViewController {
	
		
	func mapViewSetting() {
		mapView.delegate = self
		mapView.showsScale = true
	}
	
	func navBarSetting() {
		navigationItem.rightBarButtonItem = editButtonItem
		navigationItem.backBarButtonItem = UIBarButtonItem(title: "OK", style: .plain, target: nil, action: nil)
	}
	
	func toolBarSetting() {
		showMessageButton = UIBarButtonItem(title: "Tap pins to delete", style: .plain, target: nil, action: nil)
	}
	
	func setupToolBar() {
		let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		setToolbarItems([spaceButton, showMessageButton, spaceButton], animated: false)
		navigationController?.toolbar.barTintColor = UIColor(red: 243/255, green: 76/255, blue: 76/255, alpha: 1)
		
	}
}

extension PhotoAlbumViewController {
	
	
	enum ButtonType {
		case newCollection
		case deleteImages
	}
	
	func mapViewSetting() {
		mapView.delegate = self
		mapView.showsScale = true
		
	}
	
	func centerMapView() {
		var spanDeltaLatitude: CLLocationDegrees {
			let mapViewRatio = mapView.frame.height / mapView.frame.width
			return 2 * Double(mapViewRatio)
		}
		mapView.region = MKCoordinateRegion(center: annotationToShow.coordinate, span: MKCoordinateSpan(latitudeDelta: spanDeltaLatitude, longitudeDelta: 2))
		
	}
	
	func collectionViewSetting() {

		self.collectionView.delegate = self
		self.collectionView.dataSource = self
	}
	

	func fetchedResultSetting() {
		fetchedResultsController.delegate = self
		
		do {
			try fetchedResultsController.performFetch()
		} catch {
			fatalError("error fetching")
		}
	}
	
	func toolBarSetting() {
		deleteImagesButton = UIBarButtonItem(title: "Remove selected Pictures", style: .plain, target: self, action: #selector(self.removeImages))
		newCollectionButton = UIBarButtonItem(title: "New Collection", style: .plain, target: self, action: #selector(self.getNewCollection))
	}
	
	func setupToolBar(_ buttonToShow: ButtonType) {
		let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		
		switch buttonToShow {
		case .newCollection:
			setToolbarItems([spaceButton, newCollectionButton, spaceButton], animated: false)
			navigationController?.toolbar.barTintColor = nil
		case .deleteImages:
			setToolbarItems([spaceButton, deleteImagesButton, spaceButton], animated: false)
			navigationController?.toolbar.barTintColor = nil
		}
	}
}
