package cloud.holline.sdk.reactnative

import cloud.holline.sdk.Holline
import com.facebook.react.bridge.Promise
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.bridge.ReactContextBaseJavaModule
import com.facebook.react.bridge.ReactMethod
import com.facebook.react.modules.core.DeviceEventManagerModule

class HollineModule(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    override fun getName() = "HollineModule"

    @ReactMethod
    fun open(company: String, name: String?, phone: String?, source: String?, baseUrl: String?, promise: Promise) {
        try {
            if (baseUrl != null) Holline.baseUrl = baseUrl
            Holline.open(reactApplicationContext, company, name, phone, source ?: "mobile_app")
            promise.resolve(null)
        } catch (e: IllegalArgumentException) {
            promise.reject("invalid_company", e.message, e)
        }
    }

    @ReactMethod
    fun isInCall(promise: Promise) {
        promise.resolve(Holline.isInCall)
    }

    /** Called by NativeEventEmitter when JS subscribes. */
    @ReactMethod
    fun addListener(@Suppress("UNUSED_PARAMETER") eventName: String) {
        Holline.onPhaseChanged = { phase ->
            reactApplicationContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter::class.java)
                .emit("hollinePhase", phase)
        }
    }

    /** Required by NativeEventEmitter. The listener stays set: events without subscribers are dropped in JS. */
    @ReactMethod
    fun removeListeners(@Suppress("UNUSED_PARAMETER") count: Int) = Unit

    override fun invalidate() {
        Holline.onPhaseChanged = null
        super.invalidate()
    }
}
