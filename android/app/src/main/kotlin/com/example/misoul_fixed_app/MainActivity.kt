package com.example.misoul_fixed_app

import android.media.MediaPlayer
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.app/play_audio"
    private var mediaPlayer: MediaPlayer? = null
    private var isPaused: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "playAudio" -> {
                    val fileName = call.argument<String>("fileName")
                    playAudio(fileName)
                    result.success("Đang phát nhạc")
                }
                "pauseAudio" -> {
                    pauseAudio()
                    result.success("Nhạc đã tạm dừng")
                }
                "resumeAudio" -> {
                    resumeAudio()
                    result.success("Nhạc đã tiếp tục")
                }
                "stopAudio" -> {
                    stopAudio()
                    result.success("Nhạc đã dừng")
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun playAudio(fileName: String?) {
        val resId = resources.getIdentifier(fileName?.replace(".mp3", ""), "raw", packageName)
        if (resId != 0) {
            mediaPlayer?.release()
            mediaPlayer = MediaPlayer.create(this, resId)
            mediaPlayer?.start()
            isPaused = false
        }
    }

    private fun pauseAudio() {
        mediaPlayer?.let {
            if (it.isPlaying) {
                it.pause()
                isPaused = true
            }
        }
    }

    private fun resumeAudio() {
        mediaPlayer?.let {
            if (isPaused) {
                it.start()
                isPaused = false
            }
        }
    }

    private fun stopAudio() {
        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null
        isPaused = false
    }
}
