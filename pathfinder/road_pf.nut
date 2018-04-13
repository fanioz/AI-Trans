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
	_cost_road_station = null;             ///< The cost for a road station tile.
	
	/** A Road route finder constructor */
	constructor() {
		Road_PT.constructor();
		SetName("Road Finder");
		_estimate_multiplier = 1.4;
		_max_bridge_length = 50;
		this._cost_road_station = 500;
	}

	function _Neighbours(path, cur_node) {
		local n_tiles = Road_PT._Neighbours(path, cur_node);
		if (path.GetLength() > _max_len) return n_tiles;
		/* _max_cost is the maximum path cost, if we go over it, the path isn't valid. */
		if (path.GetCost() >= this._max_cost) return [];
		//if (n_tiles.len()) Info("existing have:", n_tiles.len());
		local parn = path.GetParent();
		local prev_tile = parn ? parn.GetTile() : null;
		local pp_tile = prev_tile ? (parn.GetParent() ? parn.GetParent().GetTile() : null) : null;
		Debug.Sign(cur_node, "R");
		/* Check if the current tile is part of a bridge or tunnel. */
		if (XTile.IsBridgeOrTunnel(cur_node) && AIRoad.HasRoadType(cur_node, AIRoad.GetCurrentRoadType())) {
			local other_end = XTile.GetBridgeTunnelEnd(cur_node);
			local next = XTile.NextTile(other_end, cur_node);
			_accountant.ResetCosts();
			if (AIRoad.BuildRoad(cur_node, next)) {
				n_tiles.push([next, this._GetDirection(cur_node, next, false), _accountant.GetCosts()]);
			}
			/* The other end of the bridge / tunnel is a neighbour. Exist thus 0 cost*/
			n_tiles.push([other_end, this._GetDirection(next, cur_node, true) << 4, 0]);
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
					AITile.HasTransportType(tile, AITile.TRANSPORT_WATER) ||
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

	function _Cost(path, cur_tile, new_direction) {
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;

		local prev_tile = path.GetTile();
		local cost = 0;
		
		if (AIRoad.AreRoadTilesConnected(prev_tile, cur_tile)) {
			if (AITile.IsStationTile(cur_tile)) cost += this._cost_road_station;
			return path.GetCost() + cost;
		} else {
			cost += this._cost_no_existing_road
		}
		
		/* Try to avoid road/rail crossing because our busses/trucks will crash. */
		if (AITile.HasTransportType(cur_tile, AITile.TRANSPORT_RAIL) && !AITile.HasTransportType(cur_tile, AITile.TRANSPORT_ROAD)) 
			return this._max_cost;
		/* If the new tile is a bridge / tunnel tile, check whether we came from the other
		 * end of the bridge / tunnel or if we just entered the bridge / tunnel. */
		local distance = AIMap.DistanceManhattan(cur_tile, prev_tile);
		if (XTile.IsBridgeOrTunnel(cur_tile)) {
			local other_end = XTile.GetBridgeTunnelEnd(cur_tile);
			if (_CheckTunnelBridge(prev_tile, cur_tile)) {
				//in
				cost += distance * this._cost_tile;
				if (AIBridge.IsBridgeTile(cur_tile)) {
					cost += this._GetBridgeNumSlopes(cur_tile, prev_tile) * this._cost_slope;
				}
			} else {
				//out
				cost += this._cost_tile;
			}
			/* If the two tiles are more then 1 tile apart, the pathfinder wants a bridge or tunnel
			* to be build. It isn't an existing bridge / tunnel, as that case is already handled. */
		} else if (distance > 1) {
			/* Check if we should build a bridge or a tunnel. */
			if (AITunnel.GetOtherTunnelEnd(cur_tile) == prev_tile) {
				cost += distance * (this._cost_tile + this._cost_tunnel_per_tile);
			} else {
				cost += distance * (this._cost_tile + this._cost_bridge_per_tile);
				cost += this._GetBridgeNumSlopes(cur_tile, prev_tile) * this._cost_slope;
			}
		} else {
			
			/* Finally, it can be just a single tile. */
			cost += this._cost_tile;
			
			/* Check if the new tile is a high cost tile.*/
			if (AITile.IsCoastTile(cur_tile) /*||
                    AITile.IsFarmTile(cur_tile) ||
                    AITile.IsRockTile(cur_tile) ||
                    AITile.IsRoughTile(cur_tile) ||
                    AITile.IsDesertTile(cur_tile) ||
                    AITile.IsSnowTile(cur_tile)*/
			   ) {
				cost += this._cost_coast;
			}
		
			if (path.GetParent() != null && (prev_tile - path.GetParent().GetTile()) != (cur_tile - prev_tile) &&
			AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1) {
				cost += this._cost_turn;
			}
		}
		
		/* Check if the last tile was sloped. */
		if (path.GetParent() != null && !AIBridge.IsBridgeTile(prev_tile) && !AITunnel.IsTunnelTile(prev_tile) &&
				this._IsSlopedRoad(path.GetParent().GetTile(), prev_tile, cur_tile)) {
			cost += this._cost_slope;
		}
		return path.GetCost() + cost;
	}
		
	function _Estimate(cur_tile) {
		local min_cost = this._max_cost;
		foreach(tile in this._na_goals) {
			min_cost = min(min_cost, AIMap.DistanceManhattan(tile, cur_tile) * this._cost_tile);
		}
		return (min_cost * this._estimate_multiplier).tointeger();
	}	
}
