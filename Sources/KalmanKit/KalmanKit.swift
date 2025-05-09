//
//  KalmanKit.swift
//  KalmanKit
//
//  Created by El Mostafa El Ouatri on 09/05/25.
//

import Foundation
import MapKit
import Surge

/// A Kalman Filter implementation for improving GPS-based location accuracy.
///
/// This class smooths noisy location updates from `CLLocationManager` using a six-dimensional Kalman Filter model.
/// It tracks latitude, longitude, and altitude with corresponding velocity components, and applies a prediction-correction cycle to return
/// a more stable and reliable estimate of location.
///
/// ## Key Features:
/// - Models location and velocity for latitude, longitude, and altitude
/// - Incorporates a sensor noise covariance matrix that can be tuned for different GPS sensitivity needs
/// - Adjustable acceleration noise to suit environment-specific signal variance
/// - Includes methods to reset and reinitialize the filter at any point
///
/// ## Typical Usage:
/// 1. Initialize with a starting location.
/// 2. Optionally set the sensor noise covariance if the default is suboptimal.
/// 3. Call `process(_ location:)` with new location updates.
/// 4. Use the returned location as your corrected result.
/// 5. Reset the filter using `reset(_ location:)` if tracking is interrupted.
///
/// See the included README or the sample code below for practical integration.
open class KalmanFilter {
    // MARK: - Private properties
    
    /// The dimension M of the state vector.
    private let stateVectorDimension = 6
    
    /// The dimension N of the state vector.
    private let sensorMeasurementDimension = 1
    
    /// Acceleration variance magnitude for GPS
    /// =======================================
    /// **Sigma** value is  value for Acceleration Noise Magnitude Matrix (Qt).
    /// Recommended value for accelerationNoiseSigma is 0.0625, this value is optimal for GPS problem,
    /// it was concluded by researches.
    private let accelerationNoiseSigma = 0.0625
    
    /// Value for Sensor Noise Covariance Matrix
    /// ========================================
    /// Default value is 29.0, this is the recommended value for the GPS problem, with this value filter provides optimal accuracy.
    /// This value can be adjusted depending on the needs, the higher value
    /// of defaultSensorNoiseCovariance variable will give greater roundness trajectories, and vice versa.
    private var defaultSensorNoiseCovariance: Double = 29.0
    
    /// Previous State Vector
    /// =====================
    /// **Previous State Vector** is mathematical representation of previous state of Kalman Algorithm.
    private var previousStateVector: MatrixObject
    
    
    /// Covariance Matrix for Previous State
    /// ====================================
    /// **Covariance Matrix for Previous State** is mathematical representation of covariance matrix for previous state of Kalman Algorithm.
    private var previousStateCovariance: MatrixObject
    
    
    /// Prediction Step Matrix
    /// ======================
    /// **Prediction Step Matrix (A)** is mathematical representation of prediction step of Kalman Algorithm.
    /// Prediction Matrix gives us our next state. It takes every point in our original estimate and moves it to a new predicted location,
    /// which is where the system would move if that original estimate was the right one.
    private var predictionStep: MatrixObject
    
    
    /// Acceleration Noise Magnitude Matrix
    /// ===================================
    /// **Acceleration Noise Magnitude Matrix (Qt)** is mathematical representation of external uncertainty of Kalman Algorithm.
    /// The uncertainty associated can be represented with the “world” (i.e. things we aren’t keeping track of)
    /// by adding some new uncertainty after every prediction step.
    private var accelerationNoiseMagnitude: MatrixObject
    
    
    /// Sensor Noise Covariance Matrix
    /// ==============================
    /// **Sensor Noise Covariance Matrix (R)** is mathematical representation of sensor noise of Kalman Algorithm.
    /// Sensors are unreliable, and every state in our original estimate might result in a range of sensor readings.
    private var sensorNoiseCovariance: MatrixObject
    
    /// Measured State Vector
    /// =====================
    /// **Measured State Vector (zt)** is mathematical representation of measuerd state vector of Kalman Algorithm.
    /// Value of this variable was readed from sensor, this is mean value to the reading we observed.
    private var measuredStateVector: MatrixObject!
    
    /// Time of last measurement
    /// ========================
    /// This time is used for calculating the time interval between previous and last measurements
    private var previousMeasureTime = Date()
    
    /// Previous State Location
    private var previousLocation = CLLocation()
    
    
    // MARK: - KalmanFilter initialization
    
