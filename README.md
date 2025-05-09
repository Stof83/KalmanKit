
# KalmanKit

[![Swift](https://img.shields.io/badge/Swift-6.1-orange?style=flat-square)](https://img.shields.io/badge/Swift-6.1-Orange?style=flat-square)
[![Platforms](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_visionOS-green?style=flat-square)](https://img.shields.io/badge/Platforms-macOS_iOS_tvOS_watchOS_vision_OS_Linux_Windows_Android-Green?style=flat-square)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)](https://img.shields.io/badge/Swift_Package_Manager-compatible-orange?style=flat-square)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](https://github.com/Stof83/KalmanKit/blob/main/LICENSE)

A high-precision Kalman Filter for smoothing GPS coordinates (latitude, longitude, altitude) and reducing noise from CLLocationManager updates in iOS applications.

## Overview

Kalman Filters are recursive estimators ideal for noisy sensor data—especially location data from mobile devices. This implementation models position and velocity in a six-dimensional state space and adjusts predictions over time to improve location tracking fidelity.

## Features

- ✅ Supports 6D state modeling: position and velocity for latitude, longitude, and altitude
- ✅ Tunable sensor and acceleration noise parameters
- ✅ Swift-native and ready for integration with `CLLocationManager`
- ✅ Designed for real-time, recursive updates

### Requirements

- iOS 14.0+ / macOS 11+ / tvOS 14+ / watchOS 7+ / macCatalyst 14+
- Swift 6.1+

### Installation

Use Swift Package Manager:

```swift
// swift-tools-version:6.1

import PackageDescription

let package = Package(
    name: "YourPackageName",
    dependencies: [
        .package(url: "https://github.com/Stof83/KalmanKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
                name: "YourTargetName",
                dependencies: [
                    .product(name: "KalmanKit", package: "KalmanKit")
                ]
        )
    ]
)
```

---

## Documentation

### `init` Parameters:

- **`initialLocation`**: 
    The initial `CLLocation` object representing the starting location of the filter. This is used to set the initial state of the filter (e.g., position and velocity).

### Public Methods:

#### `process(_ currentLocation: CLLocation) -> CLLocation`

- **Parameters**: A `CLLocation` object representing the latest GPS location.
- **Returns**: A corrected `CLLocation` object with reduced noise.
- **Description**: This method processes a new location update and returns a location with reduced noise using the Kalman filter algorithm.

#### `setSensorNoiseCovariance(_ newValue: Double)`

- **Parameters**: A new value (`Double`) to adjust the sensor noise covariance.
- **Description**: This setter function allows modification of the sensor noise covariance. Higher values result in smoother paths but may lag behind sharp movements.

#### `reset(_ newStartLocation: CLLocation)`

- **Parameters**: A `CLLocation` object representing the new location to reset the filter with.
- **Description**: Resets the Kalman filter with a new initial location. Useful for restarting tracking when signal is lost or tracking resumes after a pause.

---

## Usage

### 1. Initialization

```swift
let filter = await KalmanFilter(location)
```

Pass an initial `CLLocation` object to bootstrap the filter.

### 2. Processing New Location Updates

```swift
let correctedLocation = await filter.process(newLocation)
```

Pass each new GPS reading to the filter. The return value is a noise-reduced `CLLocation`.

### 3. Resetting the Filter

```swift
await filter.reset(newStartlocation)
```

Useful for resetting state if tracking resumes after a pause or signal loss.

## Configuration

### Sensor Noise

```swift
filter.setSensorNoiseCovariance(50.0)
```

Higher values smooth the output more but may lag behind sharp movements.

## Example

```swift
import CoreLocation
import KalmanKit

class LocationHandler: NSObject, CLLocationManagerDelegate {
    private var kalmanFilter: KalmanFilter?
    private var shouldResetFilter = false
    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.first else { return }

        Task {
            if kalmanFilter == nil {
                kalmanFilter = await KalmanFilter(currentLocation)
                return
            }

            if shouldResetFilter {
                await kalmanFilter?.reset(currentLocation)
                shouldResetFilter = false
                return
            }

            if let smoothedLocation = await kalmanFilter?.process(currentLocation) {
                print("Smoothed Coordinate: \(smoothedLocation.coordinate)")
            }
        }
    }
}
```

## License

This SDK is provided under the MIT License. [See LICENSE](https://github.com/Stof83/KalmanKit/blob/main/LICENSE) for details.
Feel free to use, modify, and distribute it as per the terms of the license.


---

## Contributing

Contributions are welcome! Please open issues and submit pull requests for features, fixes, or improvements.

---
