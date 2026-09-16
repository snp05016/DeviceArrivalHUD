import XCTest
@testable import DeviceArrivalHUDLib

final class DeviceArrivalHUDTests: XCTestCase {
    func testSaumyasRealBluetoothNamesMatchDefaults() {
        let devices = DeviceArrivalConfiguration.saumyaDefaults
        XCTAssertEqual(devices.first(where: { $0.matches(bluetoothName: "Saumya’s AirPods Pro") })?.id, "saumya-airpods-pro")
        XCTAssertEqual(devices.first(where: { $0.matches(bluetoothName: "Saumya’s XM4s") })?.id, "saumya-xm4")
        XCTAssertEqual(devices.first(where: { $0.matches(bluetoothName: "ProtoArc K100-A") })?.id, "protoarc-k100-a")
    }

    func testConnectionTrackerIgnoresBaselineThenReportsBothDirections() {
        var tracker = ConnectionStateTracker()
        XCTAssertNil(tracker.ingest(ConnectionSnapshot(connectedDeviceIDs: ["keyboard"])))

        let arrival = tracker.ingest(ConnectionSnapshot(connectedDeviceIDs: ["keyboard", "airpods"]))
        XCTAssertEqual(arrival?.connected, ["airpods"])
        XCTAssertTrue(arrival?.disconnected.isEmpty == true)

        let departure = tracker.ingest(ConnectionSnapshot(connectedDeviceIDs: ["airpods"]))
        XCTAssertEqual(departure?.disconnected, ["keyboard"])
        XCTAssertTrue(departure?.connected.isEmpty == true)
    }

    func testConnectedAnimationMovesForwardAndFadesAtEnd() {
        let early = AnimationTimeline(event: .connected, elapsed: 0.2)
        let late = AnimationTimeline(event: .connected, elapsed: 1.8)
        let end = AnimationTimeline(event: .connected, elapsed: AnimationTimeline.totalDuration)
        XCTAssertLessThan(early.mechanism, late.mechanism)
        XCTAssertLessThan(early.signal, late.signal)
        XCTAssertEqual(end.exitOpacity, 0, accuracy: 0.001)
    }

    func testDepartureRunsDirectedEntranceBackward() {
        let early = AnimationTimeline(event: .disconnected, elapsed: 0.1)
        let late = AnimationTimeline(event: .disconnected, elapsed: 1.9)
        XCTAssertGreaterThan(early.directedEntrance, late.directedEntrance)
    }

    func testConfigurationRoundTripsActions() throws {
        var configuration = DeviceArrivalConfiguration()
        configuration.devices[0].onConnect = [.init(kind: .runShortcut, value: "AirPods Ready")]
        let data = try JSONEncoder().encode(configuration)
        XCTAssertEqual(try JSONDecoder().decode(DeviceArrivalConfiguration.self, from: data), configuration)
    }

    func testEveryDeviceGetsDistinctNonSilentChimes() {
        let airPods = DeviceChimeSynthesizer.samples(kind: .airPods, event: .connected)
        let headphones = DeviceChimeSynthesizer.samples(kind: .headphones, event: .connected)
        let keyboard = DeviceChimeSynthesizer.samples(kind: .keyboard, event: .connected)
        XCTAssertTrue([airPods, headphones, keyboard].allSatisfy { samples in samples.contains(where: { abs($0) > 0 }) })
        XCTAssertNotEqual(Array(airPods.prefix(1_024)), Array(headphones.prefix(1_024)))
        XCTAssertNotEqual(airPods.count, keyboard.count)
    }
}
