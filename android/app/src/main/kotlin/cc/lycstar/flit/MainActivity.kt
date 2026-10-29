package cc.lycstar.flit

import android.graphics.Color
import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

/**
 * 只管窗口。原生业务按 feature 拆在 plugins/(flit_env / lsp / device / work / files),
 * 由 GeneratedPluginRegistrant 自动注册, 这里不堆方法通道。
 */
class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // 沉浸式: targetSdk 28 不会被系统强制全屏, 必须自己把窗口延伸到
        // 状态栏/导航栏之下; 栏的透明色由 Dart 侧 SystemUiOverlayStyle 控制
        WindowCompat.setDecorFitsSystemWindows(window, false)
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        super.onCreate(savedInstanceState)
    }
}
