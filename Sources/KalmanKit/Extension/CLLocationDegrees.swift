//
//  CLLocationDegrees.swift
//  KalmanKit
//
//  Created by El Mostafa El Ouatri on 09/05/25.
//


import CoreLocation

extension CLLocationDegrees {
    
    /// Compares two CLLocationDegrees values for equality with an accuracy tolerance.
    /// - Parameters:
    ///   - value: The `CLLocationDegrees` to compare to.
    ///   - accuracy: The acceptable difference between the two values.
    /// - Returns: A boolean indicating whether the values are equal within the specified accuracy.
    public func equal(to value: CLLocationDegrees, accuracy: CLLocationDegrees) -> Bool {
        abs(self - value) <= accuracy
    }
    
    /// Checks if the current value is close to another value within a specified accuracy.
    /// - Parameters:
    ///   - value: The `CLLocationDegrees` to compare to.
    ///   - accuracy: The acceptable difference between the two values.
    /// - Returns: A boolean indicating whether the values are close within the specified accuracy.
    public func close(to value: CLLocationDegrees, accuracy: CLLocationDegrees) -> Bool {
        abs(self - value) <= accuracy
    }
    
    /// Checks if the current value is less than another value.
    /// - Parameter value: The `CLLocationDegrees` to compare to.
    /// - Returns: A boolean indicating whether the current value is less than the provided value.
    public func less(than value: CLLocationDegrees) -> Bool {
        self < value
    }
    
    /// Checks if the current value is greater than another value.
    /// - Parameter value: The `CLLocationDegrees` to compare to.
    /// - Returns: A boolean indicating whether the current value is greater than the provided value.
    public func greater(than value: CLLocationDegrees) -> Bool {
        self > value
    }
}
