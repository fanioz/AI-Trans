/*
 *  This file is part of Trans AI
 *
 *  Copyright 2009-2010 fanio zilla <fanio.zilla@gmail.com>
 *
 *  @see license.txt
 */

/**
 * A Road Pathfinder.
 *  This road pathfinder tries to find a buildable / existing route for
 *  road vehicles.
 */

class Road_PF extends Road_PT
{
	/** Every estimate is multiplied by this value.
	 * Use 1 for a 'perfect' route, higher values for faster pathfinding. */
	_estimate_multiplier = null;

	/** A Road route finder constructor */
	constructor() {
		Road_PT.constructor();
		SetName("Road Finder");
		_estimate_multiplier = 1.2;
		_max_bridge_length = 50;
	}

	function _Neighbours(path, cur_node) {
		local n_tiles = Road_PT._Neighbours(path, cur_node);
		if (path.GetLength() > _max_len) return n_tiles;
		//if (n_tiles.len()) Info("existing have:", n_tiles.len());
		local parn = path.GetParent();
		local prev_tile = parn ? parn.GetTile() : null;
		local pp_tile = prev_tile ? (parn.GetParent() ? parn.GetParent().GetTile() : null) : null;
		Debug.Sign(cur_node, "R");
		/* Check if the current tile is part of a bridge or tunnel. */
		if (XTile.IsBridgeTunnel(cur_node) && AIRoad.HasRoadType(cur_node, AIRoad.GetCurrentRoadType())) {
			if (prev_tile && _CheckTunnelBridge(prev_tile, cur_node)) {
				//handled
			} else {
				local other_end = XTile.GetBridgeTunnelEnd(cur_node);
				local next = XTile.NextTile(other_end, cur_node);
				_accountant.ResetCosts();
				if (AIRoad.AreRoadTilesConnected(next, other_end)) {
					//handled;
				} else if (AIRoad.BuildRoad(other_end, next)) {
					n_tiles.push([tile, _GetDirection(other_end, next, false), _accountant.GetCosts()]);
				}
			}
		} else if (prev_tile && AIMap.DistanceManhattan(cur_node, prev_tile) > 1) {
			/* If the two tiles are more then 1 tile apart, the pathfinder wants a bridge or tunnel
			 * to be build. It isn't an existing bridge / tunnel, as that case is already handled. */
			local next = XTile.NextTile(prev_tile, cur_node);
			if (AIRoad.AreRoadTilesConnected(next, cur_node)) {
				n_tiles.push([next, _GetDirection(cur_node, next, false), 0]);
			} else {
				_accountant.ResetCosts();
				if (AIRoad.BuildRoad(cur_node, next)) {
					n_tiles.push([next, _GetDirection(cur_node, next, false), _accountant.GetCosts()]);
				}
			}
		} else {
			local bridge_dir =  0;
			if (prev_tile) {
				bridge_dir = _GetDirection(prev_tile, cur_node, true) << 4;
				if (XTile.IsNextSlopedUp(prev_tile, cur_node)) {
					n_tiles.extend(GetTunnels(prev_tile, cur_node, bridge_dir));
				}
				local tile = XTile.NextTile(prev_tile, cur_node);
				if (AITile.HasTransportType(tile, AITile.TRANSPORT_RAIL) ||
						((XTile.Height(tile) < XTile.Height(cur_node)) &&
						 (!XTile.IsFlat(cur_node)))) {
					n_tiles.extend(GetBridges(prev_tile, cur_node, bridge_dir));
				}
			}
			foreach(tile in XTile.Adjacent(cur_node)) {
				if (AIRoad.AreRoadTilesConnected(cur_node, tile)) continue;  // handled
				if (prev_tile == tile) continue;
				_accountant.ResetCosts();
				if (prev_tile == null) {
					if (AIRoad.BuildRoad(cur_node, tile)) {
						n_tiles.push([tile, _GetDirection(cur_node, tile, false), _accountant.GetCosts()]);
					}
				} else if (XTile.IsRoadBuildable(tile) && XRoad.CanExit(prev_tile, cur_node, tile)) {
					if (AIRoad.BuildRoad(cur_node, tile) || AIError.GetLastError() == AIError.ERR_VEHICLE_IN_THE_WAY) {
						n_tiles.push([tile, _GetDirection(cur_node, tile, false), _accountant.GetCosts()]);
					} else DebugOn(cur_node, tile);
				} else if (_CheckTunnelBridge(cur_node, tile)) {
					if (AIRoad.BuildRoad(cur_node, tile)) {
						n_tiles.push([tile, _GetDirection(cur_node, tile, false), _accountant.GetCosts()]);
					} else DebugOn(cur_node, tile);
				} else  {
				}
			}
		}
		return n_tiles;
	}

	function _Estimate(path, cur_tile) {
		local leng = path.Count();
		local cost = path.GetCost() / leng;
		if (path.GetLastCost() > 0) {
			if (leng > 2) {
				assert(path.GetTile() != cur_tile);
				local prev = path.GetParent().GetTile();
				if (!XTile.IsStraight(cur_tile, prev)) cost *= 2;
			}
		}
		return (Road_PT._Estimate(path, cur_tile) * cost * _estimate_multiplier).tointeger();
	}

	/**
	* Get a list of all bridges that can be build from the
	* current tile. Bridges will only be build starting on non-flat tiles
	* for performance reasons..
	*/
	function GetBridges(prev_tile, cur_node, bridge_dir) {
		/** bridge */
		local i = 1;
		local tiles = [];
		local bridge_list = AIBridgeList();
		bridge_list.Valuate(AIBridge.GetMaxLength);
		while (i < _max_bridge_length) {
			i++;
			bridge_list.RemoveBelowValue(i);
			if (bridge_list.IsEmpty()) break;
			local target = XTile.NextTileNum(prev_tile, cur_node, i);
			if (!XTile.IsRoadBuildable(target)) continue;
			if (AITile.GetMaxHeight(target) == 0) continue;
			local b2b = CLList(bridge_list);
			b2b.Valuate(AIBridge.GetMaxSpeed);
			_accountant.ResetCosts();
			if (AIBridge.BuildBridge(AIVehicle.VT_ROAD, b2b.Pop(), cur_node, target)) {
				tiles.push([target, bridge_dir, _accountant.GetCosts()]);
			}
		}
		return tiles;
	}

	/** Tunnels will only be build if no terraforming
	 *  is needed on both ends. */
	function GetTunnels(last_node, cur_node, bridge_dir) {
		local tiles = [];
		local other_tunnel_end = AITunnel.GetOtherTunnelEnd(cur_node);
		if (XTile.NextTile(other_tunnel_end, cur_node) == last_node) {
			//assert(AITunnel.GetOtherTunnelEnd (other_tunnel_end) == cur_node);
			if (Assist.IsBetween(AIMap.DistanceManhattan(cur_node, other_tunnel_end), 2, _max_tunnel_length)) {
				_accountant.ResetCosts();
				if (AITunnel.BuildTunnel(AIVehicle.VT_ROAD, cur_node)) {
					tiles.push([other_tunnel_end, bridge_dir, _accountant.GetCosts()]);
				}
			}
		}
		return tiles;
	}

	function DebugOn(cur_node, next_tile) {
		if (AIError.GetLastError() == AIError.ERR_NOT_ENOUGH_CASH) return;
		Warn("fail", AIError.GetLastErrorString());
		//Debug.Sign(cur_node, "c");
		//Debug.Sign(next_tile, "n");
	}

}
