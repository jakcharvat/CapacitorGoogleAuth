import Foundation

@objc public class GoogleAuth: NSObject {
    @objc public func echo(_ value: String) -> String {
        print(value)
        return value
    }
}
