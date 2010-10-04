/*  09.07.06 - route.nut
 *
 *  This file is part of Trans AI
 *
 *  Copyright 2009 fanio zilla <fanio.zilla@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 *  MA 02110-1301, USA.
 */

/**
 * A Route class
 * contain An AyStar implementation.
 * It solves graphs by finding the fastest route from one point to the other.
 */
class Route extends AyStar_6
{
	/**
	 * @param pf_instance An instance that'll be passed to all the callback
	 *  functions.
	 * @param cost_callback A function that returns the cost of a path. It
	 *  should accept four parameters: pf_instance, old_path, new_tile,
	 *  new_direction. old_path is an instance of AyStar.Path, and new_tile
	 *  and new_direction is the new node that is added to that path.
	 *  It should return the cost of the path including new_node.
	 * @param estimate_callback A function that returns an estimate from a node
	 *  to the goal node. It should accept four parameters: pf_instance, tile,
	 *  direction, goal_nodes. It should return an estimate to the cost from
	 *  the lowest cost between node and any node out of goal_nodes. Note that
	 *  this estimate is not allowed to be higher than the real cost between
	 *  node and any of goal_nodes. A lower value is fine, however the closer it
	 *  is to the real value, the better the performance.
	 * @param neighbours_callback A function that returns all neighbouring nodes
	 *  from a given node. It should accept three parameters: pf_instance,
	 *  current_path, node. It should return an array containing all
	 *  neighbouring nodes, which are an array in the form [tile, direction,
	 *  tile_params].
	 * @param check_direction_callback A function that returns either false or
	 *  true. It should accept four parameters: pf_instance, current_tile,
	 *  existing_direction, new_direction, tile_params. It should check if
	 *  both directions can go together on a single tile.
	 */
	constructor(pf_instance, cost_callback, estimate_callback, neighbours_callback, check_direction_callback)
	{
		::AyStar_6.constructor(pf_instance, cost_callback, estimate_callback, neighbours_callback, check_direction_callback);
		this._queue_class = FibonacciHeap;
	}

	/**
 	 * Trial version of add last detected path
 	 * @param path Path found before or Array converted from path
 	 */
 	 function AddPath(path)
 	 {
 	 	if (path instanceof ::Route.Path) {
 	 		local nodes = Assist.Path2Array(path);
 	 		foreach (node in nodes) this._closed.AddItem(node[0], node[1]);
 	 	} else if (typeof path == "array") {
 	 		foreach (node in path) this._closed.AddItem(node[0], node[1]);
 	 	} else throw "path should be instance of Rotue.Path or converted to array";
 	 }	
}

/**
 * Route cost handler
 */
class Route.Cost {
	_main = null;
	/** A Route cost constructor */
	constructor(main)
	{
		this._main = main;
	}
	
	function _set(idx, val)
	{
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");
		if (idx in this._main) this._main.idx = val; return;
		AILog.Error("the index '" + idx + "' does not exist");
		local nidx = "_" + idx;
		if (nidx in this._main) this._main.nidx = val; return;
		throw "the index '" + nidx + "' does not exist";
	}
	
	function _get(idx)
	{
		if (this._main._running) throw("You are not allowed to change parameters of a running pathfinder.");
		if (idx in this._main) return this._main.idx;
		AILog.Error("the index '" + idx + "' does not exist");
		local nidx = "_" + idx;
		if (nidx in this._main) return this._main.nidx;
		throw "the index '" + nidx + "' does not exist";
	}	
}

/**
 * Base of all path finder class.
 * Be carefull, its used by both Road and Rail PF 
 */
class Route.Finder
{
	/** A Route finder constructor */
	constructor(main)
	{
		main._max_cost = 10000000;
		main._cost_tile = 100;
		main._cost_turn = 100;
		main._cost_slope = 100;
		main._cost_bridge_per_tile = 150;
		main._cost_tunnel_per_tile = 120;
		main._cost_coast = 100;
		main._cost_crossing = 500;
		main._cost_demolition = 0;
		main._max_bridge_length = 102;
		main._max_tunnel_length = 20;
		main._estimate_multiplier = 1;
		main._use_existing = 0;
		main._pathfinder = ::Route(main, main._Cost, main._Estimate, main._Neighbours, main._CheckDirection);

		main.cost = ::Route.Cost(main);
		main._running = false;
	}
	
