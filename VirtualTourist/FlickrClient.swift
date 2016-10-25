//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by David on 10/10/16.
//  Copyright © 2016 David. All rights reserved.
//

import UIKit
import Foundation

class FlickrClient {
	
	static let sharedInstance = FlickrClient()
	
	let keys = Constants.FlickrParameterKeys.self
	let values = Constants.FlickrParameterValues.self
	let responseKeys = Constants.FlickrResponseKeys.self
	
	func getImageByURL(imagePath: String, completionHandlerForImage: @escaping (_ imageData: Data?, _ error: NSError?) -> Void) {
		
		let url = URL(string: imagePath)!
		let request = URLRequest(url: url)
		
		let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
			guard error == nil else {
				print("error: \(error)")
				return
			}
			guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
				print("request returned a status code other than 2xx")
				return
			}
			guard let data = data else {
				print("no data")
				return
			}
			completionHandlerForImage(data, nil)
		}
		task.resume()
	}
	
	
	func getImagesByLocation(latitude: Double, longitude: Double, completionHandlerForImageByLocation: @escaping (_ photoArr: [Dict]?, _ error: NSError?) -> Void) {
		
		taskForGetMethod(latitude: latitude, longitude: longitude, pageNumber: nil) { (result, error) in
			
			guard error == nil else {
				completionHandlerForImageByLocation(nil, error)
				return
			}
			
			guard let photosDict = result?[self.responseKeys.Photos] as? Dict,
					let photoArr = photosDict[self.responseKeys.Photo] as? [Dict],
					let numPages = photosDict[self.responseKeys.Pages] as? Int else {
				completionHandlerForImageByLocation(nil, error)
				return
			}
			if numPages == 1 {
				print("only one page")
				completionHandlerForImageByLocation(photoArr, nil)
			} else {
				let randomPageNumber = Int(arc4random_uniform(UInt32(numPages))) + 1
				self.getPageNumber(latitude: latitude, longitude: longitude, pageNumber: randomPageNumber, completionHandlerForPageNumber: completionHandlerForImageByLocation)
			}
			
			print("randomPage0: \(numPages)")
			
		}
		
	}
	
	func getPageNumber(latitude: Double, longitude: Double, pageNumber: Int?, completionHandlerForPageNumber: @escaping (_ photoArr: [Dict]?, _ error: NSError?) -> Void) {
		
		taskForGetMethod(latitude: latitude, longitude: longitude, pageNumber: pageNumber) { (result, error) in
			guard error == nil else {
				print("error")
				return
			}
			guard let photoDict = result?[self.responseKeys.Photos] as? Dict,
				let photoArr = photoDict[self.responseKeys.Photo] as? [Dict] else {
					completionHandlerForPageNumber(nil, error)
					return
			}
			completionHandlerForPageNumber(photoArr, nil)
		}
	}

	
	func taskForGetMethod(latitude: Double, longitude: Double, pageNumber: Int?, completionHandlerForGet: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
		
		let imageURL = getflickrURL(latitude: latitude, longitude: longitude, pageNumber: pageNumber)
		let request = NSMutableURLRequest(url: imageURL)
		
		let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
			guard error == nil else {
				print("an error with request: \(error)")
				return
			}
			guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
				print("request returned a status code other than 2xx:")
				return
			}
			guard let data = data else {
				print("no data was returned")
				return
			}
			self.parseData(data, completionHandlerForParseData: completionHandlerForGet)
		}
		task.resume()
		
	}
	
	fileprivate func getflickrURL(latitude: Double, longitude: Double, pageNumber: Int?) -> URL {
		
		var parameters: [String: AnyObject] = [
			keys.Method: values.SearchMethod as AnyObject,
			keys.APIKey: values.APIKey as AnyObject,
			keys.Latitude: latString(latitude: latitude) as AnyObject,
			keys.Longitude: lonString(longitude: longitude) as AnyObject,
			keys.Extras: values.MediumURL as AnyObject,
			keys.PerPage: values.PerPage as AnyObject,
			keys.Format: values.ResponseFormat as AnyObject,
			keys.NoJSONCallback: values.DisableJSONCallback as AnyObject
		]
		
		if let pageNumber = pageNumber {
			parameters[keys.Page] = pageNumber as AnyObject?
		}
		
		var components = URLComponents()
		components.scheme = Constants.Flickr.APIScheme
		components.host = Constants.Flickr.APIHost
		components.path = Constants.Flickr.APIPath
		components.queryItems = [URLQueryItem]()
		
		for (key, value) in parameters {
			let queryItem = URLQueryItem(name: key, value: "\(value)")
			components.queryItems!.append(queryItem)
		}
		print("url is here: \(components.url!)")
		return components.url!
		
	}
	
	fileprivate func parseData(_ data: Data, completionHandlerForParseData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
		
		var jsonResult: AnyObject?
		do {
			jsonResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject?
		} catch {
			print("could not parse the data")
		}
		
		completionHandlerForParseData(jsonResult, nil)
	}
	
	fileprivate func latString(latitude: Double?) -> String {
		guard let latitude = latitude else {
			return "0"
		}
		return "\(latitude)"
	}
	
	fileprivate func lonString(longitude: Double?) -> String {
		guard let longitude = longitude else {
			return "0"
		}
		return "\(longitude)"
	}
	
}



