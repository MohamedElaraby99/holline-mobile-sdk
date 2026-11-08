package cloud.holline.sdk

import android.content.Context
import android.content.Intent
import java.net.URI
import java.net.URLEncoder

/**
 * Opens a company's Holline call screen, or one of its meetings, inside the host app.
 *
 * ```
 * Holline.open(context, company = "your-slug", name = user.name, phone = user.phone)
 * Holline.joinMeeting(context, link, name = user.name)
 * ```
 */
object Holline {
    /** Where the call screen is served from. */
    @JvmStatic
    var baseUrl: String = "https://holline.cloud"

    /**
     * Called on the main thread when the call moves on. Phases: flow, form, ringing,
     * connected, ended, missed, callback, moved, mic-error. A meeting reports
     * meeting-ready, meeting-lobby, meeting-joined, meeting-left, meeting-ended,
     * meeting-removed, meeting-denied, meeting-full and meeting-missing.
     */
    @JvmStatic
    var onPhaseChanged: ((String) -> Unit)? = null

    /** The current phase, or null while the call screen isn't open. */
    @JvmStatic
    var phase: String? = null
        private set

    /** True while a call is ringing or connected, or a meeting is joined, even if the screen is hidden. */
    @JvmStatic
    val isInCall: Boolean
        get() = phase == "ringing" || phase == "connected" || phase == "meeting-joined"

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
        show(context, callUrl(baseUrl, company, name, phone, source))
    }

    /**
     * Opens a Holline meeting from its link (https://holline.cloud/m/abcd-efgh-ijkl,
     * or /a/<company>/m/… when your app opens your company's links) or its bare code.
     * Like a call, a meeting in progress is never replaced.
     *
     * @param link the meeting link, as received (an App Link, a notification, a message)
     * @param name fills in the person's name, so they only tap to join
     * @throws IllegalArgumentException when [link] isn't a Holline meeting link
     */
    @JvmStatic
    @JvmOverloads
    fun joinMeeting(context: Context, link: String, name: String? = null) {
        show(context, meetingUrl(baseUrl, link, name))
    }

    /** Whether [link] is a Holline meeting link this SDK can open, for routing incoming links. */
    @JvmStatic
    fun isMeetingLink(link: String): Boolean = meetingPath(baseUrl, link) != null

    private fun show(context: Context, url: String) {
        context.startActivity(
            Intent(context, HollineActivity::class.java)
                .putExtra(HollineActivity.EXTRA_URL, url)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
        )
    }

    private val meetingPathRe = Regex("^/(a/[a-z0-9-]+/)?m/[a-z]{4}-[a-z]{4}-[a-z]{4}$")
    private val meetingCodeRe = Regex("^[a-z]{4}-[a-z]{4}-[a-z]{4}$")

    /** The meeting's path on [base], from a link to it or its bare code; null if it isn't one. */
    internal fun meetingPath(base: String, link: String): String? {
        val text = link.trim()
        if (meetingCodeRe.matches(text.lowercase())) return "/m/" + text.lowercase()
        val uri = try { URI(text) } catch (_: Exception) { return null }
        val site = try { URI(base.trimEnd('/')) } catch (_: Exception) { return null }
        if (!uri.scheme.equals(site.scheme, true) || !uri.host.equals(site.host, true) || uri.port != site.port) return null
        val path = uri.path?.trimEnd('/')?.lowercase() ?: return null
        return path.takeIf { meetingPathRe.matches(it) }
    }

    /** The person's name goes in the fragment, which is never sent to the server. */
    internal fun meetingUrl(base: String, link: String, name: String?): String {
        val path = requireNotNull(meetingPath(base, link)) { "not a Holline meeting link: $link" }
        return buildString {
            append(base.trimEnd('/')).append(path).append("?sdk=1")
            name?.takeIf { it.isNotBlank() }?.let { append("#name=").append(encode(it.trim())) }
        }
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
