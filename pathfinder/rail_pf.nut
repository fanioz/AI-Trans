/* From AI Library : Rail.Pathfinder
/* $Id: main.nut 15101 2009-01-16 00:05:26Z truebrain $ */
/* modified for TransAI */

/**
 * A Rail Pathfinder.
 */
class Rail_PF extends AyStar
{
	_cost_diagonal_tile = null;    ///< The cost for a diagonal tile.

	constructor()
	{
		AyStar.constructor("Rail Finder");
		this._cost_diagonal_tile = 70;
		this._cost_turn = 100;
		this._cost_slope = 100;
	}

	/**
	 * Initialize a path search between sources and goals.
	 * @param sources The source tiles.
	 * @param goals The target tiles.
	 * @param ignored_tiles An array of tiles that cannot occur in the final path.
	 * @see AyStar::InitializePath()
	 */
	function InitializePath(sources, goals, ignored_tiles = []) {		
		assert(typeof(sources) == "array");
		assert(typeof(goals) == "array");

		Info("sources:", sources.len(), "dests:", goals.len());
		assert(sources.len());
		assert(goals.len());

		local nsources = [];

		foreach(node in sources) {
			//path, node[tile], node[dir], node[buildCost])
			local path = this._PathOfNode(null, [node[1], 0xFF, 0]);
			path = this._PathOfNode(path, [node[0], 0xFF, 0]);
			nsources.push(path);
		}
		
		//this._estimate_multiplier = 2;  // 1024
		//this._estimate_multiplier = 1.5;  //1244
		this._estimate_multiplier = 1.4;  //1865
		//this._estimate_multiplier = 1.3;  //4927
		//this._estimate_multiplier = 1;  //8100
		this.Initialize(nsources, goals, ignored_tiles);
		this._max_len = (20 + 1.2 * this._max_len).tointeger();
		Info("Add. max len:", this._max_len);
	}	

	function _nonzero(a, b)
	{
		return a != 0 ? a : b;
	}
	
	function _Cost(path, new_tile, new_direction)
	{
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;
	
		local prev_tile = path.GetTile();
	
		/* If the new tile is a bridge / tunnel tile, check whether we came from the other
		 *  end of the bridge / tunnel or if we just entered the bridge / tunnel. */
		if (AIBridge.IsBridgeTile(new_tile)) {
			if (AIBridge.GetOtherBridgeEnd(new_tile) != prev_tile) {
				local cost = path.GetCost() + this._cost_tile;
				if (path.GetParent() != null && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) cost += this._cost_turn;
				return cost;
			}
			return path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * this._cost_tile + this._GetBridgeNumSlopes(new_tile, prev_tile) * this._cost_slope;
		}
		if (AITunnel.IsTunnelTile(new_tile)) {
			if (AITunnel.GetOtherTunnelEnd(new_tile) != prev_tile) {
				local cost = path.GetCost() + this._cost_tile;
				if (path.GetParent() != null && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) cost += this._cost_turn;
				return cost;
			}
			return path.GetCost() + AIMap.DistanceManhattan(new_tile, prev_tile) * this._cost_tile;
		}
	
		/* If the two tiles are more then 1 tile apart, the pathfinder wants a bridge or tunnel
		 *  to be build. It isn't an existing bridge / tunnel, as that case is already handled. */
		if (AIMap.DistanceManhattan(new_tile, prev_tile) > 1) {
			/* Check if we should build a bridge or a tunnel. */
			local cost = path.GetCost();
			if (AITunnel.GetOtherTunnelEnd(new_tile) == prev_tile) {
				cost += AIMap.DistanceManhattan(new_tile, prev_tile) * (this._cost_tile + this._cost_tunnel_per_tile);
			} else {
				cost += AIMap.DistanceManhattan(new_tile, prev_tile) * (this._cost_tile + this._cost_bridge_per_tile) + this._GetBridgeNumSlopes(new_tile, prev_tile) * this._cost_slope;
			}
			if (path.GetParent() != null && path.GetParent().GetParent() != null &&
					path.GetParent().GetParent().GetTile() - path.GetParent().GetTile() != max(AIMap.GetTileX(prev_tile) - AIMap.GetTileX(new_tile), AIMap.GetTileY(prev_tile) - AIMap.GetTileY(new_tile)) / AIMap.DistanceManhattan(new_tile, prev_tile)) {
				cost += this._cost_turn;
			}
			return cost;
		}
	
		/* Check for a turn. We do this by substracting the TileID of the current
		 *  node from the TileID of the previous node and comparing that to the
		 *  difference between the tile before the previous node and the node before
		 *  that. */
		local cost = this._cost_tile;
		if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) cost = this._cost_diagonal_tile;
		if (path.GetParent() != null && path.GetParent().GetParent() != null &&
				AIMap.DistanceManhattan(new_tile, path.GetParent().GetParent().GetTile()) == 3 &&
				path.GetParent().GetParent().GetTile() - path.GetParent().GetTile() != prev_tile - new_tile) {
			cost += this._cost_turn;
		}
	
