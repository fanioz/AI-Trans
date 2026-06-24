/*
 * Mocks for OpenTTD AI API
 */

class AIError {
	static _last_error = 0;
	static ERR_NONE = 0;
	static ERR_UNKNOWN = 1;

	static function GetLastError() {
		local err = _last_error;
		_last_error = ERR_NONE;
		return err;
	}

	static function SetLastError(err) {
		_last_error = err;
	}
}

class AITestMode {
	constructor() {}
}

class AISign {
	static function BuildSign(tile, text) {
		return 1;
	}
}

class AIMap {
	static function GetTileIndex(x, y) {
		return (y << 10) | x;
	}
}

class AILog {
	static function Info(text) { ::print("INFO: " + text + "\n"); }
	static function Warning(text) { ::print("WARN: " + text + "\n"); }
	static function Error(text) { ::print("ERROR: " + text + "\n"); }
}

class AIController {
	static _settings = {
		debug_log = true,
		debug_signs = false,
		debug_break = false
	};
	static function GetSetting(name) {
		if (name in _settings) return _settings[name];
		return null;
	}
}

class CLString {
	static function Join(arr, sep) {
		local res = "";
		foreach (i, v in arr) {
			if (i > 0) res += sep;
			res += v.tostring();
		}
		return res;
	}
}

// Global require mock if needed, but we'll use squirrel's dofile or similar in runner
function require(path) {
	// In mock environment, we might not need this if we manually load files
}
