package cloud.holline.sdk

import android.Manifest
import android.annotation.SuppressLint
import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.webkit.JavascriptInterface
import android.webkit.PermissionRequest
import android.webkit.RenderProcessGoneDetail
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.FrameLayout
import android.widget.ImageButton
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.window.OnBackInvokedDispatcher
import org.json.JSONException
import org.json.JSONObject

/** The call page in a WebView locked to the Holline site. */
internal class HollineActivity : Activity() {
    private lateinit var root: FrameLayout
    private lateinit var webView: WebView
    private lateinit var spinner: ProgressBar
    private lateinit var offline: View
    private lateinit var loadedUrl: String
    private var loadFailed = false
    private var pendingPermission: PermissionRequest? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val url = intent.getStringExtra(EXTRA_URL)
        if (url == null) {
            // Opened from a call notification after the call screen was already gone.
            finish()
            return
        }
        loadedUrl = url
        buildViews()
        registerBackHandler()
        syncCallState()
        webView.loadUrl(url)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val url = intent.getStringExtra(EXTRA_URL) ?: return
        if (url == loadedUrl || Holline.isInCall) return
        // A new page, not loadUrl: a URL differing only in its fragment wouldn't reload.
        setIntent(intent)
        recreate()
    }

    override fun onResume() {
        super.onResume()
        if (::webView.isInitialized) webView.onResume()
    }

    override fun onPause() {
        super.onPause()
        // Pausing the WebView would pause a live call.
        if (::webView.isInitialized && !Holline.isInCall) webView.onPause()
    }

    override fun onDestroy() {
        if (::webView.isInitialized) {
            pendingPermission?.deny()
            pendingPermission = null
            tearDownWebView()
            Holline.updatePhase(null)
            HollineCallService.stop(this)
        }
        super.onDestroy()
    }

    private fun tearDownWebView() {
        (webView.parent as? ViewGroup)?.removeView(webView)
        webView.destroy()
    }

    /** Hides the screen. During a call it keeps running behind the host app. */
    private fun leave() {
        if (Holline.isInCall) moveTaskToBack(true) else finish()
    }

    private fun registerBackHandler() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            onBackInvokedDispatcher.registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT) { leave() }
        }
    }

    @Deprecated("Still called below Android 13 and by apps without predictive back.")
    override fun onBackPressed() {
        leave()
    }

    private fun buildViews() {
        root = FrameLayout(this)
        webView = createWebView()
        spinner = ProgressBar(this)
        offline = createOfflineView()
        root.addView(webView, matchParent())
        root.addView(spinner, FrameLayout.LayoutParams(dp(40), dp(40), Gravity.CENTER))
        root.addView(offline, matchParent())
        root.addView(createCloseButton(), closeButtonParams())
        applyInsets()
        setContentView(root)
    }

    private fun matchParent() = FrameLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT,
    )

    // The corner the website widget uses, whichever way the language runs.
    @SuppressLint("RtlHardcoded")
    private fun closeButtonParams() = FrameLayout.LayoutParams(dp(36), dp(36), Gravity.TOP or Gravity.LEFT).apply {
        setMargins(dp(12), dp(12), dp(12), dp(12))
    }

    private fun createCloseButton() = ImageButton(this).apply {
        setImageResource(R.drawable.holline_ic_close)
        contentDescription = getString(R.string.holline_close)
        background = GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(Color.argb(115, 15, 23, 42))
        }
        setOnClickListener { leave() }
    }

    private fun createOfflineView() = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        setBackgroundColor(Color.WHITE)
        visibility = View.GONE
        // The WebView must not take touches from under it.
        isClickable = true
        addView(
            TextView(context).apply {
                text = getString(R.string.holline_offline_title)
                textSize = 17f
                setTextColor(Color.rgb(15, 23, 42))
                gravity = Gravity.CENTER
            },
        )
        addView(
            Button(context).apply {
                text = getString(R.string.holline_offline_retry)
                setOnClickListener {
                    loadFailed = false
                    offline.visibility = View.GONE
                    spinner.visibility = View.VISIBLE
                    webView.reload()
                }
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply { topMargin = dp(16) },
        )
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun createWebView() = WebView(this).apply {
        settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            // The ringback tone and the agent's voice start without a tap on them.
            mediaPlaybackRequiresUserGesture = false
            allowFileAccess = false
            allowContentAccess = false
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
        }
        // Only ever reachable from the Holline site: leaving it opens outside the WebView.
        addJavascriptInterface(Bridge(), "HollineNative")
        webViewClient = Client()
        webChromeClient = Chrome()
    }

    private fun applyInsets() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return
        window.setDecorFitsSystemWindows(false)
        root.setOnApplyWindowInsetsListener { view, insets ->
            val bars = insets.getInsets(WindowInsets.Type.systemBars() or WindowInsets.Type.ime())
            view.setPadding(bars.left, bars.top, bars.right, bars.bottom)
            WindowInsets.CONSUMED
        }
    }

    private fun onPhase(phase: String) {
        Holline.updatePhase(phase)
        syncCallState()
    }

    /** Matches the service, the screen lock and the system bars to whether a call is live. */
    private fun syncCallState() {
        val inCall = Holline.isInCall
        if (inCall && hasPermission(Manifest.permission.RECORD_AUDIO)) {
            HollineCallService.start(this)
        } else if (!inCall) {
            HollineCallService.stop(this)
        }
        if (inCall) {
            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        } else {
            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
        root.setBackgroundColor(if (inCall) CALL_BACKGROUND else Color.WHITE)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val light = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.insetsController?.setSystemBarsAppearance(if (inCall) 0 else light, light)
        } else {
            @Suppress("DEPRECATION")
            window.statusBarColor = CALL_BACKGROUND
        }
    }

    private fun hasPermission(permission: String) = checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun isSiteUrl(uri: Uri): Boolean {
        val site = Uri.parse(Holline.baseUrl)
        return uri.scheme == site.scheme && uri.host == site.host && uri.port == site.port
    }

    private fun openExternally(uri: Uri) {
        if (uri.scheme?.lowercase() !in EXTERNAL_SCHEMES) return
        try {
            startActivity(Intent(Intent.ACTION_VIEW, uri))
        } catch (_: ActivityNotFoundException) {
            // Nothing on this device handles the link.
        }
    }

    private fun handlePermissionRequest(request: PermissionRequest) {
        if (!isSiteUrl(request.origin)) {
            request.deny()
            return
        }
        val resources = request.resources.filter { it in RESOURCE_PERMISSIONS }
        val missing = resources.map { RESOURCE_PERMISSIONS.getValue(it) }.filterNot(::hasPermission)
        if (missing.isEmpty()) {
            if (resources.isEmpty()) request.deny() else request.grant(resources.toTypedArray())
            syncCallState()
            return
        }
        pendingPermission?.deny()
        pendingPermission = request
        // Asked alongside the mic, as it's what lets the customer get back to a hidden call.
        val notifications = if (
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            !hasPermission(Manifest.permission.POST_NOTIFICATIONS)
        ) {
            listOf(Manifest.permission.POST_NOTIFICATIONS)
        } else {
            emptyList()
        }
        requestPermissions((missing + notifications).toTypedArray(), PERMISSION_REQUEST)
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != PERMISSION_REQUEST) return
        val request = pendingPermission ?: return
        pendingPermission = null
        val granted = request.resources.filter { resource ->
            RESOURCE_PERMISSIONS[resource]?.let(::hasPermission) == true
        }
        if (granted.isEmpty()) request.deny() else request.grant(granted.toTypedArray())
        syncCallState()
    }

    private fun showLoadFailure() {
        loadFailed = true
        spinner.visibility = View.GONE
        offline.visibility = View.VISIBLE
    }

    private inner class Bridge {
        /** Called from the page on a WebView thread. */
        @JavascriptInterface
        fun postMessage(message: String) {
            // "Back to the app" on a meeting's last screen.
            if (isClose(message)) {
                runOnUiThread { if (!isDestroyed) finish() }
                return
            }
            val phase = parsePhase(message) ?: return
            runOnUiThread {
                if (!isDestroyed) onPhase(phase)
            }
        }
    }

    private fun isClose(message: String): Boolean = try {
        val json = JSONObject(message)
        json.optString("source") == "holline" && json.optString("type") == "close"
    } catch (_: JSONException) {
        false
    }

    private fun parsePhase(message: String): String? = try {
        val json = JSONObject(message)
        if (json.optString("source") == "holline" && json.optString("type") == "phase") {
            json.optString("phase").ifEmpty { null }
        } else {
            null
        }
    } catch (_: JSONException) {
        null
    }

    private inner class Client : WebViewClient() {
        override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
            if (!request.isForMainFrame || isSiteUrl(request.url)) return false
            openExternally(request.url)
            return true
        }

        override fun onPageFinished(view: WebView, url: String) {
            spinner.visibility = View.GONE
            if (!loadFailed) offline.visibility = View.GONE
        }

        override fun onReceivedError(view: WebView, request: WebResourceRequest, error: WebResourceError) {
            if (request.isForMainFrame) showLoadFailure()
        }

        override fun onReceivedHttpError(view: WebView, request: WebResourceRequest, response: WebResourceResponse) {
            if (request.isForMainFrame && response.statusCode >= 500) showLoadFailure()
        }

        /** Without this, a crashed WebView takes the host app down with it. */
        override fun onRenderProcessGone(view: WebView, detail: RenderProcessGoneDetail): Boolean {
            finish()
            return true
        }
    }

    private inner class Chrome : WebChromeClient() {
        override fun onPermissionRequest(request: PermissionRequest) {
            handlePermissionRequest(request)
        }

        override fun onPermissionRequestCanceled(request: PermissionRequest) {
            if (pendingPermission == request) pendingPermission = null
        }
    }

    private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()

    companion object {
        const val EXTRA_URL = "holline_url"
        private const val PERMISSION_REQUEST = 7302
        private val CALL_BACKGROUND = Color.rgb(0, 18, 63)
        private val EXTERNAL_SCHEMES = setOf("http", "https", "tel", "mailto", "sms", "whatsapp", "geo")
        private val RESOURCE_PERMISSIONS = mapOf(
            PermissionRequest.RESOURCE_AUDIO_CAPTURE to Manifest.permission.RECORD_AUDIO,
            PermissionRequest.RESOURCE_VIDEO_CAPTURE to Manifest.permission.CAMERA,
        )
    }
}