		/* Check if the new tile is a coast tile. */
		if (AITile.IsCoastTile(new_tile)) {
			cost += this._cost_coast;
		}
	
		/* Check if the last tile was sloped. */
		if (path.GetParent() != null && !AIBridge.IsBridgeTile(prev_tile) && !AITunnel.IsTunnelTile(prev_tile) &&
				this._IsSlopedRoad(path.GetParent().GetTile(), prev_tile, new_tile)) {
			cost += this._cost_slope;
		}
	
		/* We don't use already existing rail, so the following code is unused. It
		 *  assigns if no rail exists along the route. */
		/*
		if (path.GetParent() != null && !AIRail.AreTilesConnected(path.GetParent().GetTile(), prev_tile, new_tile)) {
			cost += this._cost_no_existing_rail;
		}
		*/
	
		return path.GetCost() + cost;
	}
	
	function _Estimate(cur_tile)
	{
		local min_cost = this._max_cost;
		/* As estimate we multiply the lowest possible cost for a single tile with
		 *  with the minimum number of tiles we need to traverse. */
		foreach (tile in this._na_goals) {
			local dx = abs(AIMap.GetTileX(cur_tile) - AIMap.GetTileX(tile));
			local dy = abs(AIMap.GetTileY(cur_tile) - AIMap.GetTileY(tile));
			min_cost = min(min_cost, min(dx, dy) * this._cost_diagonal_tile * 2 + (max(dx, dy) - min(dx, dy)) * this._cost_tile);
		}
		return (min_cost * this._estimate_multiplier).tointeger();
	}
	
	function _Neighbours(path, cur_node)
	{
		if (AITile.HasTransportType(cur_node, AITile.TRANSPORT_RAIL)) 
			if (!XTile.IsMyTile(cur_node)) return [];
		/* this._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
		if (path.GetCost() >= this._max_cost) return [];
		Debug.Sign(cur_node,"r")
		local tiles = [];
		local offsets = [AIMap.GetTileIndex(0, 1), AIMap.GetTileIndex(0, -1),
		                 AIMap.GetTileIndex(1, 0), AIMap.GetTileIndex(-1, 0)];
	
		/* Check if the current tile is part of a bridge or tunnel. */
		if (AIBridge.IsBridgeTile(cur_node) || AITunnel.IsTunnelTile(cur_node)) {
			/* We don't use existing rails, so neither existing bridges / tunnels. */
		} else if (path.GetParent() != null && AIMap.DistanceManhattan(cur_node, path.GetParent().GetTile()) > 1) {
			local other_end = path.GetParent().GetTile();
			local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
			foreach (offset in offsets) {
				this._accountant.ResetCosts();
				if (AIRail.BuildRail(cur_node, next_tile, next_tile + offset)) {
					tiles.push([next_tile, this._GetDirection(other_end, cur_node, next_tile, true), this._accountant.GetCosts()]);
				}
			}
		} else {
			/* Check all tiles adjacent to the current tile. */
			foreach (offset in offsets) {
				local next_tile = cur_node + offset;
				/* Don't turn back */
				if (path.GetParent() != null && next_tile == path.GetParent().GetTile()) continue;
				/* Disallow 90 degree turns */
				if (path.GetParent() != null && path.GetParent().GetParent() != null &&
					next_tile - cur_node == path.GetParent().GetParent().GetTile() - path.GetParent().GetTile()) continue;
				/* We add them to the to the neighbours-list if we can build a rail to
				 *  them and no rail exists there. */
				this._accountant.ResetCosts();
				if ((path.GetParent() == null || AIRail.BuildRail(path.GetParent().GetTile(), cur_node, next_tile))) {
					local buildCost = this._accountant.GetCosts();
					if (path.GetParent() != null) {
						local trackInTile = AIRail.GetRailTracks(cur_node);
						if (trackInTile == AIRail.RAILTRACK_INVALID) {
							tiles.push([next_tile, this._GetDirection(path.GetParent().GetTile(), cur_node, next_tile, false), buildCost]);
						} else { 
							local trackToBuild = XRail.GetRailToTrack(path.GetParent().GetTile(), cur_node, next_tile);						
						
							if (trackToBuild == AIRail.RAILTRACK_NW_SW && trackInTile == AIRail.RAILTRACK_NE_SE ||
								trackToBuild == AIRail.RAILTRACK_NE_SE && trackInTile == AIRail.RAILTRACK_NW_SW ||
								trackToBuild == AIRail.RAILTRACK_NW_NE && trackInTile == AIRail.RAILTRACK_SW_SE ||
								trackToBuild == AIRail.RAILTRACK_SW_SE && trackInTile == AIRail.RAILTRACK_NW_NE) {
								tiles.push([next_tile, this._GetDirection(path.GetParent().GetTile(), cur_node, next_tile, false), buildCost]);
							}
						}						
					} else {
						tiles.push([next_tile, this._GetDirection(null, cur_node, next_tile, false), buildCost]);
					}
				}
			}
			if (path.GetParent() != null && path.GetParent().GetParent() != null) {
				local bridges = this._GetTunnelsBridges(path.GetParent().GetTile(), cur_node, this._GetDirection(path.GetParent().GetParent().GetTile(), path.GetParent().GetTile(), cur_node, true));
				foreach (tile in bridges) {
					tiles.push(tile);
				}
			}
		}
		return tiles;
	}
	
	function _dir(from, to)
	{
		if (from - to == 1) return 0;
		if (from - to == -1) return 1;
		if (from - to == AIMap.GetMapSizeX()) return 2;
		if (from - to == -AIMap.GetMapSizeX()) return 3;
		throw("Shouldn't come here in _dir");
	}
	
	function _GetDirection(pre_from, from, to, is_bridge)
	{
		if (is_bridge) {
			if (from - to == 1) return 1;
			if (from - to == -1) return 2;
			if (from - to == AIMap.GetMapSizeX()) return 4;
			if (from - to == -AIMap.GetMapSizeX()) return 8;
		}
		return 1 << (4 + (pre_from == null ? 0 : 4 * this._dir(pre_from, from)) + this._dir(from, to));
	}
	
	/**
	 * Get a list of all bridges and tunnels that can be build from the
	 *  current tile. Bridges will only be build starting on non-flat tiles
	 *  for performance reasons. Tunnels will only be build if no terraforming
	 *  is needed on both ends.
	 */
	function _GetTunnelsBridges(last_node, cur_node, bridge_dir)
	{
		local slope = AITile.GetSlope(cur_node);
		if (slope == AITile.SLOPE_FLAT && AITile.IsBuildable(cur_node + (cur_node - last_node))) return [];
		local tiles = [];
	
		for (local i = 2; i < this._max_bridge_length; i++) {
			local bridge_list = AIBridgeList_Length(i + 1);
			local target = cur_node + i * (cur_node - last_node);
			this._accountant.ResetCosts();
			if (!bridge_list.IsEmpty() && AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), cur_node, target)) {
				tiles.push([target, bridge_dir, this._accountant.GetCosts()]);
			}
		}
	
		if (slope != AITile.SLOPE_SW && slope != AITile.SLOPE_NW && slope != AITile.SLOPE_SE && slope != AITile.SLOPE_NE) return tiles;
		local other_tunnel_end = AITunnel.GetOtherTunnelEnd(cur_node);
		if (!AIMap.IsValidTile(other_tunnel_end)) return tiles;
	
		local tunnel_length = AIMap.DistanceManhattan(cur_node, other_tunnel_end);
		local prev_tile = cur_node + (cur_node - other_tunnel_end) / tunnel_length;
		this._accountant.ResetCosts();
		if (AITunnel.GetOtherTunnelEnd(other_tunnel_end) == cur_node && tunnel_length >= 2 &&
				prev_tile == last_node && tunnel_length < _max_tunnel_length && AITunnel.BuildTunnel(AIVehicle.VT_RAIL, cur_node)) {
			tiles.push([other_tunnel_end, bridge_dir, this._accountant.GetCosts()]);
		}
		return tiles;
	}
};
