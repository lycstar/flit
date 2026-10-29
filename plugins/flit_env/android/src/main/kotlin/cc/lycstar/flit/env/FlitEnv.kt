package cc.lycstar.flit.env

import android.content.Context
import android.system.Os
import java.io.BufferedReader
import java.io.File
import java.io.InputStreamReader

/**
 * flit 的 Termux 环境管理: bootstrap 导出/权限 + 命令执行环境。
 * 布局与 ACS/AndroidIDE 一致: files/usr = $PREFIX, files/home = $HOME。
 * bootstrap 解压编排已上移 Dart(BootstrapInstaller); 原生只留薄方法。
 */
object FlitEnv {
    lateinit var root: File; private set
    lateinit var prefix: File; private set
    lateinit var home: File; private set

    val isBootstrapped: Boolean get() = File(prefix, "bin/bash").exists()

    /** 幂等: 用到环境的插件各自调一次, 不依赖注册顺序 */
    fun init(ctx: Context) {
        if (this::root.isInitialized) return
        root = ctx.filesDir
        prefix = File(root, "usr")
        home = File(root, "home").apply { mkdirs() }
    }

    /**
     * 全量解压 bootstrap zip 到 $PREFIX(一次解完, bash+全库+软链+权限)。
     * 逻辑与 TermuxInstaller 一致: staging -> SYMLINKS.txt(Os.symlink) -> chmod -> rename。
     * 这条路径在真机五阶段验证过; 不搞"部分解压+自解压"(会踩动态库鸡生蛋)。
     * 返回 null 表示成功, 否则为错误消息。
     */
    fun bootstrapInstallFrom(zipPath: String): String? {
        val staging = File(root, "usr-staging")
        staging.deleteRecursively()
        prefix.deleteRecursively()
        staging.mkdirs()

        return try {
            val buffer = ByteArray(1 shl 16)
            val symlinks = mutableListOf<Pair<String, String>>()
            var sawSymlinks = false

            // 流式读文件, 不做 readBytes(90MB 堆数组在低内存设备上是隐患)
            java.util.zip.ZipInputStream(File(zipPath).inputStream().buffered(1 shl 16)).use { zip ->
                while (true) {
                    val entry = zip.nextEntry ?: break
                    if (entry.name == "SYMLINKS.txt") {
                        sawSymlinks = true
                        // ⚠️ 不可用 forEachLine/useLines: 它们读完会 close 整个
                        // reader 链(连带 ZipInputStream), 后续 nextEntry 抛 Stream closed
                        val reader = BufferedReader(InputStreamReader(zip))
                        while (true) {
                            val line = reader.readLine() ?: break
                            // 官方 parser 语义: 跳过空行(文件含空行分组); 两侧 trim
                            if (line.isBlank()) continue
                            val parts = line.split("←")
                            if (parts.size != 2) continue
                            symlinks += parts[0].trim() to
                                File(staging, parts[1].trim()).absolutePath
                            File(staging, parts[1].trim()).parentFile?.mkdirs()
                        }
                    } else {
                        val target = File(staging, entry.name)
                        if (entry.isDirectory) {
                            target.mkdirs()
                        } else {
                            target.parentFile?.mkdirs()
                            target.outputStream().use { out ->
                                var n: Int
                                while (zip.read(buffer).also { n = it } != -1) out.write(buffer, 0, n)
                            }
                            if (entry.name.startsWith("bin/") || entry.name.startsWith("libexec") ||
                                entry.name.startsWith("lib/apt/apt-helper") ||
                                entry.name.startsWith("lib/apt/methods")
                            ) {
                                Os.chmod(target.absolutePath, 448) // 0700
                            }
                        }
                    }
                    zip.closeEntry()
                }
            }
            require(sawSymlinks) { "No SYMLINKS.txt encountered" }
            for ((oldPath, newPath) in symlinks) Os.symlink(oldPath, newPath)

            // 元数据等目录权限
            prefix.setExecutable(true, false)
            prefix.setReadable(true, false)
            if (!staging.renameTo(prefix)) throw RuntimeException("rename staging to prefix failed")
            null
        } catch (e: Exception) {
            "基础环境安装失败：${e.message}"
        }
    }

