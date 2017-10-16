//
//  TouchAblleDropPin.swift
//  MapPixelApp
//
//  Created by Junaid Khan on 08/10/2017.
//  Copyright © 2017 mac. All rights reserved.
//

import UIKit
import MapKit
class TouchAblleDropPin: NSObject, MKAnnotation{
    dynamic var coordinate: CLLocationCoordinate2D
    var identifier : String
    
     init(coordinate:CLLocationCoordinate2D,identifier: String ) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
