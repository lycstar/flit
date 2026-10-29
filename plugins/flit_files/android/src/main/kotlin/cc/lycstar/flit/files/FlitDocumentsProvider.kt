package cc.lycstar.flit.files

import android.database.Cursor
import android.database.MatrixCursor
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import android.provider.DocumentsContract.Root
import android.provider.DocumentsProvider
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileNotFoundException
import java.io.IOException

/**
 * 把工程根 $HOME/projects 挂成系统「文件」应用的一个根(Termux 同款):
 * 用户在任何支持 SAF 的文件管理器里都能浏览/复制/编辑工程, 不需要本应用在场,
 * 这是"卸载即删"之外的备份出口。只暴露工程目录, 不暴露工具链。
 *
 * documentId: 根 = "projects", 其余 = "projects/<相对路径>"; 一律 canonical 后
 * 再比对前缀, 拒绝 .. 与符号链接越界。
 */
class FlitDocumentsProvider : DocumentsProvider() {
    private companion object {
        const val ROOT_ID = "projects"
        val ROOT_PROJECTION = arrayOf(
            Root.COLUMN_ROOT_ID,
            Root.COLUMN_DOCUMENT_ID,
            Root.COLUMN_TITLE,
            Root.COLUMN_SUMMARY,
            Root.COLUMN_ICON,
            Root.COLUMN_FLAGS,
            Root.COLUMN_MIME_TYPES,
        )
        val DOCUMENT_PROJECTION = arrayOf(
            Document.COLUMN_DOCUMENT_ID,
            Document.COLUMN_DISPLAY_NAME,
            Document.COLUMN_MIME_TYPE,
            Document.COLUMN_FLAGS,
            Document.COLUMN_SIZE,
            Document.COLUMN_LAST_MODIFIED,
        )
        // MimeTypeMap 不认识的源码后缀按文本给, 文件管理器才会提供"用文本编辑器打开"
        val TEXT_EXTENSIONS = setOf(
            "dart", "yaml", "yml", "kt", "kts", "gradle", "md", "properties",
            "lock", "gitignore", "toml", "sh", "arb", "iml",
        )
    }

    private lateinit var root: File
    private lateinit var authority: String

    override fun onCreate(): Boolean {
        val ctx = context ?: return false
        // 与 FlitEnv 同布局: files/home = $HOME, 工程根 = $HOME/projects
        root = File(ctx.filesDir, "home/projects").apply { mkdirs() }.canonicalFile
        authority = "${ctx.packageName}.documents"
        return true
    }

    override fun queryRoots(projection: Array<out String>?): Cursor =
        MatrixCursor(projection ?: ROOT_PROJECTION).apply {
            newRow()
                .add(Root.COLUMN_ROOT_ID, ROOT_ID)
                .add(Root.COLUMN_DOCUMENT_ID, ROOT_ID)
                .add(Root.COLUMN_TITLE, "Flit 工程")
                .add(Root.COLUMN_SUMMARY, "~/projects")
                .add(Root.COLUMN_ICON, R.drawable.flit_documents_root)
                .add(
                    Root.COLUMN_FLAGS,
                    Root.FLAG_LOCAL_ONLY or Root.FLAG_SUPPORTS_CREATE or Root.FLAG_SUPPORTS_IS_CHILD,
                )
                .add(Root.COLUMN_MIME_TYPES, null)
        }

    override fun queryDocument(documentId: String, projection: Array<out String>?): Cursor =
        MatrixCursor(projection ?: DOCUMENT_PROJECTION).also { include(it, fileFor(documentId)) }

    override fun queryChildDocuments(
        parentDocumentId: String,
        projection: Array<out String>?,
        sortOrder: String?,
    ): Cursor {
        val parent = fileFor(parentDocumentId)
        val children = parent.listFiles() ?: throw FileNotFoundException("无法列出 $parentDocumentId")
        val cursor = MatrixCursor(projection ?: DOCUMENT_PROJECTION)
        // 目录在前, 再按名(忽略大小写), 与文件管理器习惯一致
        children
            .sortedWith(compareBy({ !it.isDirectory }, { it.name.lowercase() }))
            .forEach { include(cursor, it) }
        return cursor
    }

    override fun isChildDocument(parentDocumentId: String, documentId: String): Boolean =
        documentId == parentDocumentId || documentId.startsWith("$parentDocumentId/")

    override fun openDocument(
        documentId: String,
        mode: String,
        signal: CancellationSignal?,
    ): ParcelFileDescriptor =
        ParcelFileDescriptor.open(fileFor(documentId), ParcelFileDescriptor.parseMode(mode))

