
/**
 * A Rail Pathfinder.
 * This rail pathfinder tries to find a buildable and non existing route for
 * rail vehicles. You can changes the costs below using for example
 * railpf.cost.turn = 30. Note that it's not allowed to change the cost
 * between consecutive calls to FindPath. You can change the cost before
 * the first call to FindPath and after FindPath has returned an actual
 * route.
 * This is modified version to :
 * - Use Aystar 6
 * - Has similiar feature with Road.Path.Finder 4
 * - No longer use call
 */
class RailPF
{
	_aystar_class = T_AyStar;
	_max_cost = null;              ///< The maximum cost for a route.
	_cost_tile = null;             ///< The cost for a single tile.
	_cost_diagonal_tile = null;    ///< The cost for a diagonal tile.
	/*_cost_no_existing_rail = null;         ///< The cost that is added to _cost_tile if no rail exist yet. */
	_cost_turn = null;             ///< The cost that is added to _cost_tile if the direction changes.
	_cost_slope = null;            ///< The extra cost if a rail tile is sloped.
	_cost_bridge_per_tile = null;  ///< The cost per tile of a new bridge, this is added to _cost_tile.
	_cost_tunnel_per_tile = null;  ///< The cost per tile of a new tunnel, this is added to _cost_tile.
	_cost_coast = null;            ///< The extra cost for a coast tile.
	_cost_crossing = null;         ///< The extra cost for crossing a road tile.
	_cost_demolition = null;       ///< The cost if demolition is required on a tile.
	_allow_demolition = null;      ///< Whether demolition is allowed.
	_pathfinder = null;            ///< A reference to the used AyStar object.
	_max_bridge_length = null;     ///< The maximum length of a bridge that will be build.
	_max_tunnel_length = null;     ///< The maximum length of a tunnel that will be build.
	_max_path_length = null;       ///< The maximum length in tiles of the total route.
	_estimate_multiplier = null;   ///< Every estimate is multiplied by this value. Use 1 for a 'perfect' route, higher values for faster pathfinding.
	
	_goal_estimate_tile = null;		///< The tile we take as goal tile for the estimate function.

	cost = null;                   ///< Used to change the costs.
	_running = null;
	_goals = null;                  ///< Stores array of goals
	_cost_callbacks = null;        ///< Stores [callback, args] tuples for additional cost.

	constructor()
	{
		this._max_cost = 10000000;
		this._cost_tile = 100;
		this._cost_diagonal_tile = 70;
		/* this._cost_no_existing_rail = 40; */
		this._cost_turn = 50;
		this._cost_slope = 100;
		this._cost_bridge_per_tile = 150;
		this._cost_tunnel_per_tile = 120;
		this._cost_coast = 20;
		this._cost_crossing = 500;
		this._cost_demolition = 500;
		this._allow_demolition = false;
		this._estimate_multiplier = 1;
		this._max_bridge_length = 25;
		this._max_tunnel_length = 20;
		this._pathfinder = this._aystar_class(this, this._Cost, this._Estimate, this._Neighbours, this._CheckDirection);

		this.cost = this.Cost(this);
		this._running = false;
		this._cost_callbacks = [];
	}

	/**
	 * Initialize a path search between sources and goals.
	 * @param sources The source tiles.
	 * @param goals The target tiles.
	 * @param ignored_tiles An array of tiles that cannot occur in the final path.
	 * @param max_length_multiplier The multiplier for the maximum route length.
	 * @param max_length_offset The minimum value of the maximum length.
	 * @see AyStar::InitializePath()
	 */
	function InitializePath(sources, goals, ignored_tiles = [], max_length_multiplier = 0, max_length_offset = 10000) {
		local nsources = [];

		foreach (node in sources) {
			local path = this._pathfinder.Path(null, node[1], 0xFF, this._Cost, this);
			path = this._pathfinder.Path(path, node[0], 0xFF, this._Cost, this);
			nsources.push(path);
		}
		this._goals = goals;
		/* The tile closes to the first source tile is set as estimate tile. */
		this._goal_estimate_tile = goals[0][0];
		foreach (tile in goals) {
			if (AIMap.DistanceManhattan(sources[0][0], tile[0]) < AIMap.DistanceManhattan(sources[0][0], this._goal_estimate_tile)) {
				this._goal_estimate_tile = tile[0];
			}
		}
		this._max_path_length = max_length_offset + max_length_multiplier * AIMap.DistanceManhattan(sources[0][0], this._goal_estimate_tile);
		
		this._pathfinder.InitializePath(nsources, goals, ignored_tiles);
	}
	
