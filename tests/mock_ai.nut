/**
 * Mocking layer for OpenTTD AI API
 */

class AIMap {
	static function GetTileX(tile) {
		return tile % 2000;
	}
	static function GetTileY(tile) {
		return tile / 2000;
	}
	static function GetTileIndex(x, y) {
		return y * 2000 + x;
	}
	static function IsValidTile(tile) {
		return tile >= 0;
	}
	static function DistanceManhattan(t1, t2) {
		local x1 = AIMap.GetTileX(t1);
		local y1 = AIMap.GetTileY(t1);
		local x2 = AIMap.GetTileX(t2);
		local y2 = AIMap.GetTileY(t2);
		local dx = x1 - x2;
		local dy = y1 - y2;
		if (dx < 0) dx = -dx;
		if (dy < 0) dy = -dy;
		return dx + dy;
	}
}

class AITile {
}

class CLList {
	items = null;
	constructor() {
		items = [];
	}
	function AddTile(tile) {
		items.push(tile);
	}
	function Count() {
		return items.len();
	}
	function _nexti(prev) {
		if (prev == null) return 0;
		if (prev >= items.len() - 1) return null;
		return prev + 1;
	}
	function _get(index) {
		return items[index];
	}
}

class XTile {
	static function NE_Of(tile, num) { return AIMap.GetTileIndex(AIMap.GetTileX(tile) - num, AIMap.GetTileY(tile)); }
	static function SW_Of(tile, num) { return AIMap.GetTileIndex(AIMap.GetTileX(tile) + num, AIMap.GetTileY(tile)); }
	static function NW_Of(tile, num) { return AIMap.GetTileIndex(AIMap.GetTileX(tile), AIMap.GetTileY(tile) - num); }
	static function SE_Of(tile, num) { return AIMap.GetTileIndex(AIMap.GetTileX(tile), AIMap.GetTileY(tile) + num); }
	static function S_Of(tile, num) { return AIMap.GetTileIndex(AIMap.GetTileX(tile) + num, AIMap.GetTileY(tile) + num); }
	static function MakeArea(tile, x, y, r) { return []; }
}
