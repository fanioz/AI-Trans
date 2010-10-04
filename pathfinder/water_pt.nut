/*  09.08.07 - water.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * A Water path tracker.
 * This route tracker tries to find an existing route for ships.
 */
class Water_PT extends Road_PT
{
	constructor()
	{
		Road_PT.constructor();
		SetName("Water Tracker");
		_vhc_max_spd = max(0, AIEngine.GetMaxSpeed(AIEngineList(AIVehicle.VT_WATER).Begin()));
	}
	/*
	function InitializePath (sources, goals, ignored_tiles) {
		Road_PT.InitializePath(sources, goals, ignored_tiles);
		_max_len = ((_max_len - 20) / 1.2 + 20).tointeger();
		Info ("max len:", _max_len);
	}
	*/
	function _Neighbours(path, cur_node) {
		if (!AITile.HasTransportType(cur_node, AITile.TRANSPORT_WATER)) return [];
		local tiles = [];
		local parn = path.GetParent();
		local prev_tile = parn ? parn.GetTile() : null;
		Debug.Sign(cur_node, "x");
		if (AIBridge.IsBridgeTile(cur_node)) {
			local other_end = XTile.GetBridgeTunnelEnd(cur_node);
			if (prev_tile && _CheckTunnelBridge (prev_tile, cur_node)) {
				//in
				local cost = 0; // XTile.BridgeCost(this, path, cur_node);
				tiles.push ([other_end, _GetDirection (prev_tile, cur_node, true) << 4, cost]);
			} else {
				//out
				local next = XTile.NextTile (other_end, cur_node);
				if (AIMarine.AreWaterTilesConnected (next, other_end)) {
					tiles.push ([next, _GetDirection (other_end, next, false), 0]);
				}
			}
		} else {
			foreach (tile in XTile.Adjacent(cur_node))
			{
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
};


 class Water_PF extends Water_PT
 {
 	/** Every estimate is multiplied by this value.
	 * Use 1 for a 'perfect' route, higher values for faster pathfinding. */
	_estimate_multiplier = null;
	constructor()
	{
		Water_PT.constructor();
		_estimate_multiplier = 1;
	}
	function _Estimate (path, cur_tile) {
		return Water_PT._Estimate (path, cur_tile) * _estimate_multiplier;
	}
 }

