/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
* A Road Path Tracker.
* This path tracker tries to find an existing route for road type.
*/
class Road_PT extends AyStar
{
	_vhc_max_spd = null;

	/** A Road route finder constructor */
	constructor() {
		AyStar.constructor("Road Tracker");
		assert(AIRoad.IsRoadTypeAvailable(AIRoad.GetCurrentRoadType()));
		/* not yet implemented */
		//_vhc_max_spd = max(0, AIEngine.GetMaxSpeed(AIEngineList(AIVehicle.VT_ROAD).Begin()));
	}

	function _GetDirection(from, to, is_bridge) {
		if (!is_bridge && XTile.IsFlat(to)) return 0xFF;
		if (from - to == 1) return 1;
		if (from - to == -1) return 2;
		if (from - to == AIMap.GetMapSizeX()) return 4;
		if (from - to == -AIMap.GetMapSizeX()) return 8;
		Debug.Sign(from, "from");
		Debug.Sign(to, "to");
		throw "should not come here";
	}

	function InitializePath(sources, goals, ignored_tiles) {
		assert(typeof(sources) == "array");
		assert(typeof(goals) == "array");

		Info("sources:", sources.len(), "dests:", goals.len());
		assert(sources.len());
		assert(goals.len());

		local nsources = [];

		foreach(node in sources) {
			nsources.push([node, 0xFF, 0]);
		}

		Initialize(nsources, goals, ignored_tiles);
		this._max_len = (20 + 1.2 * this._max_len).tointeger();
		Info("Add.max len:", this._max_len);
	}

	function _Neighbours(path, cur_node) {
		if (!AIRoad.HasRoadType(cur_node, AIRoad.GetCurrentRoadType())) return [];
		if (path.GetLength() > this._max_len) return [];

		local tiles = [];
		local parn = path.GetParent();
		local prev_tile = parn ? parn.GetTile() : null;
		if (XTile.IsBridgeOrTunnel(cur_node)) {
			local other_end = XTile.GetBridgeTunnelEnd(cur_node);
			local next = XTile.NextTile(other_end, cur_node);
			if (AIRoad.AreRoadTilesConnected(cur_node, next)) {
				tiles.push([next, this._GetDirection(cur_node, next, false), 0]);
			}
			/* The other end of the bridge / tunnel is a neighbour. Exist thus 0 cost*/
			tiles.push([other_end, this._GetDirection(next, cur_node, true) << 4, 0]);
		} else if (prev_tile && AIMap.DistanceManhattan(cur_node, prev_tile) > 1) {
			/* If the two tiles are more then 1 tile apart, the pathfinder wants a bridge or tunnel
			 * to be build. It isn't an existing bridge / tunnel, as that case is already handled. */
			local next = XTile.NextTile(prev_tile, cur_node);
			if (AIRoad.AreRoadTilesConnected(next, cur_node)) {
				tiles.push([next, _GetDirection(cur_node, next, false), 0]);
			}
		} else {
			foreach(tile in XTile.Adjacent(cur_node)) {
				if (AIRoad.AreRoadTilesConnected(cur_node, tile)) {
					tiles.push([tile, _GetDirection(cur_node, tile, false), 0]);
				} else if (_CheckTunnelBridge(cur_node, tile)) {
					if (AIRoad.AreRoadTilesConnected(cur_node, tile)) {
						tiles.push([tile, _GetDirection(cur_node, tile, false), 0]);
					}
				}
			}
		}
		return tiles;
	}
	
	function _Cost(path, new_tile, new_direction) {
		if ((path == null)  || (path.Count() == 0)) return 1;
		return path.GetCost() + 1;
	}
}