	/**
	 * Register a new cost callback function that will be called with all args specified.
	 * The callback function must return an integer or an error will be thrown.
	 * @param callback The callback function. This function will be called with
	 * as parameters: self, path, new_tile, new_direction, custom_arg.
	 * @param custom_arg An extra argument for your cost callback.
	 */
	function RegisterCostCallback(callback, args) {
		this._cost_callbacks.push([callback, args]);
	}

	/**
	 * Try to find the path as indicated with InitializePath with the lowest cost.
	 * @param iterations After how many iterations it should abort for a moment.
	 *  This value should either be -1 for infinite, or > 0. Any other value
	 *  aborts immediatly and will never find a path.
	 * @return A route if one was found, or false if the amount of iterations was
	 *  reached, or null if no path was found.
	 *  You can call this function over and over as long as it returns false,
	 *  which is an indication it is not yet done looking for a route.
	 * @see AyStar::FindPath()
	 */
	function FindPath(iterations);
};

class RailPF.Cost
{
	_main = null;

	function _set(idx, val)
	{
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");

		switch (idx) {
			case "max_cost":          this._main._max_cost = val; break;
			case "tile":              this._main._cost_tile = val; break;
			case "diagonal_tile":     this._main._cost_diagonal_tile = val; break;
			/* case "no_existing_rail":	this._main._cost_no_existing_rail = val; break; */
			case "turn":              this._main._cost_turn = val; break;
			case "slope":             this._main._cost_slope = val; break;
			case "bridge_per_tile":   this._main._cost_bridge_per_tile = val; break;
			case "tunnel_per_tile":   this._main._cost_tunnel_per_tile = val; break;
			case "coast":             this._main._cost_coast = val; break;
			case "crossing":          this._main._cost_crossing = val; break;
			case "demolition":        this._main._cost_demolition = val; break;
			case "allow_demolition":  this._main._allow_demolition = val; break;			
			case "max_bridge_length": this._main._max_bridge_length = val; break;
			case "max_tunnel_length": this._main._max_tunnel_length = val; break;
			case "estimate_multiplier": this._main._estimate_multiplier = val; break;
			default: throw("the index '" + idx + "' does not exist");
		}

		return val;
	}

	function _get(idx)
	{
		switch (idx) {
			case "max_cost":          return this._main._max_cost;
			case "tile":              return this._main._cost_tile;
			case "diagonal_tile":     return this._main._cost_diagonal_tile;
			/* case "no_existing_rail":    	return this._main._cost_no_existing_rail; */
			case "turn":              return this._main._cost_turn;
			case "slope":             return this._main._cost_slope;
			case "bridge_per_tile":   return this._main._cost_bridge_per_tile;
			case "tunnel_per_tile":   return this._main._cost_tunnel_per_tile;
			case "coast":             return this._main._cost_coast;
			case "crossing":          return this._main._cost_crossing;
			case "demolition":        return this._main._cost_demolition;
			case "allow_demolition":  return this._main._allow_demolition;
			case "max_bridge_length": return this._main._max_bridge_length;
			case "max_tunnel_length": return this._main._max_tunnel_length;
			case "estimate_multiplier":return this._main._estimate_multiplier;
			default: throw("the index '" + idx + "' does not exist");
		}
	}

	constructor(main)
	{
		this._main = main;
	}
};

function RailPF::FindPath(iterations)
{
	local test_mode = AITestMode();
	local ret = this._pathfinder.FindPath(iterations);
	this._running = (ret == false) ? true : false;
	if (!this._running && ret != null) {
		foreach (goal in this._goals) {
			if (goal[0] == ret.GetTile()) {
				return this._pathfinder.Path(ret, goal[1], 0, this._Cost, this);
			}
		}
	}
	return ret;
}

