package com.example.pick_up_recipe

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Экран не должен гаснуть во время заваривания.
 *
 * Готового плагина не подключаем намеренно: стенд работает без интернета,
 * а вся нужная функциональность — один флаг окна. Flutter просит его через
 * канал: включает на старте заваривания и снимает, уходя с экрана.
 */
class MainActivity : FlutterActivity() {
    private val channel = "pickuprecipe/screen"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "keepAwake" -> {
                    val on = call.argument<Boolean>("on") ?: false
                    // runOnUiThread: флаг окна трогается только с UI-потока,
                    // а вызов приходит из потока платформенного канала.
                    runOnUiThread {
                        if (on) {
                            window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        } else {
                            window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                        }
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
}
