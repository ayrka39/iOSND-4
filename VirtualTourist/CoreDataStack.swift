//
//  CoreDataStack.swift
//  VirtualTourist
//
//  Created by David on 10/20/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {

	static let sharedInstacne = CoreDataStack()
	// MARK: - Core Data stack
	
	lazy var persistentContainer: NSPersistentContainer = {
		
		let container = NSPersistentContainer(name: "VirtualTourist")
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		return container
	}()
	
	// MARK: - Core Data Saving support
	
	func saveContext () {
		let context = persistentContainer.viewContext
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				
				let nserror = error as NSError
				fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
			}
		}
	}

}