function RailPF::_GetBridgeNumSlopes(end_a, end_b)
{
	local slopes = 0;
	local direction = (end_b - end_a) / AIMap.DistanceManhattan(end_a, end_b);
	local slope = AITile.GetSlope(end_a);
	if (!((slope == AITile.SLOPE_NE && direction == 1) || (slope == AITile.SLOPE_SE && direction == -AIMap.GetMapSizeX()) ||
		(slope == AITile.SLOPE_SW && direction == -1) || (slope == AITile.SLOPE_NW && direction == AIMap.GetMapSizeX()) ||
		 slope == AITile.SLOPE_N || slope == AITile.SLOPE_E || slope == AITile.SLOPE_S || slope == AITile.SLOPE_W)) {
		slopes++;
	}

	local slope = AITile.GetSlope(end_b);
	direction = -direction;
	if (!((slope == AITile.SLOPE_NE && direction == 1) || (slope == AITile.SLOPE_SE && direction == -AIMap.GetMapSizeX()) ||
		(slope == AITile.SLOPE_SW && direction == -1) || (slope == AITile.SLOPE_NW && direction == AIMap.GetMapSizeX()) ||
		 slope == AITile.SLOPE_N || slope == AITile.SLOPE_E || slope == AITile.SLOPE_S || slope == AITile.SLOPE_W)) {
		slopes++;
	}
	return slopes;
}

function RailPF::_nonzero(a, b)
{
	return a != 0 ? a : b;
}

function RailPF::_Cost(self, path, new_tile, new_direction)
{
	/* path == null means this is the first node of a path, so the cost is 0. */
	if (path == null) return 0;

	local cost = self._cost_tile;
	local prev_tile = path.GetTile();

	/* Try to avoid road/rail crossing because busses/trucks will crash. */
	if (AIRail.IsLevelCrossingTile(new_tile)) {
		cost += self._cost_crossing;
	}
    
	/* If the new tile is a bridge / tunnel tile, check whether we came from the other
	 *  end of the bridge / tunnel or if we just entered the bridge / tunnel. */
	if (AIBridge.IsBridgeTile(new_tile)) {
		if (AIBridge.GetOtherBridgeEnd(new_tile) != prev_tile) {
			cost += self._cost_tile;
			if (path.GetParent() != null && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) cost += self._cost_turn;
		} else cost += AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile + self._GetBridgeNumSlopes(new_tile, prev_tile) * self._cost_slope;
	}
	if (AITunnel.IsTunnelTile(new_tile)) {
		if (AITunnel.GetOtherTunnelEnd(new_tile) != prev_tile) {
			cost += self._cost_tile;
			if (path.GetParent() != null && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) cost += self._cost_turn;
		} else cost += AIMap.DistanceManhattan(new_tile, prev_tile) * self._cost_tile;
	}

	/* If the two tiles are more then 1 tile apart, the pathfinder wants a bridge or tunnel
	 *  to be build. It isn't an existing bridge / tunnel, as that case is already handled. */
	if (AIMap.DistanceManhattan(new_tile, prev_tile) > 1) {
		/* Check if we should build a bridge or a tunnel. */
		cost -= self._cost_tile;
		if (AITunnel.GetOtherTunnelEnd(new_tile) == prev_tile) {
			cost += AIMap.DistanceManhattan(new_tile, prev_tile) * (self._cost_tile + self._cost_tunnel_per_tile);
		} else {
			cost += AIMap.DistanceManhattan(new_tile, prev_tile) * (self._cost_tile + self._cost_bridge_per_tile) + self._GetBridgeNumSlopes(new_tile, prev_tile) * self._cost_slope;
		}
		if (path.GetParent() != null && path.GetParent().GetParent() != null &&
				path.GetParent().GetParent().GetTile() - path.GetParent().GetTile() != max(AIMap.GetTileX(prev_tile) - AIMap.GetTileX(new_tile), AIMap.GetTileY(prev_tile) - AIMap.GetTileY(new_tile)) / AIMap.DistanceManhattan(new_tile, prev_tile)) {
			cost += self._cost_turn;
		}
	}

	/* Check for a turn. We do this by substracting the TileID of the current
	 *  node from the TileID of the previous node and comparing that to the
	 *  difference between the tile before the previous node and the node before
	 *  that. */
	local cost2 = self._cost_tile;
	if (path.GetParent() != null && AIMap.DistanceManhattan(path.GetParent().GetTile(), prev_tile) == 1 && path.GetParent().GetTile() - prev_tile != prev_tile - new_tile) cost2 = self._cost_diagonal_tile;
	if (path.GetParent() != null && path.GetParent().GetParent() != null &&
			AIMap.DistanceManhattan(new_tile, path.GetParent().GetParent().GetTile()) == 3 &&
			path.GetParent().GetParent().GetTile() - path.GetParent().GetTile() != prev_tile - new_tile) {
		cost2 += self._cost_turn;
	}
	cost += cost2;

	/* Check if the new tile is a coast tile. */
	if (AITile.IsCoastTile(new_tile)) {
		cost += self._cost_coast;
	}

	/* Check if the last tile was sloped. */
	if (path.GetParent() != null && !AIBridge.IsBridgeTile(prev_tile) && !AITunnel.IsTunnelTile(prev_tile) &&
			self._IsSlopedRail(path.GetParent().GetTile(), prev_tile, new_tile)) {
		cost += self._cost_slope;
	}

	/* We don't use already existing rail, so the following code is unused. It
	 *  assigns if no rail exists along the route. */
	/*
	if (path.GetParent() != null && !AIRail.AreTilesConnected(path.GetParent().GetTile(), prev_tile, new_tile)) {
		cost += self._cost_no_existing_rail;
	}
	*/
	
	/* demolish cost */
	if (!AITile.IsBuildable(new_tile) && !AIRoad.IsRoadTile(new_tile) && self._allow_demolition && 
		!AICompany.IsMine(AITile.GetOwner(new_tile)) && AITile.DemolishTile(new_tile)) {
		cost += self._cost_demolition;
	}

	/* Call all extra cost callbacks. */
	foreach (item in self._cost_callbacks) {
		local extra_cost = item[0](self, path, new_tile, new_direction, item[1]);
		if (typeof(extra_cost) != "integer") throw("Cost callback didn't return an integer.");
		cost += extra_cost;
	}

	return path.GetCost() + cost;
}