    /// Initializes a new `KalmanFilter` with configurable parameters for sensor noise, state vector, and measurement dimensions.
    ///
    /// - Parameters:
    ///   - initialLocation: The initial `CLLocation` object representing the starting location of the filter. This is used to set the initial state of the filter (e.g., position and velocity).
    ///
    /// - Notes:
    ///   - This `init` method performs asynchronous initialization because some of the matrix computations require awaiting tasks or potentially expensive computations.
    ///
    /// - Example:
    /// ```swift
    /// let kalmanFilter = await KalmanFilter(location)
    /// ```
    public init(_ initialLocation: CLLocation) {
        self.previousMeasureTime = Date()
        self.previousLocation = CLLocation()
        
        self.previousStateVector = MatrixObject(rows: stateVectorDimension, columns: sensorMeasurementDimension)
        self.previousStateCovariance = MatrixObject(rows: stateVectorDimension, columns: stateVectorDimension)
        self.predictionStep = MatrixObject(rows: stateVectorDimension, columns: stateVectorDimension)
        self.accelerationNoiseMagnitude = MatrixObject(rows: stateVectorDimension, columns: stateVectorDimension)
        self.sensorNoiseCovariance = MatrixObject(rows: stateVectorDimension, columns: stateVectorDimension)
        self.measuredStateVector = MatrixObject(rows: stateVectorDimension, columns: sensorMeasurementDimension)
        
        initialize(initialLocation)
    }
    
    // MARK: - Public Methods
    
    /// Public setter function to modify the sensor noise covariance parameter.
    /// - parameter newValue: The new value for the sensor noise covariance.
    /// This value is used in the Sensor Noise Covariance Matrix (R) and controls the smoothness of the filter.
    /// Higher values result in smoother trajectories but less responsiveness.
    public func setSensorNoiseCovariance(_ newValue: Double) {
        defaultSensorNoiseCovariance = newValue
    }

    /// Restart Kalman Algorithm Function
    /// ===========================================
    /// This restart Kalman filter matrices to the default values
    /// - parameters:
    ///   - newStartLocation: this is CLLocation object which represent location
    ///                       at the moment when algorithm start again
    public func reset(_ newStartLocation: CLLocation) {
        initialize(newStartLocation)
    }
    
    /// Process Current Location
    /// ========================
    ///  This function is a main. **processState** will be processed current location of user by Kalman Filter
    ///  based on previous state and other parameters, and it returns corrected location
    /// - parameters:
    ///   - currentLocation: this is CLLocation object which represent current location returned by GPS.
    ///                      **currentLocation** is real position of user, and it will be processed by Kalman Filter.
    /// - returns: CLLocation object with corrected latitude, longitude and altitude values
    
    public func process(_ currentLocation: CLLocation) -> CLLocation {
        // Set current timestamp
        let newMeasureTime = currentLocation.timestamp
        
        // Convert measure times to seconds
        let newMeasureTimeSeconds = newMeasureTime.timeIntervalSince1970
        let lastMeasureTimeSeconds = previousMeasureTime.timeIntervalSince1970
        
        // Calculate timeInterval between last and current measure
        let timeInterval = newMeasureTimeSeconds - lastMeasureTimeSeconds
        
        // Avoid divide-by-zero or instability
        guard timeInterval > 0.0001 else { return previousLocation }
        
        // Calculate and set Prediction Step Matrix based on new timeInterval value
        predictionStep.set(matrix: [
            [1,Double(timeInterval),0,0,0,0],
            [0,1,0,0,0,0],
            [0,0,1,Double(timeInterval),0,0],
            [0,0,0,1,0,0],
            [0,0,0,0,1,Double(timeInterval)],
            [0,0,0,0,0,1]
        ])
        
        // Parts of Acceleration Noise Magnitude Matrix
        let part1 = accelerationNoiseSigma * (Double(pow(Double(timeInterval), Double(4))) / 4.0)
        let part2 = accelerationNoiseSigma * (Double(pow(Double(timeInterval), Double(3))) / 2.0)
        let part3 = accelerationNoiseSigma * (Double(pow(Double(timeInterval), Double(2))))
        
        // Calculate and set Acceleration Noise Magnitude Matrix based on new timeInterval and sigma values
        accelerationNoiseMagnitude.set(matrix: [
            [part1,part2,0.0,0.0,0.0,0.0],
            [part2,part3,0.0,0.0,0.0,0.0],
            [0.0,0.0,part1,part2,0.0,0.0],
            [0.0,0.0,part2,part3,0.0,0.0],
            [0.0,0.0,0.0,0.0,part1,part2],
            [0.0,0.0,0.0,0.0,part2,part3]
        ])
        
        // Calculate velocity components
        // This is value of velocity between previous and current location.
        // Distance traveled from the previous to the current location divided by timeInterval between two measurement.
        let velocityXComponent = (previousLocation.coordinate.latitude - currentLocation.coordinate.latitude) / timeInterval
        let velocityYComponent = (previousLocation.coordinate.longitude - currentLocation.coordinate.longitude) / timeInterval
        let velocityZComponent = (previousLocation.altitude - currentLocation.altitude) / timeInterval
        
        // Set Measured State Vector; current latitude, longitude, altitude and latitude velocity, longitude velocity and altitude velocity
        measuredStateVector.set(matrix: [
            [currentLocation.coordinate.latitude],
            [velocityXComponent],
            [currentLocation.coordinate.longitude],
            [velocityYComponent],
            [currentLocation.altitude],
            [velocityZComponent]
        ])
        
        // Set previous Location and Measure Time for next step of processState function.
        previousLocation = currentLocation
        previousMeasureTime = newMeasureTime
        
        // Return value of kalmanFilter
        return filter()
    }
    
