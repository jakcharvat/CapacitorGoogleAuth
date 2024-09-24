package dev.jakcharvat.capacitorgoogleauth

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@CapacitorPlugin(name = "GoogleAuth")
class GoogleAuthPlugin : Plugin() {
    private lateinit var implementation: GoogleAuth

    override fun load(){
        val clientId = config.getString("clientId")
        implementation = GoogleAuth(this.bridge.activity, GoogleAuth.Config(clientId))
    }

    @PluginMethod
    fun initialize(call: PluginCall) {
        call.resolve()
    }

    @PluginMethod
    fun signIn(call: PluginCall) {
        runBlocking {
            when (val user = implementation.signIn()) {
                is GoogleAuth.User -> call.resolve(JSObject(Json.encodeToString(user)))
                else -> call.reject("Sign-in failed")
            }
        }
    }

    @PluginMethod
    fun signOut(call: PluginCall) {
        runBlocking {
            implementation.signOut()
            call.resolve()
        }
    }
}