function RailPF::_Estimate(self, cur_tile, cur_direction, goal_tiles)
{
	local min_cost = self._max_cost;
	/* As estimate we multiply the lowest possible cost for a single tile with
	 * with the minimum number of tiles we need to traverse. 
	 * looping was moved to InitializePath() 
	 */
	local dx = abs(AIMap.GetTileX(cur_tile) - AIMap.GetTileX(self._goal_estimate_tile));
	local dy = abs(AIMap.GetTileY(cur_tile) - AIMap.GetTileY(self._goal_estimate_tile));
	local min_d = min(dx, dy);
	local max_d = max(dx, dy);
	local est = self._estimate_multiplier * (min_d * self._cost_diagonal_tile * 2 + (max_d - min_d) * self._cost_tile);
	return min(min_cost, est.tointeger());
}

function RailPF::_Neighbours(self, path, cur_node)
{
	if (AITile.HasTransportType(cur_node, AITile.TRANSPORT_RAIL)) return [];
	/* self._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
	if (path.GetCost() >= self._max_cost) return [];
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
			if (AIRail.BuildRail(cur_node, next_tile, next_tile + offset)) {
				tiles.push([next_tile, self._GetDirection(self, other_end, cur_node, next_tile, true)]);
			}
		}
	} else {
		/* Check all tiles adjacent to the current tile. */
		foreach (offset in offsets) {
			local next_tile = cur_node + offset;
			local can_demolish = self._allow_demolition && !AICompany.IsMine(AITile.GetOwner(next_tile)) && AITile.DemolishTile(next_tile);
			/* Make sure never to demolish road tiles. */
			can_demolish = can_demolish && !AIRoad.IsRoadTile(next_tile);
			/* Don't turn back */
			if (path.GetParent() != null && next_tile == path.GetParent().GetTile()) continue;
			/* Disallow 90 degree turns */
			if (path.GetParent() != null && path.GetParent().GetParent() != null &&
				next_tile - cur_node == path.GetParent().GetParent().GetTile() - path.GetParent().GetTile()) continue;
			/* We add them to the to the neighbours-list if we can build a rail to
			 *  them and no rail exists there. */
			if ((path.GetParent() == null || AIRail.BuildRail(path.GetParent().GetTile(), cur_node, next_tile))) {
				if (path.GetParent() != null) {
					tiles.push([next_tile, self._GetDirection(self, path.GetParent().GetTile(), cur_node, next_tile, false)]);
				} else {
					tiles.push([next_tile, self._GetDirection(self, null, cur_node, next_tile, false)]);
				}
			}
		}
		if (path.GetParent() != null && path.GetParent().GetParent() != null) {
			local bridges = self._GetTunnelsBridges(path.GetParent().GetTile(), cur_node, self._GetDirection(self, path.GetParent().GetParent().GetTile(), path.GetParent().GetTile(), cur_node, true));
			foreach (tile in bridges) {
				tiles.push(tile);
			}
		}
	}
	return tiles;
}