    /// Kalman Filter Function
    /// ======================
    /// This is additional function, which helps in the process of correcting location
    /// Here happens the whole mathematics related to Kalman Filter. Here is the essence.
    /// The algorithm consists of two parts - Part of Prediction and Part of Update State
    ///
    /// Prediction part performs the prediction of the next state based on previous state, prediction matrix (A) and takes into consideration
    /// external uncertainty factor (Qt). It returns predicted state and covariance matrix -> xk, Pk
    ///
    /// Next step is Update part. It combines predicted state with sensor measurement. Update part first calculate Kalman gain (Kt).
    /// Kalman gain takes into consideration sensor noice. Next based on this value, value of predicted state and value of measurement,
    /// algorithm can calculate new state, and function return corrected latitude, longitude and altitude values in CLLocation object.
    private func filter() -> CLLocation {
        let predictedStateVector = predictionStep * previousStateVector
        let predictedStateCovariance = ((predictionStep * previousStateCovariance)! * predictionStep.transpose()!)! + accelerationNoiseMagnitude

        let innovationCovariance = predictedStateCovariance! + sensorNoiseCovariance

        // Kalman gain
        let kalmanGain = predictedStateCovariance! * (innovationCovariance?.inverse())!

        let updatedStateVector = predictedStateVector! + (kalmanGain! * (measuredStateVector - predictedStateVector!)!)!
        let updatedStateCovariance = (MatrixObject.identity(dimension: stateVectorDimension) - kalmanGain!)! * predictedStateCovariance!

        self.previousStateVector = updatedStateVector!
        self.previousStateCovariance = updatedStateCovariance!
        
        let latitude = previousStateVector.matrix[0,0]
        let longitude = previousStateVector.matrix[2,0]
        let altitude = previousStateVector.matrix[4,0]
        
        return CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: latitude,longitude: longitude),
            altitude: altitude,
            horizontalAccuracy: self.previousLocation.horizontalAccuracy,
            verticalAccuracy: self.previousLocation.verticalAccuracy,
            timestamp: previousMeasureTime
        )
    }
    // MARK: - HCKalmanAlgorithm functions
    
    /// Initialization of Kalman Algorithm Function
    /// ===========================================
    /// This set up Kalman filter matrices to the default values
    /// - parameters:
    ///   - initialLocation: this is CLLocation object which represent initial location
    ///                      at the moment when algorithm start
    private func initialize(_ initialLocation: CLLocation) {
        // Set timestamp for start of measuring
        previousMeasureTime = initialLocation.timestamp
        
        // Set initial location
        previousLocation = initialLocation
        
        // Set Previous State Matrix
        // previousStateVector -> [ initial_lat  lat_velocity = 0.0  initial_lon  lon_velocity = 0.0 initial_altitude altitude_velocity = 0.0 ]T
        previousStateVector.set(matrix: [
            [initialLocation.coordinate.latitude],
            [0.0],
            [initialLocation.coordinate.longitude],
            [0.0],
            [initialLocation.altitude],
            [0.0]])
        
        // Set initial Covariance Matrix for Previous State
        previousStateCovariance.set(matrix: [
            [1.0,0.0,0.0,0.0,0.0,0.0],
            [0.0,1.0,0.0,0.0,0.0,0.0],
            [0.0,0.0,1.0,0.0,0.0,0.0],
            [0.0,0.0,0.0,1.0,0.0,0.0],
            [0.0,0.0,0.0,0.0,1.0,0.0],
            [0.0,0.0,0.0,0.0,0.0,1.0]
        ])
        
        // Prediction Step Matrix initialization
        predictionStep.set(matrix: [
            [1.0,0.0,0.0,0.0,0.0,0.0],
            [0.0,1.0,0.0,0.0,0.0,0.0],
            [0.0,0.0,1.0,0.0,0.0,0.0],
            [0.0,0.0,0.0,1.0,0.0,0.0],
            [0.0,0.0,0.0,0.0,1.0,0.0],
            [0.0,0.0,0.0,0.0,0.0,1.0]
        ])
        
        // Sensor Noise Covariance Matrixinitialization
        sensorNoiseCovariance.set(matrix: [
            [defaultSensorNoiseCovariance,0,0,0,0,0],
            [0,defaultSensorNoiseCovariance,0,0,0,0],
            [0,0,defaultSensorNoiseCovariance,0,0,0],
            [0,0,0,defaultSensorNoiseCovariance,0,0],
            [0,0,0,0,defaultSensorNoiseCovariance,0],
            [0,0,0,0,0,defaultSensorNoiseCovariance]
        ])
    }

}
