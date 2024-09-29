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
        implementation.initialize(call, config: getConfig())
    }

    @objc func signIn(_ call: CAPPluginCall) {
        guard let vc = self.bridge?.viewController else {
            fatalError("Sign in called and Capacitor has no viewController")
        }

        implementation.signIn(call, vc)
    }

    @objc func signOut(_ call: CAPPluginCall) {
        implementation.signOut(call)
    }
}
