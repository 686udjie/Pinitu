package com.mousica.pinitu

import android.content.ContentValues
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.mousica.pinitu/gallery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "saveToAlbum" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                    val isVideo = call.argument<Boolean>("isVideo")
                    val albumName = call.argument<String>("albumName")
                    if (bytes != null && isVideo != null && albumName != null) {
                        saveToAlbum(bytes, isVideo, albumName, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Arguments are null", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun saveToAlbum(bytes: ByteArray, isVideo: Boolean, albumName: String, result: MethodChannel.Result) {
        try {
            val contentValues = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, if (isVideo) "downloaded_video.mp4" else "downloaded_image.jpg")
                put(MediaStore.MediaColumns.MIME_TYPE, if (isVideo) "video/mp4" else "image/jpeg")
                put(MediaStore.MediaColumns.RELATIVE_PATH, if (isVideo) "${Environment.DIRECTORY_PICTURES}/$albumName" else "${Environment.DIRECTORY_PICTURES}/$albumName")
                put(MediaStore.MediaColumns.DATE_ADDED, System.currentTimeMillis())
            }
            val uri = if (isVideo) {
                contentResolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, contentValues)
            } else {
                contentResolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, contentValues)
            }
            uri?.let {
                contentResolver.openOutputStream(it)?.use { output ->
                    output.write(bytes)
                }
                result.success("Saved to gallery")
            } ?: result.error("SAVE_FAILED", "Failed to insert to MediaStore", null)
        } catch (e: Exception) {
            result.error("SAVE_FAILED", e.message, null)
        }
    }
}
