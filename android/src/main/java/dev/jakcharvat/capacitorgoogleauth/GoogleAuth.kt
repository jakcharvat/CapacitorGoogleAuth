package dev.jakcharvat.capacitorgoogleauth

import android.content.Context
import androidx.credentials.ClearCredentialStateRequest
import androidx.credentials.GetCredentialRequest
import androidx.credentials.CredentialManager
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential.Companion.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL
import kotlinx.coroutines.coroutineScope
import kotlinx.serialization.Serializable

class GoogleAuth(
    private val context: Context,
    private val config: Config
) {
    private val credentialManager = CredentialManager.create(context)

    suspend fun signIn(): User? {
        val googleIdOption = GetGoogleIdOption.Builder()
            .setFilterByAuthorizedAccounts(true)
            .setServerClientId(config.webClientId)
            .setAutoSelectEnabled(true)
            .build()

        val request = GetCredentialRequest.Builder()
            .addCredentialOption(googleIdOption)
            .build()

        val credential = coroutineScope {
            val credentialResponse = credentialManager.getCredential(context, request)
            credentialResponse.credential
        }

        return when (credential.type) {
            TYPE_GOOGLE_ID_TOKEN_CREDENTIAL -> User.createFrom(GoogleIdTokenCredential.createFrom(credential.data))
            else -> null
        }
    }

    suspend fun signOut() {
        credentialManager.clearCredentialState(ClearCredentialStateRequest())
    }

    @Serializable
    data class User(
        val id: String,
        val email: String,
        val name: String,
        val familyName: String,
        val givenName: String,
        val imageUrl: String,
        val serverAuthCode: String,
        val authentication: Authentication
    ) {
        companion object {
            fun createFrom(idTokenCredential: GoogleIdTokenCredential): User {
                return User(
                    idTokenCredential.id,
                    "???",
                    idTokenCredential.displayName ?: "",
                    idTokenCredential.familyName ?: "",
                    idTokenCredential.givenName ?: "",
                    idTokenCredential.profilePictureUri.toString(),
                    "???",
                    Authentication(
                        "???",
                        idTokenCredential.idToken,
                        "???"
                    )
                )
            }
        }
    }

    @Serializable
    data class Authentication(
        val accessToken: String,
        val idToken: String,
        val refreshToken: String?
    )

    data class Config(
        val webClientId: String
    )
}