    /** 构造 Termux 运行环境变量(参照 ACS Environment.putEnvironment) */
    fun environment(): MutableMap<String, String> {
        val env = mutableMapOf<String, String>()
        env["HOME"] = home.absolutePath
        env["PREFIX"] = prefix.absolutePath
        env["PATH"] = "${prefix.absolutePath}/bin:${prefix.absolutePath}/bin/applets:${home.absolutePath}/android-sdk/platform-tools:/system/bin:/system/xbin"
        env["ANDROID_ROOT"] = "/system"
        env["ANDROID_DATA"] = "/data"
        env["EXTERNAL_STORAGE"] = "/sdcard"
        env["TMPDIR"] = File(prefix, "tmp").apply { mkdirs() }.absolutePath
        env["LD_LIBRARY_PATH"] = "${prefix.absolutePath}/lib"
        // termux-exec: exec 时把 #!/usr/bin/env、/bin/sh 类解释器重写到本前缀(官方 Termux 同款)。
        // 新版 termux-exec 包名为 libtermux-exec-ld-preload.so, 旧 bootstrap 兼容 libtermux-exec.so。
        // 没有它, flutter/gradle 内部脚本会报 "/usr/bin/env: bad interpreter"。
        listOf("lib/libtermux-exec-ld-preload.so", "lib/libtermux-exec.so")
            .map { File(prefix, it) }
            .firstOrNull { it.exists() }
            ?.let { env["LD_PRELOAD"] = it.absolutePath }
        env["LANG"] = "en_US.UTF-8"
        env["TZ"] = java.util.TimeZone.getDefault().id
        env["COLORTERM"] = "truecolor"

        // 工具链(JDK/Android SDK)就绪后注入构建环境, JAVA_HOME 提到 PATH 前。
        // 与 assets/scripts 的 env.sh 布局一致, 差异只在"此刻是否已装"。
        val flutterBin = File(prefix, "opt/flutter/current/bin")
        if (File(flutterBin, "flutter").exists()) {
            env["FLUTTER_ROOT"] = File(prefix, "opt/flutter/current").absolutePath
            env["PATH"] = "${flutterBin.absolutePath}:${env["PATH"]}"
        }
        val jdk = File(prefix, "lib/jvm/java-17-openjdk")
        val sdk = File(home, "android-sdk")
        val ndk = File(sdk, "ndk/28.2.13676358")
        if (File(jdk, "bin/java").exists()) {
            env["JAVA_HOME"] = jdk.absolutePath
            env["PATH"] = "${jdk.absolutePath}/bin:${env["PATH"]}"
            // libjvm.so(lib/server/) 依赖同包 lib/ 下的 libandroid-shmem.so,
            // dlopen 按 LD_LIBRARY_PATH 搜索, 必须把 JDK 的 lib 也带上
            env["LD_LIBRARY_PATH"] =
                "${jdk.absolutePath}/lib:${env["LD_LIBRARY_PATH"]}"
            // termux 版 JDK 把 java.io.tmpdir 烧死成 com.termux 前缀, 必须覆盖
            env["JDK_JAVA_OPTIONS"] = "-Djava.io.tmpdir=${prefix.absolutePath}/tmp"
        }
        if (File(sdk, "build-tools").exists()) env["ANDROID_HOME"] = sdk.absolutePath
        if (File(ndk, "source.properties").exists()) env["ANDROID_NDK_HOME"] = ndk.absolutePath
        env["GRADLE_USER_HOME"] = File(home, ".gradle").absolutePath
        if (File(prefix, "libexec/git-core/git").exists()) {
            env["GIT_EXEC_PATH"] = File(prefix, "libexec/git-core").absolutePath
        }
        // git tarball 编译期前缀是 com.termux(历史遗留), 不覆盖的话每次 git 调用
        // 都去读 com.termux/etc/gitconfig → Permission denied fatal。
        // GIT_CONFIG_SYSTEM / GIT_TEMPLATE_DIR 是 git 官方环境变量, 直接改指本前缀。
        env["GIT_CONFIG_SYSTEM"] = File(prefix, "etc/gitconfig").absolutePath
        env["GIT_TEMPLATE_DIR"] = File(prefix, "share/git-core/templates").absolutePath
        return env
    }

    /**
     * 在 Termux 环境里执行命令(经 bash -c)。
     * 返回 (exitCode, 全部输出)。
     */
    fun exec(command: String, timeoutMs: Long = 120_000): Pair<Int, String> {
        val pb = ProcessBuilder("${prefix.absolutePath}/bin/bash", "-c", command)
        pb.redirectErrorStream(true)
        pb.environment().clear()
        pb.environment().putAll(environment())
        pb.directory(home)
        // 解压后立即 exec 可能 ETXTBSY(写句柄内核侧延迟释放), 退避重试
        val p = run {
            var started: Process? = null
            var last: java.io.IOException? = null
            for (attempt in 1..6) {
                try {
                    started = pb.start()
                    break
                } catch (e: java.io.IOException) {
                    last = e
                    if (!e.message.orEmpty().contains("Text file busy")) throw e
                    Thread.sleep(250L * attempt)
                }
            }
            started ?: throw last!!
        }
        val out = StringBuilder()
        val t = Thread {
            p.inputStream.reader().use { reader ->
                val buffer = CharArray(8192)
                while (true) {
                    val count = reader.read(buffer)
                    if (count < 0) break
                    out.append(buffer, 0, count)
                }
            }
        }
        t.start()
        val exited = p.waitFor(timeoutMs, java.util.concurrent.TimeUnit.MILLISECONDS)
        if (!exited) p.destroyForcibly()
        t.join(2000)
        val code = if (exited) p.exitValue() else -1
        return code to out.toString()
    }
}
