//
//  PhotoalbumViewController.swift
//  VirtualTourist
//
//  Created by David on 10/9/16.
//  Copyright © 2016 David. All rights reserved.
//


import MapKit
import UIKit
import CoreData

class PhotoAlbumViewController: UIViewController {
	
	var annotationToShow: Pin!
	let flickrClient = FlickrClient.sharedInstance
	var deleteImagesButton: UIBarButtonItem!
	var newCollectionButton: UIBarButtonItem!
	
	var insertedIndexPaths: [IndexPath]!
	var deletedIndexPaths: [IndexPath]!
	var selectedIndexPaths = [IndexPath]() {
		didSet {
			if selectedIndexPaths.count > 0 {
				setupToolBar(.deleteImages)
			} else {
				setupToolBar(.newCollection)
			}
		}
	}
	var loadingText: String? {
		didSet {
			noPhotosLabel?.text = loadingText
			noPhotosLabel?.isHidden = false
		}
	} 
	var sharedContext: NSManagedObjectContext {
		return CoreDataStack.sharedInstacne.persistentContainer.viewContext
	}
	let sectionInsets = UIEdgeInsets(top: 5.0, left: 4.0, bottom: 5.0, right: 4.0)

	@IBOutlet weak var mapView: MKMapView!
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var noPhotosLabel: UILabel!
	
	
	override func viewDidLoad() {
		super.viewDidLoad()
		noPhotosLabel.isHidden = true
		if loadingText != nil {
			noPhotosLabel.text = loadingText
		}
		collectionViewSetting()
		toolBarSetting()
		fetchedResultSetting()
		setupToolBar(.newCollection)
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		navigationController?.isToolbarHidden = false
		centerMapView()
		mapView.addAnnotation(annotationToShow)
		
		guard let localityName = annotationToShow.title else {
			title = "Photos"
			return
		}
		title = localityName
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		navigationController?.isToolbarHidden = true
	}
	
	
	lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
		let request: NSFetchRequest<Photo> = Photo.fetchRequest()
		request.predicate = NSPredicate.init(format: "pin == %@", self.annotationToShow)
		let sort = NSSortDescriptor(key: "imageID", ascending: true)
		request.sortDescriptors = [sort]
		
		let fetchedResultController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
		return fetchedResultController
	}()
	
	// removes the selected Photo objects from the persistent store
	func removeImages() {
		
		for index in self.selectedIndexPaths {
			let photos = self.fetchedResultsController.object(at: index)
			self.sharedContext.delete(photos)
			print("did you added to delete: \(selectedIndexPaths)")
		}
		// reset selected index paths
		selectedIndexPaths = []
		do {
			if sharedContext.hasChanges {
				try sharedContext.save()
			}
		} catch {
			fatalError("update error")
		}
	}
	
	//gets invoked when the user taps the "New Collection" button
	func getNewCollection() {
		let photos = fetchedResultsController.fetchedObjects!
		for photo in photos {
			sharedContext.delete(photo)
			
		}
		loadingText = "retrieving images..."
		flickrClient.getImagesByLocation(latitude: annotationToShow.latitude, longitude: annotationToShow.longitude) { [unowned self] (photoArray, error) in
			DispatchQueue.main.async {
				guard error == nil else {
					print("error")
					return
				}
				guard let photoArray = photoArray else {
					print("no new photos ")
					return
				}
				
				self.savePhotosToPin(photoArray, pinToSave: self.annotationToShow)
				if photoArray.count == 0 {
					self.loadingText = "No Images Found at this Location."
				}
			}
		}
	}
	
	func savePhotosToPin(_ photoDataToSave: [Dict], pinToSave: Pin) {
		var photoDataMutable = photoDataToSave
		if photoDataMutable.count > 21 {
			for photo in 0...20 {
				if let imageURL = photoDataMutable[photo]["url_m"] as? String,
					let photoID = photoDataMutable[photo]["id"] as? String {
					let newPhoto = Photo(imageID: photoID, imagePath: imageURL, context: sharedContext)
					newPhoto.pin = pinToSave
				}
			}
		} else {
			for photo in photoDataMutable {
				if let imageURL = photo["url_m"] as? String,
					let photoID = photo["id"] as? String {
					let newPhoto = Photo(imageID: photoID, imagePath: imageURL, context: sharedContext)
					newPhoto.pin = pinToSave
				}
			}
		}
		
		do {
			try sharedContext.save()
		} catch {
			fatalError("error")
		}
	}
}

extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
		
	func numberOfSections(in collectionView: UICollectionView) -> Int {
		if let sections = fetchedResultsController.sections {
			return sections.count
		}
		return 1
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		print("photoVC number-3")
		if let sections = fetchedResultsController.sections {
			let currentSection = sections[section]
			if currentSection.numberOfObjects == 0 {
				noPhotosLabel.isHidden = false
			}
			return currentSection.numberOfObjects
		}
		return 1

	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCell
		cell.imageView.image = nil
		
		if let _ = selectedIndexPaths.index(of: indexPath) {
			cell.imageView.alpha = 0.3
		} else {
			cell.imageView.alpha = 1.0
		}
		
		let photos = fetchedResultsController.object(at: indexPath)

			cell.spinner.startAnimating()
			FlickrClient.sharedInstance.getImageByURL(imagePath: photos.imagePath!) { (data, error) in
				guard error == nil else {
					return
				}
				guard let photoData = data else {
					return
				}
				guard let photo = UIImage(data: photoData) else {
					return
				}
				DispatchQueue.main.async {
					cell.imageView.image = photo
					cell.spinner.stopAnimating()
				}
			}
		return cell
	}
	
		
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let selectedCell = collectionView.cellForItem(at: indexPath) as! PhotoCell
		if let index = selectedIndexPaths.index(of: indexPath) {
			selectedCell.imageView.alpha = 1.0
			selectedIndexPaths.remove(at: index)
		} else {
			selectedCell.imageView.alpha = 0.3
			selectedIndexPaths.append(indexPath)
		}
	}
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
	//is invoked which resets the temporary arrays
	func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		insertedIndexPaths = [IndexPath]()
		deletedIndexPaths = [IndexPath]()
		noPhotosLabel.isHidden = true
	}
	//stores all the objects that should be inserted or deleted in one place
	func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
	
		switch type {
		case .insert:
			insertedIndexPaths.append(newIndexPath!)
		case .delete:
			deletedIndexPaths.append(indexPath!)
			
		default:
			break
		}
	}
	//update the collection view to reflect changes all at once
	func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
		
		collectionView.performBatchUpdates({[unowned self] in
			
			for indexPath in self.insertedIndexPaths {
				self.collectionView.insertItems(at: [indexPath])
			}
			for indexPath in self.deletedIndexPaths {
				self.collectionView.deleteItems(at: [indexPath])

			}

			}, completion: nil)
	}
}

extension PhotoAlbumViewController: MKMapViewDelegate {
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		
		let pin = MKPinAnnotationView()
		
		return pin
	}
}

extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout {
	
	
	func collectionView(_ collectionView: UICollectionView,
	                    layout collectionViewLayout: UICollectionViewLayout,
	                    sizeForItemAt indexPath: IndexPath) -> CGSize {
		
		let paddingSpace = sectionInsets.left * (3 + 1)
		let availableWidth = view.frame.width - paddingSpace
		let widthPerItem = availableWidth / 3
		
		return CGSize(width: widthPerItem, height: widthPerItem)
	}
 
	
	func collectionView(_ collectionView: UICollectionView,
	                    layout collectionViewLayout: UICollectionViewLayout,
	                    insetForSectionAt section: Int) -> UIEdgeInsets {
		return sectionInsets
	}
 
	
	func collectionView(_ collectionView: UICollectionView,
	                    layout collectionViewLayout: UICollectionViewLayout,
	                    minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return sectionInsets.left
	}
}