function RailPF::_CheckDirection(self, tile, existing_direction, new_direction)
{
	return false;
}

function RailPF::_dir(from, to)
{
	if (from - to == 1) return 0;
	if (from - to == -1) return 1;
	if (from - to == AIMap.GetMapSizeX()) return 2;
	if (from - to == -AIMap.GetMapSizeX()) return 3;
	throw("Shouldn't come here in _dir");
}

function RailPF::_GetDirection(self, pre_from, from, to, is_bridge)
{
	if (is_bridge) {
		if (from - to == 1) return 1;
		if (from - to == -1) return 2;
		if (from - to == AIMap.GetMapSizeX()) return 4;
		if (from - to == -AIMap.GetMapSizeX()) return 8;
	}
	return 1 << (4 + (pre_from == null ? 0 : 4 * self._dir(pre_from, from)) + self._dir(from, to));
}

/**
 * Get a list of all bridges and tunnels that can be build from the
 *  current tile. Bridges will only be build starting on non-flat tiles
 *  for performance reasons. Tunnels will only be build if no terraforming
 *  is needed on both ends.
 */
function RailPF::_GetTunnelsBridges(last_node, cur_node, bridge_dir)
{
	local slope = AITile.GetSlope(cur_node);
	if (slope == AITile.SLOPE_FLAT && AITile.IsBuildable(cur_node + (cur_node - last_node))) return [];
	local tiles = [];

	for (local i = 2; i < this._max_bridge_length; i++) {
		local bridge_list = AIBridgeList_Length(i + 1);
		local target = cur_node + i * (cur_node - last_node);
		if (!bridge_list.IsEmpty() && AIBridge.BuildBridge(AIVehicle.VT_RAIL, bridge_list.Begin(), cur_node, target)) {
			tiles.push([target, bridge_dir]);
		}
	}

	if (slope != AITile.SLOPE_SW && slope != AITile.SLOPE_NW && slope != AITile.SLOPE_SE && slope != AITile.SLOPE_NE) return tiles;
	local other_tunnel_end = AITunnel.GetOtherTunnelEnd(cur_node);
	if (!AIMap.IsValidTile(other_tunnel_end)) return tiles;

	local tunnel_length = AIMap.DistanceManhattan(cur_node, other_tunnel_end);
	local prev_tile = cur_node + (cur_node - other_tunnel_end) / tunnel_length;
	if (AITunnel.GetOtherTunnelEnd(other_tunnel_end) == cur_node && tunnel_length >= 2 &&
			prev_tile == last_node && tunnel_length < _max_tunnel_length && AITunnel.BuildTunnel(AIVehicle.VT_RAIL, cur_node)) {
		tiles.push([other_tunnel_end, bridge_dir]);
	}
	return tiles;
}

function RailPF::_IsSlopedRail(start, middle, end)
{
	local NW = 0; // Set to true if we want to build a rail to / from the north-west
	local NE = 0; // Set to true if we want to build a rail to / from the north-east
	local SW = 0; // Set to true if we want to build a rail to / from the south-west
	local SE = 0; // Set to true if we want to build a rail to / from the south-east

	if (middle - AIMap.GetMapSizeX() == start || middle - AIMap.GetMapSizeX() == end) NW = 1;
	if (middle - 1 == start || middle - 1 == end) NE = 1;
	if (middle + AIMap.GetMapSizeX() == start || middle + AIMap.GetMapSizeX() == end) SE = 1;
	if (middle + 1 == start || middle + 1 == end) SW = 1;

	/* If there is a turn in the current tile, it can't be sloped. */
	if ((NW || SE) && (NE || SW)) return false;

	local slope = AITile.GetSlope(middle);
	/* A rail on a steep slope is always sloped. */
	if (AITile.IsSteepSlope(slope)) return true;

	/* If only one corner is raised, the rail is sloped. */
	if (slope == AITile.SLOPE_N || slope == AITile.SLOPE_W) return true;
	if (slope == AITile.SLOPE_S || slope == AITile.SLOPE_E) return true;

	if (NW && (slope == AITile.SLOPE_NW || slope == AITile.SLOPE_SE)) return true;
	if (NE && (slope == AITile.SLOPE_NE || slope == AITile.SLOPE_SW)) return true;

	return false;
}
