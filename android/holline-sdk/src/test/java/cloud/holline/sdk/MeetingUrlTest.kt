package cloud.holline.sdk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Test

class MeetingUrlTest {
    private val base = "https://holline.cloud"

    @Test
    fun aMeetingLinkOpensWithTheSdkFlag() {
        assertEquals(
            "https://holline.cloud/m/abcd-efgh-ijkm?sdk=1",
            Holline.meetingUrl(base, "https://holline.cloud/m/abcd-efgh-ijkm", null),
        )
    }

    @Test
    fun aCompanyAppLinkKeepsItsPath() {
        assertEquals(
            "https://holline.cloud/a/ayed-academy/m/abcd-efgh-ijkm?sdk=1#name=Mona+Ali",
            Holline.meetingUrl(base, "https://holline.cloud/a/ayed-academy/m/abcd-efgh-ijkm/", "Mona Ali"),
        )
    }

    @Test
    fun aBareCodeWorks() {
        assertEquals("https://holline.cloud/m/abcd-efgh-ijkm?sdk=1", Holline.meetingUrl(base, " ABCD-EFGH-IJKM ", null))
    }

    @Test
    fun theNameStaysOutOfTheQueryString() {
        val url = Holline.meetingUrl(base, "https://holline.cloud/m/abcd-efgh-ijkm", "Sara")
        assertFalse(url.substringBefore('#').contains("Sara"))
    }

    @Test
    fun otherLinksAreRefused() {
        assertNull(Holline.meetingPath(base, "https://evil.example/m/abcd-efgh-ijkm"))
        assertNull(Holline.meetingPath(base, "http://holline.cloud/m/abcd-efgh-ijkm"))
        assertNull(Holline.meetingPath(base, "https://holline.cloud/c/acme"))
        assertNull(Holline.meetingPath(base, "https://holline.cloud/m/abcd"))
        assertNull(Holline.meetingPath(base, "not a link"))
        assertThrows(IllegalArgumentException::class.java) { Holline.meetingUrl(base, "https://holline.cloud/c/acme", null) }
    }
}
