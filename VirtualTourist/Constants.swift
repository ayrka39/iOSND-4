//
//  Constants.swift
//  VirtualTourist
//
//  Created by David on 10/10/16.
//  Copyright © 2016 David. All rights reserved.
//

import Foundation

extension FlickrClient {
	
	// MARK: - Constants
	
	struct Constants {
		
		// MARK: Flickr
		struct Flickr {
			static let APIScheme = "https"
			static let APIHost = "api.flickr.com"
			static let APIPath = "/services/rest"
			
		}
		
		// MARK: Flickr Parameter Keys
		struct FlickrParameterKeys {
			static let Method = "method"
			static let APIKey = "api_key"
			static let Latitude = "lat"
			static let Longitude = "lon"
			static let Extras = "extras"
			static let PerPage = "per_page"
			static let Page = "page"
			static let Format = "format"
			static let NoJSONCallback = "nojsoncallback"
		}
		
		// MARK: Flickr Parameter Values
		struct FlickrParameterValues {
			static let SearchMethod = "flickr.photos.search"
			static let APIKey = "89aa0e2e7004da997f8a4dab2b08c930"
			static let ResponseFormat = "json"
			static let DisableJSONCallback = "1" 
			static let MediumURL = "url_m"
			static let PerPage = "21"
			
		}
		
		// MARK: Flickr Response Keys
		struct FlickrResponseKeys {
			static let Photos = "photos"
			static let Photo = "photo"
			static let Title = "title"
			static let ID = "id"
			static let MediumURL = "url_m"
			static let Pages = "pages"
			static let Total = "total"
		}
		
	}
}

typealias Dict = [String: AnyObject]

