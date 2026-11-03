package cc.lycstar.flit.files

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

internal fun nativeText(context: Context, id: Int, vararg args: Any?): String {
    val language = context.getSharedPreferences("flit_language", Context.MODE_PRIVATE)
        .getString("language", "system") ?: "system"
    val localized = if (language == "zh" || language == "en") {
        val configuration = Configuration(context.resources.configuration)
        configuration.setLocale(Locale(language))
        context.createConfigurationContext(configuration)
    } else context
    return localized.getString(id, *args)
}