	/**
	 * Calculate cost of using this tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @param new_direction current direction
	 * @return cost of new tile
	 */
	function GetCost(self, path, new_tile, new_direction)
	{
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;
		local prev_tile = path.GetTile();
		local cost = 0;
		
		/* If the new tile is a bridge tile, check whether we came from the other
		 * end of the bridge. */
		if (AIBridge.IsBridgeTile(new_tile)) {
			if (AIBridge.GetOtherBridgeEnd(new_tile) == prev_tile) {
				local b_id = AIBridge.GetBridgeID(new_tile);
				local cur_length = AIMap.DistanceManhattan(new_tile, prev_tile);
		        local b_list = AIBridgeList_Length(cur_length);
		        if (b_list.Count()) {
		        	b_list.Valuate(AIBridge.GetMaxSpeed);
		        	b_list.Sort(AIAbstractList.SORT_BY_VALUE, true);
		        	if (b_list.Begin() == b_id) return self._max_cost;
		        }
			}
		}
		
		/* Try to avoid road/rail crossing because busses/trucks will crash. */
		if (self._cost_crossing && AIRail.IsLevelCrossingTile(new_tile)) {
			cost += self._cost_crossing;
		}
	
    	/* dont call path.getcost */
		return cost;
	}
}

/**
 * A Rail Pathfinder.
 *  This rail pathfinder tries to find a buildable / existing route for
 *  rail vehicles. You can changes the costs below using for example
 *  railpf.cost.turn = 30. Note that it's not allowed to change the cost
 *  between consecutive calls to FindPath. You can change the cost before
 *  the first call to FindPath and after FindPath has returned an actual
 *  route.
 */
class Route.RailFinder extends RailPF_1
{
	/** Whether demolition is allowed. Set a cost to activate it. */
	_cost_demolition = null;
	/** The extra cost for crossing a road tile. Set a cost to activate it. */
	_cost_crossing = null;
	/** Wheter to build new or try use existing. Set 0 - 100 % of existing percent*/
	_use_existing = null;
	/** Every estimate is multiplied by this value.
	 * Use 1 for a 'perfect' route, higher values for faster pathfinding. */
	_estimate_multiplier = null;
	
	/** A Rail route finder constructor */
	constructor()
	{
		::Route.Finder.constructor(this);
		this._cost_diagonal_tile = 60;
		if (TransAI.Setting.Get(Const.Settings.realistic_acceleration)) this._cost_slope = 0;
	}
	
	/**
	 * Calculate estimate (heuristic) of using this tile as path
	 * @param self PF call back
	 * @param cur_tile current tile
	 * @param cur_direction current direction
	 * @param goal_tiles Array of goal tiles
	 * @return estimate of current tile
	 */
	function _Estimate(self, cur_tile, cur_direction, goal_tiles)
	{
		return self._estimate_multiplier * ::RailPF_1._Estimate(cur_tile, cur_direction, goal_tiles, self);
	}
	
	/**
	 * Calculate cost of using this tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @param new_direction current direction
	 * @return cost of new tile
	 */
	function _Cost(self, path, new_tile, new_direction) 
	{	
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;
		local prev_tile = path.GetTile();
		
		local cost = ::RailPF_1._Cost(path, new_tile, new_direction, self);
		cost += ::Route.Finder.GetCost(self, path, new_tile, new_direction);
		if (self._use_existing) {
			if (path.GetParent() != null) {
				if (AIRail.AreTilesConnected(path.GetParent().GetTile(), prev_tile, new_tile)) {
					cost -= (self._cost_diagonal_tile + self._cost_tile);
				} else {
					cost += (self._cost_diagonal_tile + self._cost_tile);
				}
			}
		}
		/* dont call path.getcost */
		return cost;
	}
	
	/**
	 * Find Neighbours next to current node
	 * @param self PF instance
	 * @param path Current path
	 * @param cur_node Current Node
	 * @return Array of Path tiles
	 */
	function _Neighbours(self, path, cur_node) {
		return ::RailPF_1._Neighbours(path, cur_node, self);
	}
	
	function _CheckDirection(self, tile, existing_direction, new_direction)
	{
		return false;
	}	
}
	
/**
 * A Road Pathfinder.
 *  This road pathfinder tries to find a buildable / existing route for
 *  road vehicles. You can changes the costs below using for example
 *  roadpf.cost.turn = 30. Note that it's not allowed to change the cost
 *  between consecutive calls to FindPath. You can change the cost before
 *  the first call to FindPath and after FindPath has returned an actual
 *  route. To use only existing roads, set cost.no_existing_road to
 *  cost.max_cost.
 */
