//
//  Photo+CoreDataProperties.swift
//  VirtualTourist
//
//  Created by David on 10/19/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var imageData: Data?
    @NSManaged public var imagePath: String?
    @NSManaged public var imageID: String?
    @NSManaged public var pin: Pin?

}
