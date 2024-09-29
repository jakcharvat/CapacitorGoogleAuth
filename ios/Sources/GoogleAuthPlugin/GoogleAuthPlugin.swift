import Capacitor
import Foundation

@objc(GoogleAuthPlugin)
public class GoogleAuthPlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "GoogleAuthPlugin"
    public let jsName = "GoogleAuth"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "initialize", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "signIn", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "signOut", returnType: CAPPluginReturnPromise)
    ]

    private var implementation = GoogleAuth()

    @objc func initialize(_ call: CAPPluginCall) {
        switch implementation.initialize(config: getConfig()) {
        case .success(): call.resolve()
        case .failure(let error): call.reject(error.localizedDescription)
        }
    }

    @objc func signIn(_ call: CAPPluginCall) {
        guard let vc = self.bridge?.viewController else {
            fatalError("Sign in called and Capacitor has no viewController")
        }

        Task.detached { [self] in
            switch await implementation.signIn(in: vc) {
            case .success(let data): call.resolve(data)
            case .failure(let error): call.reject(error.localizedDescription)
            }
        }
    }

    @objc func signOut(_ call: CAPPluginCall) {
        Task.detached { [self] in
            switch await implementation.signOut() {
            case .success(): call.resolve()
            case .failure(let error): call.reject(error.localizedDescription)
            }
        }
    }
}