class Route.RoadFinder extends RoadPF_3
{
	/** Whether demolition is allowed. Set a cost to activate it. */
	_cost_demolition = null;
	/** The extra cost for crossing a road tile. Set a cost to activate it. */
	_cost_crossing = null;
	/** Wheter to build new or try use existing. Set 0 - 100 % of existing percent*/
	_use_existing = null;
	/** Every estimate is multiplied by this value.
	 * Use 1 for a 'perfect' route, higher values for faster pathfinding. */
	_estimate_multiplier = null;
	
	/** A Road route finder constructor */
	constructor()
	{
		::Route.Finder.constructor(this);
		this._cost_no_existing_road = this._cost_tile;
	}
	
	/**
	 * Initialize a path search between sources and goals.
	 * @param sources The source tiles.
	 * @param goals The target tiles.
	 * @param ignored_tiles An array of tiles that cannot occur in the final path.
	 * @see AyStar::InitializePath()
	 */
	function InitializePath(sources, goals, ignored_tiles)
	{
		local nsources = [];

		foreach (node in sources) {
			nsources.push([node, 0xFF]);
		}
		
		this._pathfinder.InitializePath(nsources, goals, ignored_tiles);
	}
	
	/**
	 * Calculate cost of using this tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @param new_direction current direction
	 * @return cost of new tile
	 */
	function _Cost(self, path, new_tile, new_direction)
	{
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;
		local prev_tile = path.GetTile();
		local cost = ::RoadPF_3._Cost(path, new_tile, new_direction, self);
		cost += ::Route.Finder.GetCost(self, path, new_tile, new_direction);
		
		/* Check if there already is a connection to the tile. */
		if (AIRoad.AreRoadTilesConnected(prev_tile, new_tile)) {
			cost += -self._cost_tile;
		}				
		return cost;
	}
	
	function _Neighbours(self, path, cur_node)
	{
		/* self._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
		if (path.GetCost() >= self._max_cost) return [];
		local tiles = ::RoadPF_3._Neighbours(path, cur_node, self);
		
		return tiles;
	}
	
	/**
	 * Calculate estimate (heuristic) of using this tile as path
	 * @param self PF call back
	 * @param cur_tile current tile
	 * @param cur_direction current direction
	 * @param goal_tiles Array of goal tiles
	 * @return estimate of current tile
	 */
	function _Estimate(self, cur_tile, cur_direction, goal_tiles)
	{
		return self._estimate_multiplier * ::RoadPF_3._Estimate(cur_tile, cur_direction, goal_tiles, self);
	}
}

/**
 * A Route tracker.
 * This route tracker tries to find an existing route for
 * vehicles.
 */
class Route.Tracker
{
	/**
	 * Calculate cost of using this tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @param new_direction current direction
	 * @param trans_type current transport type
	 * @return cost of new tile
	 */
	function GetCost(self, path, new_tile, new_direction, trans_type)
	{
		/* path == null means this is the first node of a path, so the cost is 0. */
		if (path == null) return 0;
		if (!AITile.HasTransportType(new_tile, trans_type)) return self._max_cost;
		return path.GetCost() + AIMap.DistanceManhattan(path.GetTile(), new_tile);
	}

