//
//  Constants.swift
//  MapPixelApp
//
//  Created by Junaid Khan on 10/10/2017.
//  Copyright © 2017 mac. All rights reserved.
//

import Foundation
let API_KEY = "4ba1e5fd585ca180ba9d4a5a20190670"
func flickrURL(forApiKey api: String, withAnnotation annotation : TouchAblleDropPin, numberOfPhotos number: Int) -> String
{
  return"https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
}
