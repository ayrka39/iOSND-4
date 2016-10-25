//
//  Pin+CoreDataClass.swift
//  VirtualTourist
//
//  Created by David on 10/19/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import CoreData
import MapKit


public class Pin: NSManagedObject, MKAnnotation {
	
	public var coordinate: CLLocationCoordinate2D {
		return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
	}
	
	override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
		super.init(entity: entity, insertInto: context)
	}
	
	init(annotation: MKPointAnnotation, context: NSManagedObjectContext) {
		let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context)!
		
		super.init(entity: entity, insertInto: context)
		
		latitude = annotation.coordinate.latitude as Double
		longitude = annotation.coordinate.longitude as Double 
		title = annotation.title
	}

}
