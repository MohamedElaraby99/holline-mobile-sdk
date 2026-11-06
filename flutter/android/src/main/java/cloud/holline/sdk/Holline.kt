package cloud.holline.sdk

import android.content.Context
import android.content.Intent
import java.net.URLEncoder

/**
 * Opens a company's Holline call screen inside the host app.
 *
 * ```
 * Holline.open(context, company = "your-slug", name = user.name, phone = user.phone)
 * ```
 */
object Holline {
    /** Where the call screen is served from. */
    @JvmStatic
    var baseUrl: String = "https://holline.cloud"

    /**
     * Called on the main thread when the call moves on. Phases: flow, form, ringing,
     * connected, ended, missed, callback, moved, mic-error.
     */
    @JvmStatic
    var onPhaseChanged: ((String) -> Unit)? = null

    /** The current phase, or null while the call screen isn't open. */
    @JvmStatic
    var phase: String? = null
        private set

    /** True while a call is ringing or connected, even if the call screen is hidden. */
    @JvmStatic
    val isInCall: Boolean
        get() = phase == "ringing" || phase == "connected"

    /**
     * Opens the call screen, or brings back the one that's already open. A call in
     * progress is never replaced, even when the arguments differ.
     *
     * @param company the company's slug, from its Holline call link
     * @param name fills in the customer's name on the form
     * @param phone fills in the customer's phone number on the form
     * @param source shown as the call's source in analytics
     */
    @JvmStatic
    @JvmOverloads
    fun open(
        context: Context,
        company: String,
        name: String? = null,
        phone: String? = null,
        source: String = "mobile_app",
    ) {
        val url = callUrl(baseUrl, company, name, phone, source)
        context.startActivity(
            Intent(context, HollineActivity::class.java)
                .putExtra(HollineActivity.EXTRA_URL, url)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    internal fun updatePhase(next: String?) {
        if (next == phase) return
        phase = next
        if (next != null) onPhaseChanged?.invoke(next)
    }

    /** The customer's details go in the fragment, which is never sent to the server. */
    internal fun callUrl(base: String, company: String, name: String?, phone: String?, source: String): String {
        val slug = company.trim().lowercase()
        require(slug.isNotEmpty()) { "company must not be empty" }
        val fragment = listOfNotNull(
            name?.takeIf { it.isNotBlank() }?.let { "name=${encode(it)}" },
            phone?.takeIf { it.isNotBlank() }?.let { "phone=${encode(it)}" },
        ).joinToString("&")
        return buildString {
            append(base.trimEnd('/')).append("/c/").append(encode(slug))
            append("?sdk=1&src=").append(encode(source))
            if (fragment.isNotEmpty()) append('#').append(fragment)
        }
    }

    private fun encode(value: String) = URLEncoder.encode(value, "UTF-8")
}