	/**
	 * Calculate estimate (heuristic) of using this tile as path
	 * @param self PF call back
	 * @param cur_tile current tile
	 * @param cur_direction current direction
	 * @param goal_tiles Array of goal tiles
	 * @return estimate of current tile
	 */
	function GetEstimate(self, cur_tile, cur_direction, goal_tiles)
	{
		local min_cost = self._max_cost;
		foreach (tile in goal_tiles) {
			if (typeof tile == "array") {
				min_cost = min(min_cost, AIMap.DistanceManhattan(tile[0], cur_tile));
			} else {
				min_cost = min(min_cost, AIMap.DistanceManhattan(tile, cur_tile));
			}
		}
		return min_cost;
	}	
}

/**
 * A Route tracker.
 * This route tracker tries to find an existing route for road
 * vehicles.
 */
class Route.RoadTracker extends Route.RoadFinder
{
	function _Neighbours(self, path, cur_node) {
		/* self._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
		if (path.GetCost() >= self._max_cost) return [];
		if (!AITile.HasTransportType(cur_node, AITile.TRANSPORT_ROAD)) return [];
		
		local tiles = ::Route.RoadFinder._Neighbours(self, path, cur_node);
		return tiles;
	}
	
	/**
	 * Calculate cost of using this tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @param new_direction current direction
	 * @return cost of new tile
	 */
	function _Cost(self, path, new_tile, new_direction)
	{
		if (path != null && !AIRoad.AreRoadTilesConnected(path.GetTile(), new_tile)) { 
		return ::Route.Tracker.GetCost(self, path, new_tile, new_direction, AITile.TRANSPORT_ROAD);
		}
		return self._max_cost;
	}
}

/**
 * A Route tracker.
 * This route tracker tries to find an existing route for rail
 * vehicles.
 */
class Route.RailTracker extends Route.RailFinder
{
	function _Neighbours(self, path, cur_node) {
		if (!AITile.HasTransportType(cur_node, AITile.TRANSPORT_RAIL)) return [];
		
		/* self._max_cost is the maximum path cost, if we go over it, the path isn't valid. */
		if (path.GetCost() >= self._max_cost) return [];
		/* Because we can Only use track we own. */
		if (!Tile.IsMine(cur_node)) return [];
		/* Because train need to get powered */
		if (!AIRail.TrainHasPowerOnRail(AIRail.GetRailType(cur_node), AIRail.GetCurrentRailType())) return [];
		/* Dont pass thru station */
		if (AITile.IsStationTile(cur_node)) return [];
		
		local prev_tile = path.GetParent() ? path.GetParent().GetTile() : path.GetTile();
		/* can only pass a twoway or PBS signal */
		if (AIRail.GetSignalType(prev_tile, path.GetTile()) != AIRail.SIGNALTYPE_NONE) {
			if (AIRail.GetSignalType(prev_tile, path.GetTile()) != AIRail.SIGNALTYPE_NORMAL_TWOWAY) return [];
			if (AIRail.GetSignalType(prev_tile, path.GetTile()) != AIRail.SIGNALTYPE_PBS) return [];
		}
		
		local tiles = [];

		/* Check if the current tile is part of a bridge or tunnel. */
		if (AIBridge.IsBridgeTile(cur_node) || AITunnel.IsTunnelTile(cur_node)) {
			if ((AIBridge.IsBridgeTile(cur_node) && AIBridge.GetOtherBridgeEnd(cur_node) == path.GetParent().GetTile()) ||
			  (AITunnel.IsTunnelTile(cur_node) && AITunnel.GetOtherTunnelEnd(cur_node) == path.GetParent().GetTile())) {
				local other_end = path.GetParent().GetTile();
				local next_tile = cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end);
				tiles.push([next_tile, self._GetDirection(null, cur_node, next_tile, true)]);
			} else if (AIBridge.IsBridgeTile(cur_node)) {
				local other_end = AIBridge.GetOtherBridgeEnd(cur_node);;
				if ((cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end)) == 
					path.GetParent().GetTile()) {
						tiles.push([AIBridge.GetOtherBridgeEnd(cur_node), self._GetDirection(null, path.GetParent().GetTile(), cur_node, true)]);
					}
			} else {
				local other_end = AITunnel.GetOtherTunnelEnd(cur_node);
				if ((cur_node + (cur_node - other_end) / AIMap.DistanceManhattan(cur_node, other_end)) == path.GetParent().GetTile()) tiles.push([AITunnel.GetOtherTunnelEnd(cur_node), self._GetDirection(null, path.GetParent().GetTile(), cur_node, true)]);
			}
		} else {
			foreach (next_tile in Tiles.Adjacent(cur_node)) {
				/* Don't turn back */
				if (next_tile == prev_tile) continue;
				/* Disallow 90 degree turns */
				if (path.GetParent().GetParent() != null &&
					next_tile - cur_node == path.GetParent().GetParent().GetTile() - prev_tile) continue;
				if (AIRail.AreTilesConnected(prev_tile, cur_node, next_tile)) {
					tiles.push([next_tile, self._GetDirection(prev_tile, cur_node, next_tile, false)]);
				}
			}
		}
		return tiles;
	}
	
	/**
	 * Calculate cost of using this tile as path
	 * @param self PF call back
	 * @param path current path
	 * @param new_tile current tile
	 * @param new_direction current direction
	 * @return cost of new tile
	 */
	function _Cost(self, path, new_tile, new_direction)
	{
		return ::Route.Tracker.GetCost(self, path, new_tile, new_direction, AITile.TRANSPORT_RAIL);
	}
}
