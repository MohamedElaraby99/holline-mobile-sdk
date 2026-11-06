package cloud.holline.sdk

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Test

class CallUrlTest {
    private val base = "https://holline.cloud"

    @Test
    fun withoutCustomerDetailsThereIsNoFragment() {
        assertEquals(
            "https://holline.cloud/c/acme?sdk=1&src=mobile_app",
            Holline.callUrl(base, "acme", null, null, "mobile_app"),
        )
    }

    @Test
    fun customerDetailsStayOutOfTheQueryString() {
        val url = Holline.callUrl(base, "acme", "Mona Ali", "+201000000000", "mobile_app")
        assertEquals("https://holline.cloud/c/acme?sdk=1&src=mobile_app#name=Mona+Ali&phone=%2B201000000000", url)
        assertFalse(url.substringBefore('#').contains("201000000000"))
    }

    @Test
    fun blankCustomerDetailsAreLeftOut() {
        assertEquals(
            "https://holline.cloud/c/acme?sdk=1&src=mobile_app#phone=010",
            Holline.callUrl(base, "acme", " ", "010", "mobile_app"),
        )
    }

    @Test
    fun slugIsNormalizedAndBaseTrimmed() {
        assertEquals(
            "https://holline.cloud/c/acme?sdk=1&src=app",
            Holline.callUrl("https://holline.cloud/", " ACME ", null, null, "app"),
        )
    }

    @Test(expected = IllegalArgumentException::class)
    fun emptyCompanyIsRejected() {
        Holline.callUrl(base, "  ", null, null, "app")
    }
}
