//
//  CLLocationCoordinate2D-Extension.swift
//  A1_A2_iOS_Pennapar_c0874203
//
//  Created by Alice’z Poy on 2023-01-20.
//

import Foundation
import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        
        let maxLat = lhs.latitude + 0.005
        let minLat = lhs.latitude - 0.005
        
        let maxLong = lhs.longitude + 0.005
        let minLong = lhs.longitude - 0.005
        
        return (maxLat >= rhs.latitude && rhs.latitude > minLat ) && (maxLong >= rhs.longitude && rhs.longitude > minLong)
    }
}
