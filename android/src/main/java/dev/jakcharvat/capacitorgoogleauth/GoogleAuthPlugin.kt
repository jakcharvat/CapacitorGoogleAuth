package dev.jakcharvat.capacitorgoogleauth

import com.getcapacitor.JSObject
import com.getcapacitor.Plugin
import com.getcapacitor.PluginCall
import com.getcapacitor.PluginMethod
import com.getcapacitor.annotation.CapacitorPlugin

@CapacitorPlugin(name = "GoogleAuth")
class GoogleAuthPlugin : Plugin() {
    private val implementation = GoogleAuth()

    @PluginMethod
    fun echo(call: PluginCall) {
        val value: String? = call.getString("value")

        val ret = JSObject()
        ret.put("value", value?.let { implementation.echo(it) })
        call.resolve(ret)
    }
}
