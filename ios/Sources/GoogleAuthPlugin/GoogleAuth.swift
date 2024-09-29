import Capacitor
import Foundation
import GoogleSignIn

struct GoogleAuth {
    var signIn: GIDSignIn?
    var additionalScopes: [String] = []

    mutating func initialize(_ call: CAPPluginCall, config: PluginConfig) {
        let signIn = GIDSignIn.sharedInstance

        guard let clientId = getClientId(from: config) else {
            call.reject("Couldn't load client ID from config")
            return
        }

        additionalScopes = config.getArray("scopes") as? [String] ?? []
        signIn.configuration = GIDConfiguration(clientID: clientId)
        self.signIn = signIn

        NotificationCenter.default.addObserver(
            forName: Notification.Name.capacitorOpenURL,
            object: nil,
            queue: nil,
            using: handleOpenUrl(with:)
        )
    }

    private func getClientId(from config: PluginConfig) -> String? {
        if let clientId = config.getString("iosClientId")
            ?? config.getString("clientId")
        {
            return clientId
        }

        if let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
            let dict = try? NSDictionary(contentsOf: url, error: ()),
            let clientId = dict["CLIENT_ID"] as? String
        {
            return clientId
        }

        return Bundle.main.object(forInfoDictionaryKey: "CLIENT_ID") as? String
    }

    private func noSignIn(in call: CAPPluginCall) {
    }

    private func handleOpenUrl(with notification: Notification) {
        guard let dataObject = notification.object as? [String: Any],
            let url = dataObject["url"] as? URL
        else {
            print("Missing url in openUrl notification")
            return
        }

        guard let signIn else {
            fatalError("SignIn is not initialized in notification observer handler")
        }

        signIn.handle(url)
    }

    @MainActor
    private func getSignedInUser(from signIn: GIDSignIn, using viewController: UIViewController) async throws
        -> GIDGoogleUser?
    {
        if let user = signIn.currentUser { return user }
        if signIn.hasPreviousSignIn() { return try await signIn.restorePreviousSignIn() }

        return try await signIn.signIn(
            withPresenting: viewController, hint: nil, additionalScopes: additionalScopes
        ).user
    }

    func signIn(_ call: CAPPluginCall, _ viewController: UIViewController) {
        Task.detached {
            do {
                guard let signIn else {
                    return call.reject("GoogleAuth must be initialized before signIn")
                }

                guard let googleUser = try await getSignedInUser(from: signIn, using: viewController),
                      let profile = googleUser.profile,
                      let idToken = googleUser.idToken else {
                    return call.reject("Google sign in failed")
                }

                let user = User(
                    id: googleUser.userID ?? "",
                    email: profile.email,
                    name: profile.name,
                    familyName: profile.familyName ?? "",
                    givenName: profile.givenName ?? "",
                    imageUrl: profile.imageURL(withDimension: 100)?.absoluteString ?? "",
                    serverAuthCode: "???",
                    authentication: Authentication(
                        accessToken: googleUser.accessToken.tokenString,
                        idToken: idToken.tokenString,
                        refreshToken: googleUser.refreshToken.tokenString
                    )
                )

                guard let data = try? JSONEncoder().encode(user),
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    return call.reject("Invalid user data")
                }

                call.resolve(dict)
            } catch {
                call.reject("\(error.localizedDescription) - \(error)")
            }
        }
    }

    func signOut(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let signIn else {
                return call.reject("GoogleAuth must be initialized before signOut")
            }

            signIn.signOut()
            call.resolve()
        }
    }
}

private struct Authentication: Encodable {
    let accessToken: String
    let idToken: String
    let refreshToken: String?
}

private struct User: Encodable {
    let id: String
    let email: String
    let name: String
    let familyName: String
    let givenName: String
    let imageUrl: String
    let serverAuthCode: String
    let authentication: Authentication
}
