package cc.lycstar.flit.lsp

import android.util.Log
import cc.lycstar.flit.env.FlitEnv
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.io.InputStream
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.ScheduledFuture
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/** Process-scoped JSON-RPC transport. Dart owns the LSP lifecycle/handshake. */
object LspServer {
    private class Pending(val callback: (String?) -> Unit) {
        var timeout: ScheduledFuture<*>? = null
        fun finish(json: String?) { timeout?.cancel(false); callback(json) }
    }
    private class Session(val process: Process, val id: Int) {
        val pending = ConcurrentHashMap<Int, Pending>()
        val writeLock = Any()
        fun drain() { pending.keys.toList().forEach { pending.remove(it)?.finish(null) } }
    }
    @Volatile private var current: Session? = null
    private val nextId = AtomicInteger(1)
    private val timer = Executors.newSingleThreadScheduledExecutor { r ->
        Thread(r, "lsp-timeout").apply { isDaemon = true }
    }
    @Volatile var onNotify: ((String) -> Unit)? = null
    val isRunning: Boolean get() = current?.process?.isAlive == true

    @Synchronized fun start(dartBin: String, rootPath: String, sessionId: Int): Boolean {
        stop()
        if (!File(dartBin).exists()) return false
        return try {
            val builder = ProcessBuilder(dartBin, "language-server", "--protocol=lsp")
            builder.environment().clear()
            builder.environment().putAll(FlitEnv.environment())
            builder.directory(File(rootPath))
            val session = Session(builder.start(), sessionId)
            current = session
            Thread {
                try { readLoop(session) }
                catch (e: Exception) { Log.w("flit-lsp", "read: ${e.message}") }
                finally {
                    synchronized(this) {
                        if (current === session) {
                            current = null
                            session.process.destroy()
                            onNotify?.invoke("{\"jsonrpc\":\"2.0\",\"method\":\"flit/serverExited\",\"params\":{},\"flitSession\":${session.id}}")
                        }
                    }
                    session.drain()
                }
            }.apply { name = "lsp-reader"; start() }
            Thread {
                try { session.process.errorStream.bufferedReader().forEachLine {
                    Log.w("flit-lsp", it.take(300))
                } } catch (_: Exception) { }
            }.apply { name = "lsp-stderr"; start() }
            true
        } catch (e: Exception) {
            Log.w("flit-lsp", "start: ${e.message}")
            false
        }
    }

    fun request(method: String, paramsJson: String, cb: (String?) -> Unit): Boolean {
        val session = current ?: return false
        val id = nextId.getAndIncrement()
        val pending = Pending(cb)
        session.pending[id] = pending
        pending.timeout = timer.schedule({
            session.pending.remove(id)?.finish(null)
        }, 25, TimeUnit.SECONDS)
        return try {
            send(session, JSONObject().put("jsonrpc", "2.0").put("id", id)
                .put("method", method).put("params", JSONObject(paramsJson)).toString())
            true
        } catch (e: Exception) {
            session.pending.remove(id)?.timeout?.cancel(false)
            false
        }
    }

    fun notify(method: String, paramsJson: String): Boolean {
        val session = current ?: return false
        return try {
            send(session, JSONObject().put("jsonrpc", "2.0").put("method", method)
                .put("params", JSONObject(paramsJson)).toString())
            true
        } catch (_: Exception) { false }
    }

    @Synchronized fun stop() {
        val old = current
        current = null
        old?.process?.destroy()
        old?.drain()
    }

    private fun send(session: Session, json: String) = synchronized(session.writeLock) {
        check(current === session && session.process.isAlive)
        val bytes = json.toByteArray(Charsets.UTF_8)
        session.process.outputStream.apply {
            write("Content-Length: ${bytes.size}\r\n\r\n".toByteArray(Charsets.US_ASCII))
            write(bytes)
            flush()
        }
    }

    private fun readLoop(session: Session) {
        val input = session.process.inputStream
        while (current === session) {
            var length: Int? = null
            while (true) {
                val line = readHeaderLine(input) ?: return
                if (line.isEmpty()) break
                val parts = line.split(':', limit = 2)
                if (parts.size == 2 && parts[0].equals("Content-Length", true)) {
                    length = parts[1].trim().toIntOrNull()
                }
            }
            val size = length ?: throw IllegalStateException("Missing Content-Length")
            check(size in 0..(32 * 1024 * 1024))
            val bytes = ByteArray(size)
            var offset = 0
            while (offset < size) {
                val count = input.read(bytes, offset, size - offset)
                if (count < 0) return
                offset += count
            }
            route(session, String(bytes, Charsets.UTF_8))
        }
    }

    private fun route(session: Session, json: String) {
        val message = JSONObject(json)
        if (message.has("method")) {
            if (current !== session) return
            if (!message.has("id")) { onNotify?.invoke(message.put("flitSession", session.id).toString()); return }
            val response = JSONObject().put("jsonrpc", "2.0").put("id", message.get("id"))
            when (message.getString("method")) {
                "workspace/configuration" -> {
                    val count = message.optJSONObject("params")?.optJSONArray("items")?.length() ?: 0
                    val values = JSONArray()
                    repeat(count) { values.put(JSONObject.NULL) }
                    response.put("result", values)
                }
                "client/registerCapability", "client/unregisterCapability", "window/workDoneProgress/create" ->
                    response.put("result", JSONObject.NULL)
                else -> response.put("error", JSONObject().put("code", -32601).put("message", "Unsupported client method"))
            }
            send(session, response.toString())
        } else {
            val id = message.opt("id") as? Number ?: return
            session.pending.remove(id.toInt())?.finish(json)
        }
    }

    private fun readHeaderLine(input: InputStream): String? {
        val bytes = java.io.ByteArrayOutputStream()
        while (bytes.size() < 8192) {
            val b = input.read()
            if (b == -1) return null
            if (b == 10) return bytes.toString("US-ASCII").trimEnd('\r')
            bytes.write(b)
        }
        throw IllegalStateException("Oversized LSP header")
    }
}
