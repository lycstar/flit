package cc.lycstar.flit.device

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Handler
import android.os.Looper
import java.net.BindException
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.ServerSocket

/** mDNS discovers ADB service types, not arbitrary listening ports. All lifecycle
 * and callbacks are serialized on the main looper. Losing a service invalidates it.
 * Local ownership requires BOTH a local interface address and an occupied port,
 * as in Shizuku; an unrelated LAN device with the same port is not this device. */
internal class AdbDiscovery(
    context: Context,
    private val type: String,
    private val onFound: (NsdServiceInfo) -> Unit,
    private val onLost: (String) -> Unit = {},
    private val onError: (String) -> Unit,
) : NsdManager.DiscoveryListener {
    private val nsd = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    private val main = Handler(Looper.getMainLooper())
    private var active = false
    private var registered = false
    private val present = mutableSetOf<String>()

    fun start() {
        if (active) return
        active = true
        runCatching { nsd.discoverServices(type, NsdManager.PROTOCOL_DNS_SD, this) }
            .onFailure { fail("无法开始端口扫描：${it.message}") }
    }

    fun stop() {
        active = false
        present.clear()
        if (registered) {
            registered = false
            runCatching { nsd.stopServiceDiscovery(this) }
        }
    }

    private fun fail(message: String) {
        if (!active) return
        stop()
        onError(message)
    }

    override fun onDiscoveryStarted(serviceType: String) { main.post {
        registered = true
        if (!active) stop()
    } }
    override fun onDiscoveryStopped(serviceType: String) { main.post { registered = false } }
    override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) { main.post {
        // Some implementations register the listener even if startup fails.
        runCatching { nsd.stopServiceDiscovery(this) }
        fail("端口扫描失败（NSD $errorCode）")
    } }
    override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {}
    override fun onServiceLost(info: NsdServiceInfo) { main.post {
        if (active) { present.remove(info.serviceName); onLost(info.serviceName) }
    } }
    override fun onServiceFound(info: NsdServiceInfo) { main.post {
        if (!active || info.serviceType.trimEnd('.') != type.trimEnd('.')) return@post
        if (!present.add(info.serviceName)) return@post
        resolve(info, 0)
    } }

    private fun resolve(info: NsdServiceInfo, attempt: Int) {
        AdbResolver.submit(nsd, info, { active && present.contains(info.serviceName) }) { resolved, code ->
            if (!active || !present.contains(info.serviceName)) return@submit
            if (resolved == null) {
                if (attempt < 2) main.postDelayed({
                    if (active && present.contains(info.serviceName)) resolve(info, attempt + 1)
                }, 300L * (attempt + 1))
                else fail("端口解析失败（NSD $code），请重新扫描")
                return@submit
            }
            val host = resolved.host ?: return@submit
            val local = runCatching {
                NetworkInterface.getNetworkInterfaces().toList().any { net ->
                    net.inetAddresses.toList().any { it.address.contentEquals(host.address) }
                }
            }.getOrDefault(false)
            if (!local || resolved.port !in 1..65535) return@submit
            val occupied = try {
                ServerSocket().use { it.bind(InetSocketAddress("127.0.0.1", resolved.port), 1) }
                false
            } catch (_: BindException) { true } catch (_: Exception) { false }
            if (occupied) onFound(resolved)
        }
    }
}

/** Older Android NSD allows only one pending resolution. The queue is shared
 * across connection scans AND the notification pairing service. */
private object AdbResolver {
    private val main = Handler(Looper.getMainLooper())
    private data class Request(val nsd: NsdManager, val info: NsdServiceInfo,
        val valid: () -> Boolean, val done: (NsdServiceInfo?, Int) -> Unit)
    private val queue = ArrayDeque<Request>()
    private var busy = false
    fun submit(nsd: NsdManager, info: NsdServiceInfo, valid: () -> Boolean,
        done: (NsdServiceInfo?, Int) -> Unit) {
        queue.addLast(Request(nsd, info, valid, done))
        next()
    }
    private fun next() {
        if (busy) return
        var request: Request
        do { request = queue.removeFirstOrNull() ?: return } while (!request.valid())
        val current = request
        busy = true
        var finished = false
        fun finish(info: NsdServiceInfo?, code: Int) { main.post {
            if (!finished) {
                finished = true
                busy = false
                if (current.valid()) current.done(info, code)
                next()
            }
        } }
        // A platform callback may never arrive; don't block every future scan.
        main.postDelayed({ finish(null, -1) }, 5000)
        runCatching {
            current.nsd.resolveService(current.info, object : NsdManager.ResolveListener {
                override fun onServiceResolved(info: NsdServiceInfo) = finish(info, 0)
                override fun onResolveFailed(info: NsdServiceInfo, code: Int) = finish(null, code)
            })
        }.onFailure { finish(null, -1) }
    }
}
