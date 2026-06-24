/*
 * Mocks for OpenTTD AI API
 */

class AITile {
	static _water_tiles = {};

	static function IsWaterTile(tile) {
		return (tile in AITile._water_tiles);
	}
}

class XTile {
	static _adjacents = {};

	static function Adjacent(tile) {
		if (tile in XTile._adjacents) {
			foreach(adj in XTile._adjacents[tile]) {
				yield adj;
			}
		}
	}
}

// Global logger mocks
function Info(msg, val = "") { ::print("INFO: " + msg + " " + val + "\n"); }
function Warn(msg, val = "") { ::print("WARN: " + msg + " " + val + "\n"); }
