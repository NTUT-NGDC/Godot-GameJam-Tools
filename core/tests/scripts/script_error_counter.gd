extends Logger
## 測試用：數腳本錯誤（SCRIPT ERROR）。腳本錯誤會讓那個測試函式直接中斷、跑不到後面的 _expect，
## 不另外數的話，最後還是會印「全部 PASS」。
##   const ScriptErrors = preload("res://core/tests/scripts/script_error_counter.gd")
##   var errors: ScriptErrors = ScriptErrors.new()   # 一建立就開始數
##   ……跑測試……
##   _failures += errors.report()                      # 有腳本錯誤就算失敗

## 數到幾個腳本錯誤
var count: int = 0


func _init() -> void:
	OS.add_logger(self)


func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String,
		_editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_SCRIPT:
		count += 1


## 停止計數，回傳有幾個腳本錯誤（有的話印出 FAIL）
func report() -> int:
	OS.remove_logger(self)
	if count > 0:
		print("  FAIL 測試中出現 %d 個腳本錯誤（SCRIPT ERROR），往上找紅字" % count)
	return count
