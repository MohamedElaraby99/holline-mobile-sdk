package cloud.holline.sdk.flutter

import android.content.Context
import cloud.holline.sdk.Holline
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class HollineSdkPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "holline_sdk")
        channel.setMethodCallHandler(this)
        Holline.onPhaseChanged = { phase -> channel.invokeMethod("onPhase", phase) }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        Holline.onPhaseChanged = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "open" -> open(call, result)
            "isInCall" -> result.success(Holline.isInCall)
            "joinMeeting" -> joinMeeting(call, result)
            "isMeetingLink" -> {
                call.argument<String>("baseUrl")?.let { Holline.baseUrl = it }
                result.success(Holline.isMeetingLink(call.argument<String>("link").orEmpty()))
            }
            else -> result.notImplemented()
        }
    }

    private fun open(call: MethodCall, result: MethodChannel.Result) {
        try {
            call.argument<String>("baseUrl")?.let { Holline.baseUrl = it }
            Holline.open(
                context,
                call.argument<String>("company").orEmpty(),
                call.argument<String>("name"),
                call.argument<String>("phone"),
                call.argument<String>("source") ?: "mobile_app",
            )
            result.success(null)
        } catch (e: IllegalArgumentException) {
            result.error("invalid_company", e.message, null)
        }
    }

    private fun joinMeeting(call: MethodCall, result: MethodChannel.Result) {
        call.argument<String>("baseUrl")?.let { Holline.baseUrl = it }
        val link = call.argument<String>("link").orEmpty()
        if (!Holline.isMeetingLink(link)) {
            result.success(false)
            return
        }
        Holline.joinMeeting(context, link, call.argument<String>("name"))
        result.success(true)
    }
}
