//
//  LocationHandler.swift
//  KalmanKit
//
//  Created by El Mostafa El Ouatri on 09/05/25.
//


/// `KalmanFilter` provides a mathematical technique to estimate the true position of a moving object
/// by reducing noise from GPS signals. This implementation is suitable for smoothing GPS trajectories
/// in real-time by applying a 6-dimensional Kalman filter model (position and velocity in latitude,
/// longitude, and altitude).
///
/// The filter maintains state continuity across measurements and compensates for measurement noise
/// through a prediction-correction cycle using the state transition matrix, noise covariance, and Kalman gain.
///
/// ### Key Components
/// - **State Vector (x):** Contains latitude, latitude velocity, longitude, longitude velocity, altitude, altitude velocity.
/// - **Prediction Matrix (A):** Models motion over time based on elapsed intervals.
/// - **Process Noise Covariance (Qt):** Reflects model uncertainty, scaled by acceleration noise.
/// - **Sensor Noise Covariance (R):** Represents GPS noise, adjustable for accuracy tuning.
/// - **Kalman Gain (K):** Weighs prediction vs. measurement reliability.
///
/// ### Usage
/// 1. **Import the KalmanKit module**
/// ```swift
/// import KalmanKit
/// ```
///
/// 2. **Initialize the filter with an initial location**
/// ```swift
/// let kalmanFilter = KalmanFilter(initialLocation: myInitialLocation)
/// ```
/// - `myInitialLocation`: CLLocation representing the starting point.
///
/// 3. **(Optional) Adjust sensor noise to suit your accuracy needs**
/// ```swift
/// kalmanFilter.sensorNoiseCovariance = 35.0
/// ```
/// - Higher values produce smoother but less responsive output.
/// - Lower values increase responsiveness but may amplify noise.
///
/// 4. **Process each new location measurement**
/// ```swift
/// let filteredLocation = kalmanFilter.processState(currentLocation: latestGPSReading)
/// ```
/// - `latestGPSReading`: A raw `CLLocation` from GPS.
/// - `filteredLocation`: A smoothed `CLLocation` suitable for display or analysis.
///
/// 5. **Restart the filter when resuming tracking from a fresh starting point**
/// ```swift
/// kalmanFilter.resetKalmanFilter(newStartLocation: freshStartLocation)
/// ```
///
/// ### Example
/// ```swift
/// class LocationHandler: NSObject, CLLocationManagerDelegate {
///     private var kalmanFilter: KalmanFilter?
///     private var shouldResetFilter = false
///     private let locationManager = CLLocationManager()
/// 
///     override init() {
///         super.init()
///         locationManager.delegate = self
///         locationManager.requestWhenInUseAuthorization()
///         locationManager.startUpdatingLocation()
///     }
/// 
///     func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
///         guard let currentLocation = locations.first else { return }
/// 
///         if kalmanFilter == nil {
///             kalmanFilter = KalmanFilter(initialLocation: currentLocation)
///             return
///         }
///
///         if shouldResetFilter {
///             kalmanFilter?.resetKalmanFilter(newStartLocation: currentLocation)
///             shouldResetFilter = false
///             return
///         }
///
///         if let smoothedLocation = kalmanFilter?.processState(currentLocation: currentLocation) {
///             print("Smoothed Coordinate: \(smoothedLocation.coordinate)")
///         }
///     }
/// }
/// 
