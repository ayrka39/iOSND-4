//
//  Photo+CoreDataClass.swift
//  VirtualTourist
//
//  Created by David on 10/19/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import CoreData
import UIKit


public class Photo: NSManagedObject {
	
	
	override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?){
		super.init(entity: entity, insertInto: context)
	}
	
	init(imageID: String, imagePath: String, context: NSManagedObjectContext) {
		
		let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context)!
		super.init(entity: entity, insertInto: context)
		
		self.imageID = imageID
		self.imagePath = imagePath
		
	}
	

}
