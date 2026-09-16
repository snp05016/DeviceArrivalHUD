import Foundation
import IOKit

public enum BatteryReader {
    private static let serviceClasses = ["AppleDeviceManagementHIDEventService", "IOHIDEventService"]
    private static let batteryKeys = Set(["BATTERYPERCENT", "BATTERYPERCENTSINGLE", "BATTERYPERCENTCOMBINED", "BATTERYLEVEL", "BATTERYPERCENTLEFT", "BATTERYPERCENTRIGHT"])
    private static let nameKeys = Set(["PRODUCT", "PRODUCTNAME", "DEVICENAME", "NAME"])

    public static func percentage(forDeviceNamed deviceName: String) -> Int? {
        for serviceClass in serviceClasses {
            guard let matching = IOServiceMatching(serviceClass) else { continue }
            var iterator: io_iterator_t = 0
            guard IOServiceGetMatchingServices(kIOMainPortDefault, matching, &iterator) == KERN_SUCCESS else { continue }
            defer { IOObjectRelease(iterator) }

            var service = IOIteratorNext(iterator)
            while service != 0 {
                defer { IOObjectRelease(service); service = IOIteratorNext(iterator) }
                var properties: Unmanaged<CFMutableDictionary>?
                guard IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
                      let dictionary = properties?.takeRetainedValue() as? [String: Any],
                      propertyNames(in: dictionary).contains(where: { namesMatch($0, deviceName) }) else { continue }
                var values: [Int] = []
                collectBatteryValues(in: dictionary, into: &values)
                if let value = values.min() { return value }
            }
        }
        return nil
    }

    private static func collectBatteryValues(in value: Any, key: String? = nil, into values: inout [Int]) {
        if let dictionary = value as? NSDictionary {
            for (nestedKey, nestedValue) in dictionary {
                collectBatteryValues(in: nestedValue, key: nestedKey as? String, into: &values)
            }
            return
        }
        guard let key, batteryKeys.contains(key.uppercased()), let number = value as? NSNumber else { return }
        let raw = number.doubleValue
        let percentage = raw >= 0 && raw <= 1 ? raw * 100 : raw
        if (0...100).contains(percentage) { values.append(Int(percentage.rounded())) }
    }

    private static func propertyNames(in value: Any, key: String? = nil) -> [String] {
        if let dictionary = value as? NSDictionary {
            return dictionary.flatMap { propertyNames(in: $0.value, key: $0.key as? String) }
        }
        guard let key, nameKeys.contains(key.uppercased()), let name = value as? String else { return [] }
        return [name]
    }

    private static func namesMatch(_ lhs: String, _ rhs: String) -> Bool {
        let left = TrackedDevice.normalized(lhs)
        let right = TrackedDevice.normalized(rhs)
        if left.contains(right) || right.contains(left) { return true }
        let ignored = Set(["THE", "AUDIO", "HEADPHONES", "HEADSET", "SAUMYA", "S"])
        return !Set(left.split(separator: " ").map(String.init)).subtracting(ignored)
            .intersection(Set(right.split(separator: " ").map(String.init)).subtracting(ignored)).isEmpty
    }
}

