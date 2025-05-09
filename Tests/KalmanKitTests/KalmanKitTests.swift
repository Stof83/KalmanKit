
import CoreLocation
import Testing
@testable import KalmanKit

extension Tag {
    @Tag static var filters: Self
}

@Suite
struct KalmanFilterTests {

    @Test("Initial correction returns valid CLLocation")
    func testInitialCorrection() {
        let startLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0703, longitude: 7.6869), // Piazza Castello, Torino
            altitude: 240.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )

        let kalman = KalmanFilter(startLocation)
        let filtered = kalman.process(startLocation)

        #expect(filtered.coordinate.latitude.equal(to: startLocation.coordinate.latitude, accuracy: 0.0001))
        #expect(filtered.coordinate.longitude.equal(to: startLocation.coordinate.longitude, accuracy: 0.0001))
        #expect(filtered.altitude.equal(to: startLocation.altitude, accuracy: 0.1))
    }

    @Test("Kalman Filter smooths minor variation")
    func testSmoothingEffect() {
        let startLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0703, longitude: 7.6869), // Piazza Castello
            altitude: 240.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )

        let kalman = KalmanFilter(startLocation)

        let noisyLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0705, longitude: 7.6867), // Slight variation nearby
            altitude: 241.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date().addingTimeInterval(1.0)
        )

        let smoothed = kalman.process(noisyLocation)

        #expect(smoothed.coordinate.latitude.close(to: 45.0704, accuracy: 0.0001))
        #expect(smoothed.coordinate.longitude.close(to: 7.6868, accuracy: 0.0001))
        #expect(smoothed.altitude.close(to: 240.5, accuracy: 0.1))

    }

    @Test("Resetting filter restarts the state")
    func testResetKalmanFilter() {
        let startLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0703, longitude: 7.6869),
            altitude: 240.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )

        let kalman = KalmanFilter(startLocation)

        let newStart = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0627, longitude: 7.6784), // Porta Nuova station
            altitude: 250.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )

        kalman.reset(newStart)
        let result = kalman.process(newStart)

        #expect(result.coordinate.latitude.equal(to: newStart.coordinate.latitude, accuracy: 0.0001))
        #expect(result.coordinate.longitude.equal(to: newStart.coordinate.longitude, accuracy: 0.0001))
        #expect(result.altitude.equal(to: newStart.altitude, accuracy: 0.1))
    }

    @Test("Custom sensor noise affects output")
    func testCustomSensorNoise() {
        let startLocation = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0703, longitude: 7.6869),
            altitude: 240.0,
            horizontalAccuracy: 5.0,
            verticalAccuracy: 5.0,
            timestamp: Date()
        )

        let kalman = KalmanFilter(startLocation)
        
        kalman.setSensorNoiseCovariance(50)

        let location = CLLocation(
            coordinate: CLLocationCoordinate2D(latitude: 45.0710, longitude: 7.6880), // Giardini Reali
            altitude: 242.0,
            horizontalAccuracy: 10.0,
            verticalAccuracy: 10.0,
            timestamp: Date().addingTimeInterval(2.0)
        )

        let output = kalman.process(location)

        #expect(output.coordinate.latitude.less(than: location.coordinate.latitude))
        #expect(output.coordinate.longitude.less(than: location.coordinate.longitude))
    }
}

