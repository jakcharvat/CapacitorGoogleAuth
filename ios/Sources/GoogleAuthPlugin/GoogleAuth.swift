import Capacitor
import Foundation
import GoogleSignIn

enum GoogleAuthError : Error {
    case noClientId
    case uninitializedGoogleAuth(inFunction: String = #function)
    case signInFailed
    case invalidUserData

    case passthrough(Error)

    var localizedDescription: String {
        switch self {
        case .noClientId:
            return "No client ID found in config"
        case .uninitializedGoogleAuth(let inFunction):
            return "Google auth not initialized when calling \(inFunction)"
        case .signInFailed:
            return "Google signin failed"
        case .invalidUserData:
            return "Google signin returned invalid user data"
        case .passthrough(let error):
            return "Google signin error: \(error.localizedDescription)"
        }
    }
}

struct GoogleAuth {
    var signIn: GIDSignIn?
    var additionalScopes: [String] = []

    mutating func initialize(config: PluginConfig) -> Result<Void, GoogleAuthError> {
        let signIn = GIDSignIn.sharedInstance

        guard let clientId = getClientId(from: config) else {
            return .failure(.noClientId)
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

        return .success(())
    }

    private func getClientId(from config: PluginConfig) -> String? {
        if let clientId = config.getString("iosClientId") { return clientId }

        if let url = Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist"),
            let dict = try? NSDictionary(contentsOf: url, error: ()),
            let clientId = dict["CLIENT_ID"] as? String { return clientId }

        return nil
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
    private func getSignedInUser(from signIn: GIDSignIn, in viewController: UIViewController) async throws
        -> GIDGoogleUser?
    {
        if let user = signIn.currentUser { return user }
        if signIn.hasPreviousSignIn() { return try await signIn.restorePreviousSignIn() }

        return try await signIn.signIn(
            withPresenting: viewController, hint: nil, additionalScopes: additionalScopes
        ).user
    }

    func signIn(in viewController: UIViewController) async -> Result<[String : Any], GoogleAuthError> {
        do {
            guard let signIn else {
                return .failure(.uninitializedGoogleAuth())
            }

            guard let googleUser = try await getSignedInUser(from: signIn, in: viewController),
                  let user = User(from: googleUser) else {
                return .failure(.signInFailed)
            }

            guard let data = try? JSONEncoder().encode(user),
                  let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return .failure(.invalidUserData)
            }

            return .success(dict)
        } catch {
            return .failure(.passthrough(error))
        }
    }

    @MainActor
    func signOut() async -> Result<(), GoogleAuthError> {
        guard let signIn else {
            return .failure(.uninitializedGoogleAuth())
        }

        signIn.signOut()
        return .success(())
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

    init(
        id: String,
        email: String,
        name: String,
        familyName: String,
        givenName: String,
        imageUrl: String,
        serverAuthCode: String,
        authentication: Authentication
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.familyName = familyName
        self.givenName = givenName
        self.imageUrl = imageUrl
        self.serverAuthCode = serverAuthCode
        self.authentication = authentication
    }

    init?(from googleUser: GIDGoogleUser) {
        guard let profile = googleUser.profile,
              let idToken = googleUser.idToken else { return nil }

        self.init(
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
    }
}