    override fun createDocument(parentDocumentId: String, mimeType: String, displayName: String): String {
        val parent = fileFor(parentDocumentId)
        val name = safeName(displayName)
        var target = File(parent, name)
        var n = 2
        while (target.exists()) target = File(parent, "$name (${n++})")
        val created = try {
            if (mimeType == Document.MIME_TYPE_DIR) target.mkdir() else target.createNewFile()
        } catch (e: IOException) {
            throw FileNotFoundException("无法创建 ${target.name}: ${e.message}")
        }
        if (!created) throw FileNotFoundException("无法创建 ${target.name}")
        changed(parentDocumentId)
        return docIdFor(target)
    }

    override fun deleteDocument(documentId: String) {
        val file = fileFor(documentId)
        if (file == root) throw FileNotFoundException("不能删除工程根")
        val deleted = if (file.isDirectory) file.deleteRecursively() else file.delete()
        if (!deleted) throw FileNotFoundException("删除失败 ${file.name}")
        changed(parentIdOf(documentId))
    }

    override fun renameDocument(documentId: String, displayName: String): String {
        val file = fileFor(documentId)
        if (file == root) throw FileNotFoundException("不能重命名工程根")
        val target = File(file.parentFile, safeName(displayName))
        if (target.exists() || !file.renameTo(target)) {
            throw FileNotFoundException("重命名失败 ${file.name}")
        }
        changed(parentIdOf(documentId))
        return docIdFor(target)
    }

    private fun include(cursor: MatrixCursor, file: File) {
        val isRoot = file == root
        val dir = file.isDirectory
        // 根只能往里建, 不能删/改名
        val flags = when {
            isRoot -> Document.FLAG_DIR_SUPPORTS_CREATE
            dir -> Document.FLAG_DIR_SUPPORTS_CREATE or Document.FLAG_DIR_PREFERS_LAST_MODIFIED or
                Document.FLAG_SUPPORTS_DELETE or Document.FLAG_SUPPORTS_RENAME
            else -> Document.FLAG_SUPPORTS_WRITE or Document.FLAG_SUPPORTS_DELETE or
                Document.FLAG_SUPPORTS_RENAME
        }
        cursor.newRow()
            .add(Document.COLUMN_DOCUMENT_ID, docIdFor(file))
            .add(Document.COLUMN_DISPLAY_NAME, if (isRoot) "Flit 工程" else file.name)
            .add(Document.COLUMN_MIME_TYPE, mimeOf(file))
            .add(Document.COLUMN_FLAGS, flags)
            .add(Document.COLUMN_SIZE, if (dir) null else file.length())
            .add(Document.COLUMN_LAST_MODIFIED, file.lastModified())
    }

    private fun mimeOf(file: File): String {
        if (file.isDirectory) return Document.MIME_TYPE_DIR
        val ext = file.extension.lowercase()
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext)
            ?: if (ext in TEXT_EXTENSIONS) "text/plain" else "application/octet-stream"
    }

    private fun safeName(displayName: String): String {
        val name = displayName.trim()
        if (name.isEmpty() || name == "." || name == ".." || name.contains('/')) {
            throw FileNotFoundException("非法名称 $displayName")
        }
        return name
    }

    private fun docIdFor(file: File): String {
        val rel = file.canonicalPath.removePrefix(root.path).trimStart('/')
        return if (rel.isEmpty()) ROOT_ID else "$ROOT_ID/$rel"
    }

    private fun fileFor(documentId: String): File {
        if (documentId != ROOT_ID && !documentId.startsWith("$ROOT_ID/")) {
            throw FileNotFoundException("未知文档 $documentId")
        }
        val file = File(root, documentId.removePrefix(ROOT_ID).trimStart('/')).canonicalFile
        if (file != root && !file.path.startsWith(root.path + File.separator)) {
            throw FileNotFoundException("越界 $documentId")
        }
        if (!file.exists()) throw FileNotFoundException("不存在 $documentId")
        return file
    }

    private fun parentIdOf(documentId: String): String =
        documentId.substringBeforeLast('/', ROOT_ID)

    /** 变更通知: 文件管理器正开着这个目录时即时刷新 */
    private fun changed(parentDocumentId: String) {
        context?.contentResolver?.notifyChange(
            DocumentsContract.buildChildDocumentsUri(authority, parentDocumentId),
            null,
        )
    }
}
