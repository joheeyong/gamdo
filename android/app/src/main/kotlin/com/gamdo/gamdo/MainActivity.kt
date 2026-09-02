package com.gamdo.gamdo

import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 인스타그램 스토리·피드 편집 화면으로 사진을 바로 넘긴다.
 *
 * OS 공유 시트를 띄우지 않는다. 스토리는 Meta가 문서로 지원하는
 * `com.instagram.share.ADD_TO_STORY` 인텐트를 쓰고, 피드는 인스타그램
 * 패키지를 명시한 전송 인텐트를 쓴다 (패키지를 지정하면 선택 창이 뜨지 않는다).
 *
 * 어느 쪽이든 마지막 공유 버튼은 사용자가 인스타그램 안에서 누른다.
 */
class MainActivity : FlutterActivity() {

    private companion object {
        const val CHANNEL = "gamdo/instagram_share"
        const val INSTAGRAM_PACKAGE = "com.instagram.android"
        const val STORY_ACTION = "com.instagram.share.ADD_TO_STORY"

        const val RESULT_OPENED = "opened"
        const val RESULT_NOT_INSTALLED = "notInstalled"
        const val RESULT_FAILED = "failed"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isInstalled" -> result.success(isInstagramInstalled())

                    "shareToStory" -> result.success(
                        shareToStory(
                            call.argument<String>("path"),
                            call.argument<String>("sourceApplicationId"),
                        )
                    )

                    "shareToFeed" -> result.success(
                        shareToFeed(call.argument<String>("path"))
                    )

                    else -> result.notImplemented()
                }
            }
    }

    private fun isInstagramInstalled(): Boolean =
        try {
            packageManager.getPackageInfo(INSTAGRAM_PACKAGE, 0)
            true
        } catch (_: PackageManager.NameNotFoundException) {
            false
        }

    /** 앱 캐시의 파일을 인스타그램이 읽을 수 있는 content:// URI로 바꾼다. */
    private fun contentUriFor(path: String?): Uri? {
        if (path.isNullOrEmpty()) return null
        val file = File(path)
        if (!file.exists()) return null
        return try {
            FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        } catch (_: IllegalArgumentException) {
            // file_paths.xml에 없는 경로 — 설정 문제이므로 실패로 알린다
            null
        }
    }

    private fun shareToStory(path: String?, sourceApplicationId: String?): String {
        if (!isInstagramInstalled()) return RESULT_NOT_INSTALLED
        val uri = contentUriFor(path) ?: return RESULT_FAILED

        val intent = Intent(STORY_ACTION).apply {
            setDataAndType(uri, "image/*")
            // 스토리 인텐트는 패키지를 지정하지 않는다 — 액션 자체가
            // 인스타그램 전용이고, 지정하면 일부 버전에서 거부된다.
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            sourceApplicationId?.let { putExtra("source_application", it) }
        }

        return try {
            startActivity(intent)
            RESULT_OPENED
        } catch (_: ActivityNotFoundException) {
            RESULT_FAILED
        }
    }

    private fun shareToFeed(path: String?): String {
        if (!isInstagramInstalled()) return RESULT_NOT_INSTALLED
        val uri = contentUriFor(path) ?: return RESULT_FAILED

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "image/*"
            // 패키지를 지정하면 OS 선택 창 없이 인스타그램이 바로 열린다
            setPackage(INSTAGRAM_PACKAGE)
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        return try {
            startActivity(intent)
            RESULT_OPENED
        } catch (_: ActivityNotFoundException) {
            RESULT_FAILED
        }
    }
}
