package dev.jakcharvat.capacitorgoogleauth

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@CapacitorPlugin(name = "GoogleAuth")
class GoogleAuthPlugin : Plugin() {
    private lateinit var implementation: GoogleAuth

    override fun load(){
        implementation = GoogleAuth(this.activity.applicationContext)
    }

    @PluginMethod
    suspend fun initialize(call: PluginCall) {
        call.resolve()
    }

    @PluginMethod
    suspend fun signIn(call: PluginCall) {
        when (val user = implementation.signIn()) {
            is GoogleAuth.User -> call.resolve(JSObject(Json.encodeToString(user)))
            else -> call.reject("Sign-in failed")
        }
    }

    @PluginMethod
    suspend fun signOut(call: PluginCall) {
        implementation.signOut()
        call.resolve()
    }
}
