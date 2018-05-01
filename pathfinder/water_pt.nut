/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2018 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * A Water path tracker.
 * This route tracker tries to find an existing route for ships.
 */
class Water_PT extends Road_PT
{
	constructor() {
		Road_PT.constructor();
		SetName("Water Tracker");
		/* not yet implemented */
		//_vhc_max_spd = max(0, AIEngine.GetMaxSpeed(AIEngineList(AIVehicle.VT_WATER).Begin()));
	}

	function InitializePath(sources, goals, ignored_tiles) {
		Road_PT.InitializePath(sources, goals, ignored_tiles);
		_max_len = ((_max_len - 20) / 1.2 + 20).tointeger();
		Info("nautical max len:", _max_len);
	}

	function _Neighbours(path, cur_node) {
		local tiles = [];
		local parn = path.GetParent();
		local prev_tile = parn ? parn.GetTile() : null;
		Debug.SignPF(cur_node, "W");
		if (AIBridge.IsBridgeTile(cur_node)) {
			local other_end = XTile.GetBridgeTunnelEnd(cur_node);
			if (prev_tile && _CheckTunnelBridge(prev_tile, cur_node)) {
				//in
				local cost = 0; // XTile.BridgeCost(this, path, cur_node);
				tiles.push([other_end, _GetDirection(prev_tile, cur_node, true) << 4, cost]);
			} else {
				//out
				local next = XTile.NextTile(other_end, cur_node);
				if (AIMarine.AreWaterTilesConnected(next, other_end)) {
					tiles.push([next, _GetDirection(other_end, next, false), 0]);
				}
			}
		} else {
			foreach(tile in XTile.Adjacent(cur_node)) {
				if (AITile.HasTransportType(tile, AITile.TRANSPORT_WATER) ||
						AIMarine.IsDockTile(tile) ||
						AIMarine.IsWaterDepotTile(tile) ||
						AIMarine.IsBuoyTile(tile) ||
						AIMarine.AreWaterTilesConnected(cur_node, tile)) {
					tiles.push([tile, _GetDirection(cur_node, tile, false), 0]);
				}
			}
		}
		return tiles;
	}
	
	function ShapeIt(path) {
		local shape = Road_PT.ShapeIt(path);
		if (path.Count() == 0) return shape;
		shape += path.GetCost();
		return shape;
	}
};


class Water_PF extends Water_PT
{
	constructor() {
		Water_PT.constructor();
	}
}
